import Foundation
import Combine

public enum Criticality: String, EquatableFileStorable {
	case info
    case warning
    case error
}

public struct Event: CustomStringConvertible, EquatableFileStorable {
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
    private static let shared: AppEvents = AppEvents()
    public static let appEventsStream = shared.$appEvents.share().eraseToAnyPublisher()

    @Published private var appEvents: [Event] = []

    private init() { }

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
