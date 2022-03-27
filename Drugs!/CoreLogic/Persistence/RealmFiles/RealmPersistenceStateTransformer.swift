//
//  RealmPersistenceStateTransformer.swift
//  Drugs!
//
//  Created by Ivan Lugo on 2/11/22.
//  Copyright © 2022 Ivan Lugo. All rights reserved.
//

import Foundation
import RealmSwift
import Combine

class RealmPersistenceStateTransformer {
    @Published var appData: ApplicationData = ApplicationData()
    
    private let manager: EntryLogRealmManager
    private var entriesToken: NotificationToken?
    private var drugsToken: NotificationToken?
    
    init(manager: EntryLogRealmManager) {
        self.manager = manager
        try? setupObservations()
    }
    
    deinit {
        entriesToken?.invalidate()
        drugsToken?.invalidate()
    }
    
    func doMigrations() throws {
        manager.access { realm in
            
        }
    }
    
    func setupObservations() throws {
        let realm = try manager.loadEntryLogRealm()
        entriesToken = realm
            .objects(RLM_MedicineEntry.self)
            .sorted(by: \.date, ascending: false)
            .observe { [weak self] change in
                switch change {
                case let .initial(results):
                    log { Event("Initial entry list loaded") }
                    self?.appData.mainEntryList = results.map { V1Migrator().toV1Entry($0) }
                case let .update(results, previousDeleted, newInserted, previousModified):
                    log { Event("Entry list updated") }
                    self?.appData.mainEntryList = results.map { V1Migrator().toV1Entry($0) }
                case let .error(error):
                    log { Event("Failed to observe, \(error.localizedDescription)", .error)}
                }
            }
        drugsToken = RLM_AvailableDrugList
            .defeaultObservableListFrom(realm)
            .observe { [weak self] change in
                switch change {
                case let .initial(results):
                    log { Event("Initial drug list loaded") }
                    if let first = results.first {
                        self?.appData.availableDrugList = V1Migrator().toV1DrugList(first)
                    }
                case let .update(results, _, _, _):
                    log { Event("Drug list updated") }
                    if let first = results.first {
                        self?.appData.availableDrugList = V1Migrator().toV1DrugList(first)
                    }
                case let .error(error):
                    log { Event("Failed to observe, \(error.localizedDescription)", .error) }
                }
            }
    }
}
