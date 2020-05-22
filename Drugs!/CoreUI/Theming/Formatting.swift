import Foundation

// Statically used
let dateTimeFormatter: DateFormatter = {
    let dateFormatter = DateFormatter()
    dateFormatter.dateStyle = .short
    dateFormatter.timeStyle = .short
    return dateFormatter
}()

let dateFormatterLong: DateFormatter = {
    let dateFormatter = DateFormatter()
    dateFormatter.dateStyle = .long
    dateFormatter.timeStyle = .short
    return dateFormatter
}()


let dateFormatter: DateFormatter = {
    let dateFormatter = DateFormatter()
    dateFormatter.dateStyle = .none
    dateFormatter.timeStyle = .medium
    return dateFormatter
}()

let dateFormatterSmall: DateFormatter = {
    let dateFormatter = DateFormatter()
    dateFormatter.timeStyle = .short
    return dateFormatter
}()

extension Date {
    func timeDifference(from date: Date) -> (days: Int, hours: Int, minutes: Int) {
        let calendar = Calendar.current
        let timeComponents = calendar.dateComponents([.day, .hour, .minute, .second], from: self)
        let nowComponents = calendar.dateComponents([.day, .hour, .minute, .second], from: date)
        let difference = calendar.dateComponents([.day, .hour, .minute, .second], from: timeComponents, to: nowComponents)
        return (
            max(difference.day!, difference.day! * -1),
            max(difference.hour!, difference.hour! * -1),
            max(difference.minute!, difference.minute! * -1)
        )
    }

    func distanceString(_ date: Date) -> String {
        let (days, hours, minutes) = timeDifference(from: date)

        if hours == 0 && minutes == 0 {
            return "No time change"
        } else {
            let hoursText = hours != 1 ? "hours" : "hour"
            let minuteText = minutes != 1 ? "minutes" : "minute"
            let suffix = self < date ? "later" : "earlier"

            return String(format: "%d %@, %d %@ %@", hours, hoursText, minutes, minuteText, suffix)
        }
    }
}
