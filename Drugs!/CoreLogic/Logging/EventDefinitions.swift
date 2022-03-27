//
//  EventDefinitions.swift
//  Drugs!
//
//  Created by Ivan Lugo on 8/22/21.
//  Copyright © 2021 Ivan Lugo. All rights reserved.
//

import Foundation

public enum Criticality: String, EquatableFileStorable, CaseIterable {
	case info
	case warning
	case error
}

public struct Event: CustomStringConvertible, EquatableFileStorable {
	let message: String
	let criticality: Criticality
	
	let file: String
	let function: String
	var date = Date()
	var dateString: String {
		DateFormatting.CustomFormatLoggingTime.string(from: date)
	}
	
	init (
		_ message: String = "",
		_ criticality: Criticality = .info,
		_ file: String = #file,
		_ function: String = #function
	) {
		self.message = message
		self.criticality = criticality
		self.file = URL(fileURLWithPath: file).lastPathComponent
		self.function = function
	}
	
	public var description: String {
        return "[\(dateString) \(criticality.rawValue) \(file):\(function)] -> \(message)"
	}
}
