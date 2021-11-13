//
//  RealmEventLogging.swift
//  Drugs!
//
//  Created by Ivan Lugo on 8/22/21.
//  Copyright © 2021 Ivan Lugo. All rights reserved.
//

import Foundation
import RealmSwift

public protocol AppEventLogRealmManager {
	typealias RealmReceiver = (Realm) throws -> Void
	func withRealm(_ actor: RealmReceiver)
}

public class DefaultAppEventRealmManager: AppEventLogRealmManager {
	public static let shared = DefaultAppEventRealmManager()
	
	private lazy var internalRealm: Realm? = {
		try? loadAppEventLogRealm()
	}()
	
	private func loadAppEventLogRealm() throws -> Realm {
		var config = Realm.Configuration.defaultConfiguration
		config.fileURL = AppFiles.appEventLogging
		let realm = try Realm(configuration: config)
		return realm
	}
	
	public func withRealm(_ actor: RealmReceiver) {
		guard let realm = internalRealm else { return }
		do {
			try actor(realm)
		} catch {
            log { Event("\(error)", .error) }
		}
	}
}

public class RealmAppEventLogger {
	public static let shared = RealmAppEventLogger()
	public let manager = DefaultAppEventRealmManager.shared
	
	public static func add(_ event: Event) {
        let manager = shared.manager
        DispatchQueue.main.async {
            manager.withRealm { realm in
                let persistable = event.realmPersistable
                try realm.write {
                    realm.add(persistable)
                }
            }
        }
	}
}

class PersistableEvent: Object {
	@Persisted var message: String
	@Persisted var criticality: Criticality
	@Persisted var date: Date
	@Persisted var file: String
	@Persisted var function: String
}

extension Criticality: PersistableEnum { }

extension Event {
	var realmPersistable: PersistableEvent {
		let event = PersistableEvent()
		event.message = message
		event.criticality = criticality
		event.date = date
		event.file = file
		event.function = function
		return event
	}
}
