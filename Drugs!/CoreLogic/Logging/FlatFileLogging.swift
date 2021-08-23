//
//  FlatFileLogging.swift
//  Drugs!
//
//  Created by Ivan Lugo on 8/22/21.
//  Copyright © 2021 Ivan Lugo. All rights reserved.
//

import Foundation

public class AppEvents {
	public static let shared: AppEvents = AppEvents()
	
	private let logFileStore = LogFileStore()
	
	private init() { }
	
	var logFile: URL { logFileStore.logFile }
	
	func eraseLogs() {
		logFileStore.cleanFile()
	}
	
	static func add(_ event: Event) {
		shared.logFileStore.appendText(event.description)
		shared.logFileStore.appendText("\n")
	}
}
