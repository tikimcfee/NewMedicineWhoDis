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
enum RealmManagerError: Error {
    case onLoadError(internalError: Error)
}

public protocol EntryLogRealmManager {
    func loadEntryLogRealm() throws -> Realm
	func access(_ onLoad: (Realm) throws -> Void)
}

extension EntryLogRealmManager {
	func access(_ onLoad: (Realm) throws -> Void) {
        do {
            let realm = try loadEntryLogRealm()
            try onLoad(realm)
        } catch let RealmManagerError.onLoadError(internalError) {
            log { Event("Failed to load realm: \(internalError.localizedDescription)", .error) }
        } catch {
            log { Event("Error during realm modification: \(error.localizedDescription)", .error) }
        }
	}
	
	func accessImmediate<T>(_ onLoad: (Realm) throws -> T?) -> T? {
        do {
            let realm = try loadEntryLogRealm()
            return try onLoad(realm)
        } catch let RealmManagerError.onLoadError(internalError) {
            log { Event("Failed to load realm: \(internalError.localizedDescription)", .error) }
        } catch {
            log { Event("Error during realm modification: \(error.localizedDescription)", .error) }
        }
        return nil
	}
}

class DefaultRealmManager: EntryLogRealmManager {
    public func makeModifier() -> DefaultRealmModifer {
        DefaultRealmModifer(
            manager: self,
            infoCalculator: AvailabilityInfoCalculator(manager: self)
        )
    }
    
    public func loadEntryLogRealm() throws -> Realm {
        do {
            return try Realm(configuration: Self.makeEntryLogConfiguration())
        } catch {
            throw RealmManagerError.onLoadError(internalError: error)
        }
    }
    
    public static func makeEntryLogConfiguration() -> Realm.Configuration {
        var config = Realm.Configuration.defaultConfiguration
        config.schemaVersion = CURRENT_SCHEMA_VERSION
        config.fileURL = AppFiles.entryLogRealm
//        config.deleteRealmIfMigrationNeeded = true
        config.migrationBlock = { migration, flag in
            log { Event("Migration: New schema -- \(migration.newSchema.description)", .info) }
            log { Event("Migration: Old schema -- \(migration.oldSchema.description)", .info) }
        }
        return config
    }
}

// Why are they hiding this? Why is this a bad idea to generally do? We'll see lolol
func safeWrite<Value>(_ value: Value, _ block: (Value) -> Void) where Value: ThreadConfined {
    let thawed = value.realm == nil ? value : value.thaw() ?? value
    if let realm = thawed.realm, !realm.isInWriteTransaction {
        try! realm.write {
            block(thawed)
        }
    } else {
        block(thawed)
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

