//
//  RealmManager.swift
//  Drugs!
//
//  Created by Ivan Lugo on 8/21/21.
//  Copyright © 2021 Ivan Lugo. All rights reserved.
//

import Combine
import Foundation
import RealmSwift

//MARK: - Realm Helper
public protocol EntryLogRealmManager {
    func loadEntryLogRealm() throws -> Realm
}

class DefaultRealmManager: EntryLogRealmManager {
    public func loadEntryLogRealm() throws -> Realm {
        var config = Realm.Configuration.defaultConfiguration
        config.fileURL = AppFiles.entryLogRealm
        let realm = try Realm(configuration: config)
        return realm
    }
}

#if DEBUG
class TestingRealmManager: EntryLogRealmManager {
    public func loadEntryLogRealm() throws -> Realm {
        var config = Realm.Configuration.defaultConfiguration
        config.deleteRealmIfMigrationNeeded = true
        config.fileURL = AppFiles.Testing__entryLogRealm
        let realm = try Realm(configuration: config)
        return realm
    }
}
#endif

enum RealmPersistenceError: Error {
    case invalidIndex(Int)
}

class RealmPersistenceManager: ObservableObject, PersistenceManager {
    private let manager: EntryLogRealmManager
    private let migrater = V1Migrator()
    
    init(manager: EntryLogRealmManager = DefaultRealmManager()) {
        self.manager = manager
    }
    
    @Published var appData: ApplicationData = ApplicationData()
    
    var appDataStream: AnyPublisher<ApplicationData, Never> {
        $appData.eraseToAnyPublisher()
    }
    
    func getEntry(with id: String) -> MedicineEntry? {
        try? manager.loadEntryLogRealm()
            .object(ofType: RLM_MedicineEntry.self, forPrimaryKey: id)
            .map { model in migrater.toV1Entry(model) }
    }
    
    func addEntry(medicineEntry: MedicineEntry, _ handler: @escaping ManagerCallback) {
        (try? manager.loadEntryLogRealm()).map { realm in
            do {
                try realm.write {
                    realm.add(migrater.fromV1Entry(medicineEntry))
                    handler(.success(()))
                }
            } catch {
                handler(.failure(error))
            }
        }
    }
    
    func removeEntry(index: Int, _ handler: @escaping ManagerCallback) {
        (try? manager.loadEntryLogRealm()).map { realm in
            do {
                let objects = realm.objects(RLM_MedicineEntry.self)
                guard objects.count > index else { throw RealmPersistenceError.invalidIndex(index) }
                let toRemove = objects[index]
                try realm.write {
                    realm.delete(toRemove)
                    handler(.success(()))
                }
            } catch {
                handler(.failure(error))
            }
        }
    }
    
    func updateEntry(updatedEntry: MedicineEntry, _ handler: @escaping ManagerCallback) {
        (try? manager.loadEntryLogRealm()).map { realm in
            do {
                try realm.write {
                    realm.add(migrater.fromV1Entry(updatedEntry), update: .modified)
                    handler(.success(()))
                }
            } catch {
                handler(.failure(error))
            }
        }
    }
    
    func updateDrug(originalDrug: Drug, updatedDrug: Drug, _ handler: @escaping ManagerCallback) {
        (try? manager.loadEntryLogRealm()).map { realm in
            do {
                let drugToUpdate = realm.objects(RLM_Drug.self).first(where: { $0.id == updatedDrug.id })
                try realm.write {
                    drugToUpdate?.hourlyDoseTime = updatedDrug.hourlyDoseTime
                    drugToUpdate?.ingredients.removeAll()
                    drugToUpdate?.ingredients.append(objectsIn: updatedDrug.ingredients.map(migrater.fromV1Ingredient))
                    handler(.success(()))
                }
            } catch {
                handler(.failure(error))
            }
        }
    }
    
    func addDrug(newDrug: Drug, _ handler: @escaping ManagerCallback) {
        (try? manager.loadEntryLogRealm()).map { realm in
            do {
                let newRealmDrug = migrater.fromV1drug(newDrug)
                try realm.write {
                    realm.add(newRealmDrug)
                    handler(.success(()))
                }
            } catch {
                handler(.failure(error))
            }
        }
    }
    
    func removeDrug(drugToRemove: Drug, _ handler: @escaping ManagerCallback) {
        (try? manager.loadEntryLogRealm()).map { realm in
            do {
                try realm.write {
                    let toDelete = realm.object(ofType: RLM_Drug.self, forPrimaryKey: drugToRemove.id)
                    realm.delete(toDelete!)
                    handler(.success(()))
                }
            } catch {
                handler(.failure(error))
            }
        }
    }
    
    
}
