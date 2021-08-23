import Foundation
import Combine

public func log(_ event: () -> Event) {
	out(event)
}

fileprivate func out(_ event: () -> Event) {
	let appEvent = event()
	debugPrint(appEvent)
	RealmAppEventLogger.add(appEvent)
}
