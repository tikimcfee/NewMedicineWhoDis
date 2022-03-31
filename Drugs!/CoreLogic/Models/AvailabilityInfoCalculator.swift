//
//  AvailabilityInfoCalculator.swift
//  Drugs!
//
//  Created by Ivan Lugo on 3/25/22.
//  Copyright © 2022 Ivan Lugo. All rights reserved.
//

import Foundation
import RealmSwift
import Combine
import SwiftUI

public typealias AvailabilityInfo = [Drug: (canTake: Bool, when: Date)]

enum AvailabilityInfoError: Error {
    case initialStateFailed
    case missingContainer
    case missingDrugList
    case missingBindTargetRealm
    case missingDrug(String)
}

extension AvailabilityInfo {
    func canTake(_ drug: Drug) -> Bool {
        return self[drug]?.canTake == true
    }
}

// Receiver protocol must allow weak reference so state is not implicitly retained,
// captured by the immediate usage in the sink call
typealias ContainerReceiver = (inout DrugSelectionContainerModel) -> Void
typealias ContainerReceiverGetter = (ContainerReceiver) -> Void

class AvailabilityInfoCalculator: ObservableObject {
    private lazy var id = UUID()
    private lazy var workQueue = DispatchQueue(label: "CalculatorQueue-\(id)", qos: .userInteractive)
    
    private let manager: DefaultRealmManager
    
    var realmTokens = [NotificationToken]()
    private var bag = Set<AnyCancellable>()
    
    init(manager: DefaultRealmManager) {
        self.manager = manager
    }
    
    deinit {
        log("Calculator deinit")
    }
    
    func start(receiver: @escaping ContainerReceiverGetter) {
        manager.access { realm in
            try ensureInitialRealmState(
                RLM_MedicineEntry.observableResults(realm),
                RLM_AvailabilityInfoContainer.observableResults(realm),
                RLM_AvailableDrugList.observableResults(realm),
                in: realm
            )
            
            let drugListPublisher = buildDrugListPublisher(realm)
            let entryListPublisher = buildEntryListPublisher(realm)
            
            bag.insert(
                Publishers.CombineLatest(
                    entryListPublisher,
                    drugListPublisher
                )
//                .receive(on: workQueue)
//                .removeDuplicates(by: { last, next in
//                    return last.0 == next.0
//                        && last.1 == next.1
//                })
//                .receive(on: RunLoop.main)
                .compactMap { [weak self] (entries, drugList) -> (AvailabilityInfo, AvailableDrugList)? in
                    // TODO: better way to grab the value and persist and return info
                    // maybe just get finally get rid of old info
                    let newMap = Self.buildNewStatesMap(entries: entries, drugList: drugList)
                    guard let container = self?.persistContainerChange(newMap) else {
                        log("Failed to persist container; cannot migrate to v1 drug list")
                        return nil
                    }
                    
                    let migrator = V1Migrator()
                    let newInfo = migrator.migrateFromRLMAvailability(
                        container: container,
                        sourceList: drugList
                    )
                    return (newInfo, migrator.toV1DrugList(drugList))
                }
                .sink(
                    receiveCompletion: { state in
                        switch state {
                        case .finished: log("CombineLatest reported finished state")
                        case let .failure(error): log(error)
                        }
                    },
                    receiveValue: { newInfo in
                        receiver { toEdit in
                            log("Alert receiver of new info")
                            toEdit.info = newInfo.0
                            toEdit.availableDrugs = newInfo.1
                        }
                    }
                )
            )
        }
    }
    
    private func persistContainerChange(
        _ newMap: Map<Drug.ID, RLM_AvailabilityStats>
    ) -> RLM_AvailabilityInfoContainer? {
        manager.accessImmediate { realm -> RLM_AvailabilityInfoContainer in
            guard let container = RLM_AvailabilityInfoContainer.defaultFrom(realm) else {
                throw AvailabilityInfoError.missingDrugList
            }
            
            safeWrite(container) { safeContainer in
                safeContainer.allInfo = newMap
            }
            
            return container
        }
    }
    
    private func buildDrugListPublisher(_ realm: Realm) -> AnyPublisher<RLM_AvailableDrugList, Never> {
        RLM_AvailableDrugList
            .observableResults(realm)
            .changesetPublisher
            .compactMap { change in
                switch change {
                case let .initial(list):
                    log("Load initial drug list")
                    return list.first
                case let .update(list, deletions, insertions, modifications):
                    log("Drug list update: \(deletions) \(insertions) \(modifications)")
                    return list.first
                case let .error(error):
                    log(error, "Failed to observe drug list")
                    return nil
                }
            }
            .map { (list: RLM_AvailableDrugList) in list }
            .eraseToAnyPublisher()
    }
    
    private func buildEntryListPublisher(_ realm: Realm) -> AnyPublisher<Results<RLM_MedicineEntry>, Never> {
        RLM_MedicineEntry
            .observableResults(realm)
            .changesetPublisher
            .compactMap { change in
                switch change {
                case let .initial(list):
                    log("Load initial entry list")
                    return list
                case let .update(list, deletions, insertions, modifications):
                    log("Entry list update: \(deletions) \(insertions) \(modifications)")
                    return list
                case let .error(error):
                    log(error, "Failed to observe entry list")
                    return nil
                }
            }
            .map { (list: Results<RLM_MedicineEntry>) in list }
            .eraseToAnyPublisher()
    }

    private func ensureInitialRealmState(
        _ entries: Results<RLM_MedicineEntry>,
        _ container: Results<RLM_AvailabilityInfoContainer>?,
        _ drugs: Results<RLM_AvailableDrugList>?,
        in realm: Realm
    ) throws {
        log("Checking and setting initial state")
        
        if let _ = container?.first,
           let drugList = drugs?.first,
           drugList.drugs.isEmpty || drugList.didSetDefaultList
        {
            log("Active state is already valid")
            return
        }
        
        // Create managed(?) instances to update initial state
        let container = container?.first ?? {
            log("Container missing from query, creating initial info container model")
            return RLM_AvailabilityInfoContainer()
        }()
        
        let drugList = drugs?.first ?? {
            log("Drug list mising from query, creating intial drug list")
            return RLM_AvailableDrugList()
        }()
        
        try realm.write {
            [
                ("Adding container", {
                    realm.add(container, update: .modified)
                }),
                ("Adding list", {
                    if !drugList.didSetDefaultList && drugList.drugs.isEmpty {
                        // assign directly to allow reduce to capture type from property
                        log("Adding initial drugs to list")
                        let migrator = V1Migrator()
                        drugList.drugs = AvailableDrugList.defaultList.drugs
                            .reduce(into: List()) { result, drug in
                                result.append(migrator.fromV1drug(drug))
                            }
                        log("Added drugs: \(drugList.drugs.count)")
                    }
                    drugList.didSetDefaultList = true
                    realm.add(drugList, update: .modified)
                })
            ].forEach { step, action in
                log(step)
                action()
            }
        }
    }
}

extension AvailabilityInfoCalculator {
    static func buildNewStatesMap(
        startDate: Date = Date(),
        entries: Results<RLM_MedicineEntry>,
        drugList: RLM_AvailableDrugList
    ) -> Map<Drug.ID, RLM_AvailabilityStats> {
        
        let drugStates = Map<Drug.ID, RLM_AvailabilityStats>()
        drugList.drugs.forEach {
            drugStates[$0.id] = RLM_AvailabilityStats(canTake: true, when: startDate)
        }
        
        func listMatchOrDefault(_ drug: RLM_Drug) -> RLM_Drug {
            drugList.drugs.first(where: { $0.id == drug.id }) ?? drug
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
}
