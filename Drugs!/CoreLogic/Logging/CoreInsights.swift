//
//  CoreInsights.swift
//  Drugs!
//
//  Created by Ivan Lugo on 10/20/19.
//  Copyright © 2019 Ivan Lugo. All rights reserved.
//

import Foundation

public func eTag(_ object: Any?) -> String {
    guard case let .some(thing) = object
        else { return "" }
	return String(describing: thing)
}

public enum Criticality: String {
	case debug, warning, error
}

public struct Event: CustomStringConvertible {
	let tag: String
	let message: String
	let criticality: Criticality
	
	init (
		_ message: String = "",
        _ criticality: Criticality = .debug,
        _ tag: String = #file
	) {
		self.tag = URL(fileURLWithPath: tag).lastPathComponent
		self.message = message
		self.criticality = criticality
	}
	
	public var description: String {
		return "(\(criticality.rawValue))"
			+ " \(tag)"
			+ " --| \(message)"
	}
}

public struct AppEvents {
	public private(set) static var appEvents: [Event] = []
	
	static func add(_ event: Event) { appEvents.append(event) }
	
	static func dump() { appEvents.forEach { print($0) } }
}

public func logd(_ event: () -> Event) {
	out(event)
}

public func loge(_ event: () -> Event) {
	out(event)
}

fileprivate func out(_ event: () -> Event) {
	let theEvent = event()
	AppEvents.add(theEvent)
	print(theEvent)

}
