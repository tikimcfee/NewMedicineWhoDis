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
    case missingDrugList
    case missingBindTargetRealm
}

extension AvailabilityInfo {
    func canTake(_ drug: Drug) -> Bool {
        return self[drug]?.canTake == true
    }
}

// Receiver protocol must allow weak reference so state is not implicitly retained,
// captured by the immediate usage in the sink call
protocol InfoReceiver: AnyObject {
    var selectionModelReceiver: ((inout DrugSelectionContainerModel) -> Void) -> () { get }
}

class AvailabilityInfoCalculator: ObservableObject {
    private lazy var id = UUID()
    lazy var workQueue = DispatchQueue(label: "CalculatorQueue-\(id)", qos: .userInteractive)
    private var bag = Set<AnyCancellable>()
    var realmTokens = [NotificationToken]()
    
    private let entriesSubject = PassthroughSubject<Results<RLM_MedicineEntry>, Never>()
    private let drugListSubject = PassthroughSubject<Results<RLM_AvailableDrugList>, Never>()
    private lazy var combine = Publishers.CombineLatest(entriesSubject, drugListSubject)
    
    @Published var info: AvailabilityInfo = AvailabilityInfo()
    
    init(receiver: InfoReceiver) {
        bag = [
            combine
                .receive(on: workQueue)
                .compactMap { result in Self.updateInfo(entries: result.0, drugs: result.1) }
                .receive(on: RunLoop.main)
                .sink { [weak receiver] newInfo in
                    receiver?.selectionModelReceiver { toEdit in
                        log("Alert receiver of new info")
                        toEdit.info = newInfo.0
                        toEdit.availableDrugs = newInfo.1
                    }
                }
        ]
    }
    
    deinit {
        log("Calculator state cleaning up")
    }
    
    func bindModelSnapshot(_ unsafeTarget: RLM_MedicineEntry) {
        self.bindModelSnapshotImpl(unsafeTarget)
    }
    
    private func bindModelSnapshotImpl(_ unsafeTarget: RLM_MedicineEntry) {
        log("--- Start observing: \(unsafeTarget.id)::[\(String(describing: Thread.current))]")
        guard let thawedModel = unsafeTarget.thaw(),
              let realm = thawedModel.realm?.thaw()
        else {
            log(AvailabilityInfoError.missingBindTargetRealm)
            return
        }
        
        realmTokens = [
            realm.objects(RLM_MedicineEntry.self).observe { [weak entriesSubject] change in
                log("--- Observing entries: \(unsafeTarget.id)::[\(String(describing: Thread.current))]")
                switch change {
                case let .initial(results):
                    entriesSubject?.send(results.freeze())
                case let .update(results, _, _, _):
                    entriesSubject?.send(results.freeze())
                case let .error(error):
                    log(error)
                    break
                }
            },
            RLM_AvailableDrugList.defeaultObservableListFrom(realm).observe { [weak drugListSubject] change in
                log("--- Observe drug list: \(unsafeTarget.id)::[\(String(describing: Thread.current))]")
                switch change {
                case let .initial(results):
                    drugListSubject?.send(results.freeze())
                case let .update(results, _, _, _):
                    drugListSubject?.send(results.freeze())
                case let .error(error):
                    log(error)
                    break
                }
            }
        ]
    }
    
    private static func updateInfo(
        entries: Results<RLM_MedicineEntry>,
        drugs: Results<RLM_AvailableDrugList>?
    ) -> (AvailabilityInfo, AvailableDrugList)? {
        log("Starting InfoCalculator update")
        
        guard let drugs = drugs?.first else {
            log(AvailabilityInfoError.missingDrugList)
            return nil
        }
                
        let migrator = V1Migrator()
        let v1Entries = entries.map { migrator.toV1Entry($0) }
        let v1Drugs = migrator.toV1DrugList(drugs)
        let newInfo = Self.computeInfo(availableDrugs: v1Drugs, entries: Array(v1Entries))
        
        return (newInfo, v1Drugs)
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
