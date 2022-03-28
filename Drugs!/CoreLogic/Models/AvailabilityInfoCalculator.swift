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
    lazy var workQueue = DispatchQueue(label: "CalculatorQueue-\(id)", qos: .userInteractive)
    
    private var bag = Set<AnyCancellable>()
    var realmTokens = [NotificationToken]()
    let entryStatsPersister: EntryStatsInfoPersister
    
    init(persister: EntryStatsInfoPersister) {
        self.entryStatsPersister = persister
    }
    
    deinit {
        log("Calculator state cleaning up")
    }
    
    func start(receiver: @escaping ContainerReceiverGetter) {
        entryStatsPersister.start()
        entryStatsPersister.manager.access { realm in
            bag.insert(
                Publishers.CombineLatest(
                    RLM_AvailabilityInfoContainer.defeaultObservableListFrom(realm).collectionPublisher,
                    RLM_AvailableDrugList.defeaultObservableListFrom(realm).collectionPublisher
                )
                .compactMap { result in return Self.makeUpdateInfo(container: result.0, drugs: result.1) }
                .receive(on: RunLoop.main)
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
    
    private static func makeUpdateInfo(
        container: Results<RLM_AvailabilityInfoContainer>?,
        drugs: Results<RLM_AvailableDrugList>?
    ) -> (AvailabilityInfo, AvailableDrugList)? {
        log("Starting InfoCalculator update")
        
        guard let drugs = drugs?.first,
              let container = container?.first else {
            log(AvailabilityInfoError.missingDrugList)
            return nil
        }
        
        let migrator = V1Migrator()
        let v1Info = migrator.migrateFromStatsContainer(sourceList: drugs, into: container)
        let v1Drugs = migrator.toV1DrugList(drugs)
        
        return (v1Info, v1Drugs)
    }

        
    static func computeInfo(startDate: Date = Date(),
                            availableDrugs: AvailableDrugList,
                            entries: [MedicineEntry]) -> AvailabilityInfo {
        var drugDates = [Drug: Date]()
        availableDrugs.drugs.forEach { drugDates[$0] = startDate }
        
        // Use the newest drug info if there is one.
        // This is important so old entries don't step on new drugs.
        for entry in entries {
            for (drug, _) in entry.drugsTaken {
                let newestDrug = availableDrugs.drugFor(id: drug.id) ?? drug
                let nextDoseTime = entry.date.advanced(by: newestDrug.doseTimeInSeconds)
                
                guard let lastKnownTakenDate = drugDates[newestDrug] else {
                    drugDates[newestDrug] = nextDoseTime
                    continue
                }
                
                if lastKnownTakenDate < nextDoseTime {
                    drugDates[newestDrug] = nextDoseTime
                }
            }
        }
        
        return drugDates.reduce(into: AvailabilityInfo()) { result, entry in
            result[entry.key] = (entry.value <= startDate, entry.value)
        }
    }
}

private extension AvailableDrugList {
    func drugFor(id: DrugId) -> Drug? {
        drugs.first(where: { $0.id == id })
    }
}
