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
    public func loadEntryLogRealm() throws -> Realm {
        var config = Realm.Configuration.defaultConfiguration
        config.fileURL = AppFiles.entryLogRealm
        config.migrationBlock = { migration, flag in
            log { Event("Migration: New schema -- \(migration.newSchema.description)", .info) }
            log { Event("Migration: Old schema -- \(migration.oldSchema.description)", .info) }
        }
        
        do {
            return try Realm(configuration: config)
        } catch {
            throw RealmManagerError.onLoadError(internalError: error)
        }
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

