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
import Network

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
    private let migrator = V1Migrator()
    
    typealias Publised = (AvailabilityInfo, AvailableDrugList)
    typealias InfoPublisher = AnyPublisher<Publised, Never>
    typealias CurrentInfoPublisher = AnyPublisher<Publised, Never>
    
    private lazy var currentInfoSubject: CurrentValueSubject = {
        CurrentValueSubject<(AvailabilityInfo, AvailableDrugList), Never>(
            (AvailabilityInfo(), AvailableDrugList([]))
        )
    }()
    
    lazy var currentInfoPublisher: CurrentInfoPublisher = {
        currentInfoSubject.eraseToAnyPublisher()
    }()
        
    init(manager: DefaultRealmManager) {
        self.manager = manager
        onInit()
    }
    
    deinit {
        log("Calculator deinit")
    }
    
    func onInit() {
        manager.access { realm in
            try ensureInitialRealmState(
                RLM_MedicineEntry.observableResults(realm),
                RLM_AvailabilityInfoContainer.observableResults(realm),
                RLM_AvailableDrugList.observableResults(realm),
                in: realm
            )
            
            let infoPublisher = try makeRootInfoPublisher(from: realm)
            bag.insert(
                infoPublisher.sink(receiveValue: { [weak self] result in
                    self?.currentInfoSubject.send(result)
                })
            )
        }
    }
}

// MARK: -- Publishers
private extension AvailabilityInfoCalculator {
    func makeRootInfoPublisher(from realm: Realm) throws -> InfoPublisher {
        let oneMonthPrior = Date().addingTimeInterval(-1 * (60 * 60 * 24 * 7 * 4))
        return Publishers.CombineLatest(
            buildEntryListPublisher(realm, cutoffDate: oneMonthPrior),
            buildDrugListPublisher(realm)
        )
        .compactMap { [weak self] in self?.mergeObservedResults($0, $1) }
        .eraseToAnyPublisher()
    }
    
    func mergeObservedResults(
        _ entries: Results<RLM_MedicineEntry>,
        _ drugList: RLM_AvailableDrugList
    ) -> Publised? {
        manager.accessImmediate { realm in
            var newInfo: Publised? = nil
            try realm.write {
                newInfo = try Self.writeUpdatedContainersAndGroups(
                    entries: entries,
                    drugList: drugList,
                    realm: realm
                )
            }
            return newInfo
        }
    }

    func buildDrugListPublisher(_ realm: Realm) -> AnyPublisher<RLM_AvailableDrugList, Never> {
        RLM_AvailableDrugList
            .defaultFrom(realm)?
            .publisher(for: \.self)
            .eraseToAnyPublisher()
        ?? {
            log(AvailabilityInfoError.missingDrugList, "Can't find list to build publisher")
            return Empty().eraseToAnyPublisher()
        }()
    }
    
    func buildEntryListPublisher(_ realm: Realm, cutoffDate: Date) -> AnyPublisher<Results<RLM_MedicineEntry>, Never> {
        return RLM_MedicineEntry
            .observableResults(realm)
            .sorted(by: \.date, ascending: false)
            .where { $0.date > cutoffDate }
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
            .eraseToAnyPublisher()
    }
    
    func ensureInitialRealmState(
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
        
        try realm.write {[
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
        }}
    }
}


extension AvailabilityInfoCalculator {
    static func writeUpdatedContainersAndGroups(
        entries: Results<Entry>,
        drugList: RLM_AvailableDrugList,
        canTakeAtDate: Date = Date(),
        realm: Realm
    ) throws -> Publised {
        guard let timingContainer = RLM_AvailabilityInfoContainer.defaultFrom(realm) else {
            throw AvailabilityInfoError.missingContainer
        }
        
        // Clear all current timings
        log("Clearing timing container")
        let newTimingInfo = timingContainer.timingInfo ?? {
            log("Timing container missing info; recreating empty")
            return Map<DrugId, RLM_AvailabilityStats>()
        }()
        timingContainer.timingInfo?.removeAll()
        
        
        // Add all default timings
        log("Adding default drugs")
        drugList.drugs.forEach { drug in
            newTimingInfo[drug.id] = RLM_AvailabilityStats(drug: drug, when: canTakeAtDate)
        }
        
        // Clear all groups; we'll recreate and add next
        log("Clearing all entry groups")
        realm.delete(RLM_MedicineEntryGroup.observableResults(realm))
        
        // groups up entries by 'simpleDateKey', currently "2022-04-02" (yyyy-MM-dd).
        var newEntryGroups = [String: EntryGroup]()
        func upsertIntoNewGroups(_ entry: Entry) {
            let group = newEntryGroups[entry.simpleDateKey] ?? {
                let newGroup = EntryGroup()
                newGroup.representableDate = entry.date
                return newGroup
            }()
            group.entries.append(entry)
            newEntryGroups[entry.simpleDateKey] = group
        }

        // Use all drugs taken to compute a mapping of the next date that drug id
        // may be taken based on dosage time
        func updateFromDrugSelection(_ entry: Entry, _ drugSelection: RLM_DrugSelection) {
            guard let recordedDrug = drugSelection.drug else {
                log("Missing: \(drugSelection.drug?.id ?? "<no drug>")")
                return
            }
            
            let lookupDrug = newTimingInfo[recordedDrug.id]?.drug ?? {
                log("Missing drug from list; using recording drug: \(recordedDrug)")
                return recordedDrug
            }()
            let entryOffsetNextDoseTime = entry.date.advanced(by: lookupDrug.doseTimeInSeconds)
            
            switch newTimingInfo[lookupDrug.id] {
            case .some(let stats):
                stats.when = max(entryOffsetNextDoseTime, stats.when)
                newTimingInfo[lookupDrug.id] = stats
                
            case .none:
                let stats = RLM_AvailabilityStats(
                    drug: lookupDrug,
                    when: canTakeAtDate
                )
                newTimingInfo[lookupDrug.id] = stats
            }
        }
        
        // Use the newest drug info if there is one.
        // This is important so old entries don't step on new drugs.
        entries
            .forEach { entry in
                upsertIntoNewGroups(entry)
                entry.drugsTaken.forEach { drugSelection in
                    updateFromDrugSelection(entry, drugSelection)
                }
            }
        
        
        // Write all data
        log("Running deferred add of updated timing container")
        timingContainer.timingInfo = newTimingInfo
        
        log("Running deferred group add on entries: \(newEntryGroups.keys)")
        realm.add(newEntryGroups.values)
        
        // Migrate to old format for compat
        let migrator = V1Migrator()
        drugList.drugs.forEach { migrator.cache($0) }
        return (
            migrator.migrateFromRLMAvailability(container: timingContainer, sourceList: drugList),
            migrator.toV1DrugList(drugList)
        )
    }
    
    private static func makeInitialGroup(_ entry: Entry) -> RLM_MedicineEntryGroup {
        let group = RLM_MedicineEntryGroup()
        group.representableDate = entry.date
        return group
    }
}


