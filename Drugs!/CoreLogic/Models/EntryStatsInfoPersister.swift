//
//  EntryStatsInfoPersister.swift
//  Drugs!
//
//  Created by Ivan Lugo on 3/27/22.
//  Copyright © 2022 Ivan Lugo. All rights reserved.
//

import Foundation
import RealmSwift
import Combine

class EntryStatsInfoPersister {
    private var bag = Set<AnyCancellable>()
    var realmTokens = [NotificationToken]()
    
    private let worker = BackgroundWorker()
    let manager: DefaultRealmManager
    
    init(manager: DefaultRealmManager) {
        self.manager = manager
    }
    
    deinit {
        log("Info persister state cleaning up")
        worker.stop()
    }
    
    func start() {
        log("starting worker thread on persister init")
        worker.start()
        worker.run { [weak self] runLoop in
            log("worker online: \(Thread.current)")
            self?.initializeOnWorkerThread()
        }
    }
    
    private func initializeOnWorkerThread() {
        // retained by calculator instance
        manager.access { realm in
            bag.insert(
                Publishers.CombineLatest(
                    realm.objects(RLM_MedicineEntry.self).collectionPublisher,
                    RLM_AvailableDrugList.defeaultObservableListFrom(realm).collectionPublisher
                )
                .sink(
                    receiveCompletion: { state in
                        switch state {
                        case .finished: log("CombineLatest reported finished state")
                        case let .failure(error): log(error)
                        }
                    },
                    receiveValue: { [weak self] value in
                        self?.writeUpdatedState(value.0, value.1)
                    }
                )
            )
        }
    }
    
    private func writeUpdatedState(
        _ entries: Results<RLM_MedicineEntry>?,
        _ drugList: Results<RLM_AvailableDrugList>?
    ) {
        guard let entries = entries,
              let drugList = drugList?.first?.drugs else {
            log("Skip state write")
            return
        }
        
        do {
            try updateInfoContainer {
                $0.allInfo = buildNewStatesMap(entries: entries, drugList: drugList)
            }
            log("Selection info updated")
        } catch {
            log(error)
        }
    }
    
    private func buildNewStatesMap(
        startDate: Date = Date(),
        entries: Results<RLM_MedicineEntry>,
        drugList: RealmSwift.List<RLM_Drug>
    ) -> Map<Drug.ID, RLM_AvailabilityStats> {
        
        let drugStates = Map<Drug.ID, RLM_AvailabilityStats>()
        drugList.forEach {
            drugStates[$0.id] = RLM_AvailabilityStats(canTake: true, when: startDate)
        }
        
        func listMatchOrDefault(_ drug: RLM_Drug) -> RLM_Drug {
            drugList.first(where: { $0.id == drug.id }) ?? drug
        }
        
        // Use the newest drug info if there is one.
        // This is important so old entries don't step on new drugs.
        entries.forEach { entry in
            entry.drugsTaken.forEach { drugSelection in
                guard let drug = drugSelection.drug else {
                    log(AvailabilityInfoError.missingDrug("No drug from selection: \(entry.id), \(drugSelection.count)"))
                    return
                }
                
                let entryOrListDrug = listMatchOrDefault(drug)
                let nextDoseTime = entry.date.advanced(by: entryOrListDrug.doseTimeInSeconds)
                
                switch drugStates[entryOrListDrug.id] {
                case .some(let stats):
                    stats.when = max(nextDoseTime, stats.when)
                    stats.canTake = nextDoseTime <= startDate
                case .none:
                    let stats = RLM_AvailabilityStats()
                    stats.when = nextDoseTime
                    stats.canTake = nextDoseTime <= startDate
                    drugStates[entryOrListDrug.id] = stats
                }
            }
        }
        
        return drugStates
    }
    
    private func loadListTuple() -> (Results<RLM_MedicineEntry>?, Results<RLM_AvailableDrugList>?) {
        manager.accessImmediate { realm in (
            realm.objects(RLM_MedicineEntry.self),
            RLM_AvailableDrugList.defeaultObservableListFrom(realm)
        )} ?? (nil, nil)
    }
    
    private func updateInfoContainer(_ receiver: (RLM_AvailabilityInfoContainer) -> Void) throws {
        manager.access { realm in
            try realm.write {
                let infoContainer = RLM_AvailabilityInfoContainer.defaultFrom(realm) ?? {
                    log(AvailabilityInfoError.missingContainer, "No info container found, creating new")
                    let container = RLM_AvailabilityInfoContainer()
                    realm.add(container, update: .all)
                    return container
                }()
                receiver(infoContainer)
                realm.add(infoContainer, update: .all)
            }
        }
    }
}
