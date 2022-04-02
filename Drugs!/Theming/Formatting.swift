import Foundation

struct DateFormatting {
    static let EntryCellTime: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .none
        dateFormatter.timeStyle = .short
        return dateFormatter
    }()
    
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
    struct TimeDifference {
        let days: Int
        let hours: Int
        let minutes: Int
        let fromWeekday: Int?
        let toWeekday: Int?
        
        var weekdayDiffers: Bool { fromWeekday != toWeekday }
    }
    
    func timeDifference(from date: Date) -> TimeDifference {
        let calendar = Calendar.current
        let components: Set<Calendar.Component> = [
            .calendar, .era, .year, .month, .weekOfYear, .weekday, .day, .hour, .minute, .second, .nanosecond
        ]
        let thisComponents = calendar.dateComponents(components, from: self)
        let requestedComponents = calendar.dateComponents(components, from: date)
        let difference = calendar.dateComponents(components, from: thisComponents, to: requestedComponents)
        return TimeDifference(
            days: max(difference.day!, difference.day! * -1),
            hours: max(difference.hour!, difference.hour! * -1),
            minutes: max(difference.minute!, difference.minute! * -1),
            fromWeekday: requestedComponents.weekday,
            toWeekday: thisComponents.weekday
        )
    }

    func distanceString(_ date: Date,
                        postfixSelfIsBefore: String = "later",
                        postfixSelfIsAfter: String = "earlier") -> String {
        
        let difference = timeDifference(from: date)
        let (days, hours, minutes) = (difference.days, difference.hours, difference.minutes)
        
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
