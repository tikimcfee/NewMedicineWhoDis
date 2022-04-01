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
    private let migrator = V1Migrator()
    
    typealias InfoPublisher = AnyPublisher<(AvailabilityInfo, AvailableDrugList), Never>
    lazy var infoPublisher: InfoPublisher = {
        manager.accessImmediate { realm in
            try self.makeRootInfoPublisher(from: realm)
        } ?? {
            log("No info publisher to send results to. That stinks.")
            return Empty().eraseToAnyPublisher()
        }()
    }()
    
    init(manager: DefaultRealmManager) {
        self.manager = manager
    }
    
    deinit {
        log("Calculator deinit")
    }
    
    func start(receiver: @escaping ContainerReceiverGetter) {
        bag.insert(
            infoPublisher.sink { [receiver] newInfo in
                receiver { toUpdate in
                    log("Alert receiver of new info")
                    toUpdate.info = newInfo.0
                    toUpdate.availableDrugs = newInfo.1
                }
            }
        )
    }
}

// MARK: -- Publishers
private extension AvailabilityInfoCalculator {
    func makeRootInfoPublisher(from realm: Realm) throws -> InfoPublisher {
        try ensureInitialRealmState(
            RLM_MedicineEntry.observableResults(realm),
            RLM_AvailabilityInfoContainer.observableResults(realm),
            RLM_AvailableDrugList.observableResults(realm),
            in: realm
        )
        
        return Publishers.CombineLatest(
            buildEntryListPublisher(realm),
            buildDrugListPublisher(realm)
        )
        .compactMap { [weak self] in self?.mergeObservedResults($0, $1) }
        .eraseToAnyPublisher()
    }
    
    func mergeObservedResults(
        _ entries: Results<RLM_MedicineEntry>,
        _ drugList: RLM_AvailableDrugList
    ) -> (AvailabilityInfo, AvailableDrugList)? {
        
        // TODO: better way to grab the value and persist and return info
        // maybe just get finally get rid of old info
        let newMap = Self.buildNewStatesMap(entries: entries, drugList: drugList)
        guard let container = persistContainerChange(newMap, drugList) else {
            log("Failed to persist container; cannot migrate to v1 drug list")
            return nil
        }
        
        let newInfo = migrator.migrateFromRLMAvailability(
            container: container,
            sourceList: drugList
        )
        
        return (newInfo, migrator.toV1DrugList(drugList))
    }
    
    func persistContainerChange(
        _ newMap: Map<Drug.ID, RLM_AvailabilityStats>,
        _ drugList: RLM_AvailableDrugList
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
    
    func buildEntryListPublisher(_ realm: Realm) -> AnyPublisher<Results<RLM_MedicineEntry>, Never> {
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
