import Combine
import SwiftUI

public final class NotificationInfoViewState: ObservableObject {
    private var cancellables = Set<AnyCancellable>()
    private let manualUpdateSubject = {
        PassthroughSubject<Date, Never>()
    }()

    // View state
    @Published var notificationModels = [NotificationInfoViewModel]()
    @Published var permissionsGranted = false

    public func startPublishing() {
        stopPublishing()
        modelStream
            .subscribe(on: DispatchQueue.global())
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] value in
                self?.notificationModels = value
            })
            .store(in: &cancellables)
    }

    public func stopPublishing() {
        cancellables = Set()
    }

    private func timerStream() -> AnyPublisher<Date, Never> {
        Timer.publish(every: 2, on: .current, in: .common)
            .autoconnect()
            .map{ _ in Date() }
            .merge(with: manualUpdateSubject)
            .merge(with: Just(.init()))
            .receive(on: DispatchQueue.global())
            .eraseToAnyPublisher()
    }

    private var pendingRequestStream: AnyPublisher<[UNNotificationRequest], Never> {
        return timerStream()
            .handleEvents(receiveOutput: { date in
                log { Event("\(date): Fetching pending notifications") }
            })
            .compactMap{ [weak self] _ in self?.fetchedRequests() }
            .handleEvents(receiveOutput: { models in
                log { Event("Got pending notifications: \(models.count)") }
            })
            .eraseToAnyPublisher()
    }

    private func fetchedRequests() -> [UNNotificationRequest] {
        let semaphore = DispatchSemaphore(value: 0)
        var fetchedRequests: [UNNotificationRequest] = []
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            fetchedRequests = requests
            semaphore.signal()
        }
        semaphore.wait()
        return fetchedRequests
    }

    private var modelStream: AnyPublisher<[NotificationInfoViewModel], Never> {
        return pendingRequestStream
            .map{ requests in
                requests
                    .compactMap{ $0.asInfoViewModel }
                    .sorted{ $0.deleteTitleName < $1.deleteTitleName }
            }
            .handleEvents(
                receiveSubscription: { _ in log{ Event("ModelStream subscription started") } },
                receiveOutput: { model in log{ Event("Model produced: \(model.count)") } },
                receiveCancel: { log{ Event("ModelStream subscription cancelled") } }
            )
            .eraseToAnyPublisher()
    }

    var permissionStateStream: AnyPublisher<Bool, Never> {
        return $permissionsGranted.eraseToAnyPublisher()
    }

    func removeExistingNotification(_ notificationId: String) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [notificationId])
        manualUpdateSubject.send(Date())
    }

    func removeCurrentNotifications() {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        DispatchQueue.main.async { [weak self] in
            self?.notificationModels = []
        }
    }

    func requestPermissions() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { [weak self] granted, error in
            if let error = error {
                log { Event("Failed to acquire notificaiton permissions: \(error)", .error)}
            }
            log { Event("Notifcation grant state: \(granted)")}
            asyncMain {
                self?.permissionsGranted = granted
            }
        }
    }

    func scheduleForDrug(_ drug: Drug) {
        let notificationCenter = UNUserNotificationCenter.current()
        let request = drug.asNotificationRequest()
        notificationCenter.add(request) { [weak self] error in
            if let error = error {
                log{ Event("Failed to schedule notification: \(error)", .error) }
            }
            log{ Event("Notification scheduling resolved") }
            self?.manualUpdateSubject.send(Date())
        }
    }
}

public struct NotificationScheduler {
    public let notificationState: NotificationInfoViewState

    func scheduleLocalNotification(for drug: Drug) {
        notificationState.scheduleForDrug(drug)
    }

    func scheduleLocalNotifications(for drugs: [Drug]) {
        drugs.forEach{ scheduleLocalNotification(for: $0) }
    }
}

struct DrugNotificationUserInfo {
    let drugId: DrugId
    let drugName: String

    init (id: DrugId,
          name: String) {
        self.drugId = id
        self.drugName = name
    }

    init? (_ info: [AnyHashable: Any]) {
        guard let drugName = info["drugName"] as? String else { return nil }
        self.drugId = info["drugId"] as? DrugId ?? drugName
        self.drugName = drugName
    }

    var toNotificationContent: [AnyHashable: Any] {
        return [
            "drugId": drugId,
            "drugName": drugName
        ]
    }
}

extension Drug {
    func asNotificationRequest(_ startDate: Date = Date()) -> UNNotificationRequest {
        let calendar = Calendar.current
        let sourceDate = calendar.date(byAdding: .second, value: Int(doseTimeInSeconds), to: startDate)!

        // Make content
        let content = UNMutableNotificationContent()
        content.title = "You can take \(drugName)"
        content.body = "Scheduled reminder for \(DateFormatting.DefaultDateShortTime.string(from: sourceDate))."
        content.sound = UNNotificationSound(named: .init("slow-spring-board.caf"))
        content.userInfo = DrugNotificationUserInfo(id: id, name: drugName)
            .toNotificationContent

        // Create time to notify
        let requestedComponents = calendar.dateComponents(
            [.second, .minute, .hour, .day, .month, .year],
            from: sourceDate
        )

        // Trigger determines next available display time
        let calendarTrigger = UNCalendarNotificationTrigger(
            dateMatching: requestedComponents,
            repeats: false
        )

        // Create the request
        let uuidString = UUID().uuidString
        return UNNotificationRequest(
            identifier: uuidString,
            content: content,
            trigger: calendarTrigger
        )
    }
}

extension UNNotificationRequest {
    var calendarDate: Date? {
        (trigger as? UNCalendarNotificationTrigger)?.nextTriggerDate()
    }

    var logInfo: String {
        return String(describing: trigger)
            .appending("\n--")
            .appending(String(describing: (trigger as? UNCalendarNotificationTrigger)?.nextTriggerDate()))
            .appending("\n--")
            .appending(String(describing: content.userInfo["drugName"] as? String))
    }

    var asInfoViewModel: NotificationInfoViewModel? {
        guard let triggerDate = calendarDate,
              let info = DrugNotificationUserInfo(content.userInfo)
        else {
            log { Event("Notification missing data: \(logInfo)", .error) }
            return nil
        }

        let timeUntilTrigger = Date().distanceString(triggerDate,
                                                     postfixSelfIsBefore: "from now",
                                                     postfixSelfIsAfter: "ago")
        return NotificationInfoViewModel(
            notificationId: identifier,
            titleText: content.title,
            messageText: content.body,
            triggerDateText: "Scheduled for \(timeUntilTrigger).",
            deleteTitleName: info.drugName,
            triggerDate: triggerDate
        )
    }
}
