//
//  RealmPersistenceManager.swift
//  Drugs!
//
//  Created by Ivan Lugo on 2/11/22.
//  Copyright © 2022 Ivan Lugo. All rights reserved.
//

import Foundation
import Realm
import Combine
import SwiftUI

enum RealmPersistenceError: Error {
    case invalidRemovalId(String)
    case invalidMigrationCall
}

class RealmPersistenceManager: ObservableObject, PersistenceManager {
    private let manager: EntryLogRealmManager
    private let tranformer: RealmPersistenceStateTransformer
    private let migrater = V1Migrator()
    
    init(manager: EntryLogRealmManager = DefaultRealmManager()) {
        self.manager = manager
        self.tranformer = RealmPersistenceStateTransformer(manager: manager)
    }
    
    var appDataStream: AnyPublisher<ApplicationData, Never> {
        tranformer.$appData.eraseToAnyPublisher()
    }
    
    var isMigrationNeeded: Bool {
        return manager.accessImmediate { realm in
            return self.migrater.isMigrationNeeded(into: realm)
        } ?? {
            log { Event("nil manager access, realm may be inaccessible!", .error) }
            return true
        }()
    }
    
    func checkAndCompleteMigrations(_ sourceFlatFile: FilePersistenceManager) throws {
        manager.access { realm in
            try migrater.migrate(manager: sourceFlatFile, into: realm)
        }
    }
    
    func getEntry(with id: String) -> MedicineEntry? {
        try? manager.loadEntryLogRealm()
            .object(ofType: RLM_MedicineEntry.self, forPrimaryKey: id)
            .map { model in migrater.toV1Entry(model) }
    }
    
    func addEntry(medicineEntry: MedicineEntry, _ handler: @escaping ManagerCallback) {
        manager.access { realm in
            do {
                try realm.write {
                    realm.add(migrater.fromV1Entry(medicineEntry), update: .all)
                    handler(.success(()))
                }
            } catch {
                handler(.failure(error))
            }
        }
    }
    
    func removeEntry(with id: MedicineEntry.ID, _ handler: @escaping ManagerCallback) {
        manager.access { realm in
            do {
                guard let object = realm.object(ofType: RLM_MedicineEntry.self, forPrimaryKey: id) else {
                    throw RealmPersistenceError.invalidRemovalId(id)
                }
                try realm.write {
                    realm.delete(object)
                    handler(.success(()))
                }
            } catch {
                handler(.failure(error))
            }
        }
    }
    
    struct UpdateEntryError: Error {
        var updated: MedicineEntry
        var reason = "undefined"
    }
    
    func updateEntry(updatedEntry: MedicineEntry, _ handler: @escaping ManagerCallback) {
        manager.access { realm in
            do {
                try realm.write {
//                    guard let toUpdate = realm.object(ofType: RLM_MedicineEntry.self, forPrimaryKey: updatedEntry.id) else {
//                        throw UpdateEntryError(updated: updatedEntry, reason: "Missing target entry")
//                    }
                    let updatedCopy = migrater.fromV1Entry(updatedEntry)
                    realm.add(updatedCopy, update: .all)
                    handler(.success(()))
                }
            } catch {
                handler(.failure(error))
            }
        }
    }
    
    struct UpdateError: Error {
        var original: Drug
        var updated: Drug
        var reason = "undefined"
    }
    
    func updateDrug(originalDrug: Drug, updatedDrug: Drug, _ handler: @escaping ManagerCallback) {
        manager.access { realm in
            do {
                guard let availableDrugList = RLM_AvailableDrugList.defaultFrom(realm) else {
                    throw UpdateError(original: originalDrug, updated: updatedDrug, reason: "Missing root drug list")
                }
                guard let drugToUpdate = availableDrugList.drugs.first(where: { $0.id == updatedDrug.id }) else {
                    throw UpdateError(original: originalDrug, updated: updatedDrug, reason: "Missing drug in realm list")
                }
                try realm.write {
                    drugToUpdate.name = updatedDrug.drugName
                    drugToUpdate.hourlyDoseTime = updatedDrug.hourlyDoseTime
                    drugToUpdate.ingredients.removeAll()
                    drugToUpdate.ingredients.append(objectsIn: updatedDrug.ingredients.map(migrater.fromV1Ingredient))
                    handler(.success(()))
                }
            } catch let error as UpdateError {
                log { Event(error.reason, .error) }
                handler(.failure(error))
            } catch {
                log { Event("\(error)", .error) }
                handler(.failure(error))
            }
        }
    }
    
    struct AddError: Error {
        var new: Drug
        var reason = "undefined"
    }
    
    func addDrug(newDrug: Drug, _ handler: @escaping ManagerCallback) {
        manager.access { realm in
            do {
                guard let availableDrugList = RLM_AvailableDrugList.defaultFrom(realm) else {
                    throw AddError(new: newDrug, reason: "Missing root drug list")
                }
                guard availableDrugList.drugs.first(where: { $0.id == newDrug.id} ) == nil else {
                    throw AddError(new: newDrug, reason: "ID already exists")
                }
                let newRealmDrug = migrater.fromV1drug(newDrug)
                try realm.write {
                    availableDrugList.drugs.append(newRealmDrug)
                    handler(.success(()))
                }
            } catch {
                handler(.failure(error))
            }
        }
    }
    
    struct RemoveError: Error {
        var remove: Drug
        var reason = "undefined"
    }
    
    func removeDrug(drugToRemove: Drug, _ handler: @escaping ManagerCallback) {
        manager.access { realm in
            do {
                guard let availableDrugList = RLM_AvailableDrugList.defaultFrom(realm) else {
                    throw RemoveError(remove: drugToRemove, reason: "Missing root drug list")
                }
                guard let index = availableDrugList.drugs.firstIndex(where: { $0.id == drugToRemove.id} ) else {
                    throw RemoveError(remove: drugToRemove, reason: "ID missing")
                }
                try realm.write {
                    availableDrugList.drugs.remove(at: index)
                    handler(.success(()))
                }
            } catch {
                handler(.failure(error))
            }
        }
    }
    
#if DEBUG
    func removeAllData() {
        manager.access { realm in
            try? realm.write {
                let all = realm.objects(RLM_MedicineEntry.self)
                realm.delete(all)
            }
        }
    }
    
    func __internalAppData() -> ApplicationData {
        return tranformer.appData
    }
#endif
}
