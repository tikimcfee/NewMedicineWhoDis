import Foundation
import Combine

public func eTag(_ object: Any?) -> String {
    guard case let .some(thing) = object
        else { return "" }
	return String(describing: thing)
}

public enum Criticality: String {
	case info, warning, error
}

public struct Event: CustomStringConvertible {
	let tag: String
	let message: String
	let criticality: Criticality
	
	init (
		_ message: String = "",
        _ criticality: Criticality = .info,
        _ tag: String = #file
	) {
		self.message = message
		self.criticality = criticality
        self.tag = URL(fileURLWithPath: tag).lastPathComponent
	}
	
	public var description: String {
		return "(\(criticality.rawValue))"
			+ " \(tag)"
			+ " ::: \(message)"
	}
}

public class AppEvents: ObservableObject {
    private static var shared: AppEvents = AppEvents()
    public static var appEventsStream = shared.$appEvents.share().eraseToAnyPublisher()

    @Published private var appEvents: [Event] = []

    private init() {
        // no params
    }

	static func add(_ event: Event) {
        shared.appEvents.append(event)
    }
	
	static func dump() {
        shared.appEvents.forEach { print($0) }
    }
}

public func log(_ event: () -> Event) {
	out(event)
}

fileprivate func out(_ event: () -> Event) {
	let appEvent = event()
	AppEvents.add(appEvent)
	print(appEvent)

}
