import Foundation

struct DateFormatting {
    static let ShortDateShortTime: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        return dateFormatter
    }()

    static let LongDateShortTime: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .short
        return dateFormatter
    }()

    static let NoDateMediumTime: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .none
        dateFormatter.timeStyle = .medium
        return dateFormatter
    }()

    static let NoDateShortTime: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .none
        dateFormatter.timeStyle = .short
        return dateFormatter
    }()

    static let DefaultDateShortTime: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.timeStyle = .short
        return dateFormatter
    }()

    static let CustomFormatLoggingTime: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "y-MM-dd H:m:ss.SSSS"
        return dateFormatter
    }()
}

extension Date {
    func timeDifference(from date: Date) -> (days: Int, hours: Int, minutes: Int) {
        let calendar = Calendar.current
        let components: Set<Calendar.Component> = [.calendar, .era, .year, .month, .weekOfYear, .day, .hour, .minute, .second, .nanosecond]
        let thisComponents = calendar.dateComponents(components, from: self)
        let requestedComponents = calendar.dateComponents(components, from: date)
        let difference = calendar.dateComponents(components, from: thisComponents, to: requestedComponents)
        return (
            max(difference.day!, difference.day! * -1),
            max(difference.hour!, difference.hour! * -1),
            max(difference.minute!, difference.minute! * -1)
        )
    }

    func distanceString(_ date: Date,
                        postfixSelfIsBefore: String = "later",
                        postfixSelfIsAfter: String = "earlier") -> String {
        let (days, hours, minutes) = timeDifference(from: date)
        guard days > 0 || hours > 0 || minutes > 0 else {
            return "No time change"
        }
		return ["day".simplePlural(days),
				"hour".simplePlural(hours),
				"minute".simplePlural(minutes)]
            .filter { $0.count > 0 }
            .joined(separator: ", ")
            .appending(" ")
            .appending(self < date ? postfixSelfIsBefore : postfixSelfIsAfter)
    }
}

extension String {
    func simplePlural(_ count: Int, _ defaultIfEmpty: String = "") -> String {
        return count == 0 ? defaultIfEmpty
            : count != 1 ? "\(count) \(self)s"
            : "\(count) \(self)"
    }
}
