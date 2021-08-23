//
//  AppFiles.swift
//  Drugs!
//
//  Created by Ivan Lugo on 8/22/21.
//  Copyright © 2021 Ivan Lugo. All rights reserved.
//

import Foundation

// MARK: - Default file locations

// MARK: -- Flat files
extension AppFiles {
	public static var medicineLogsDirectory: URL {
		directory(named: "medicineLogs")
	}
	
	public static var medicineLogsFile: URL {
		file(named: "core_logs_file.json", in: medicineLogsDirectory)
	}
	
	public static var appEventLogging: URL {
		file(named: "app_event_logs.txt", in: medicineLogsDirectory)
	}	
}

// MARK: -- Realm files
extension AppFiles {	
	public static var realmsDirectory: URL {
		directory(named: "logs-in-realms")
	}
	
	public static var cacheRealmsDirectory: URL {
		directory(named: "cache-in-realms")
	}
	
	public static var entryLogRealm: URL {
		file(named: "realmfile_entry_log", in: realmsDirectory)
	}
	
	public static var appEventLogsRealm: URL {
		file(named: "realmfile_appevents_log", in: realmsDirectory)
	}
	
	#if DEBUG
	public static var Testing__entryLogRealm: URL {
		file(named: "TESTS__realmfile_entry_log__TESTS", in: realmsDirectory)
	}
	#endif
}
