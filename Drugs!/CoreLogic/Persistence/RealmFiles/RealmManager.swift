//
//  RealmManager.swift
//  Drugs!
//
//  Created by Ivan Lugo on 8/21/21.
//  Copyright © 2021 Ivan Lugo. All rights reserved.
//

import Foundation
import RealmSwift

//MARK: - Realm Helper

class EntryLogRealmManager {
    public func loadEntryLogRealm() throws -> Realm {
        var config = Realm.Configuration.defaultConfiguration
        config.fileURL = AppFiles.entryLogRealm
        let realm = try Realm(configuration: config)
        return realm
    }
    
    #if DEBUG
    public func loadTestLogRealm() throws -> Realm {
        var config = Realm.Configuration.defaultConfiguration
        config.deleteRealmIfMigrationNeeded = true
        config.fileURL = AppFiles.Testing__entryLogRealm
        let realm = try Realm(configuration: config)
        return realm
    }
    #endif
}
