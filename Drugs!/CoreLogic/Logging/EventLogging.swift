import Foundation
import Combine

public func log(_ event: () -> Event) {
	out(event)
}

public func log(
    _ message: @autoclosure @escaping () -> String,
    _ criticality: @autoclosure @escaping () -> Criticality = .info,
    _ file: String =  #file,
    _ function: String = #function
) {
    out({ Event(message(), criticality(), file, function) })
}

public func log(
    _ error: @autoclosure @escaping () -> Error,
    _ message: @autoclosure @escaping () -> String? = nil,
    _ file: String = #file,
    _ function: String = #function
) {
    let message = message() ?? "Default error log: "
    out({ Event("\(message) \(error())", .error, file, function) })
}


fileprivate func out(_ event: () -> Event) {
	let appEvent = event()
	debugPrint(appEvent)
	RealmAppEventLogger.add(appEvent)
}
