//
//  CoreInsights.swift
//  Drugs!
//
//  Created by Ivan Lugo on 10/20/19.
//  Copyright © 2019 Ivan Lugo. All rights reserved.
//

import Foundation

let APP_EVENTS = AppEvents()

public func eTag(_ object: Any?) -> String {
	return String(describing: type(of: object))
}

public enum Criticality: String {
	case low, medium, high, critical
}

public struct Event: CustomStringConvertible {
	let tag: String
	let message: String
	let criticality: Criticality
	
	init (
		_ tagObject: Any? = nil,
		_ message: String = "",
		_ criticality: Criticality = .low
	) {
		self.tag = eTag(tagObject)
		self.message = message
		self.criticality = criticality
	}
	
	public var description: String {
		return "["
			+ "\(tag).."
			+ "\(criticality.rawValue)"
			+ "]::\(message)"
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
