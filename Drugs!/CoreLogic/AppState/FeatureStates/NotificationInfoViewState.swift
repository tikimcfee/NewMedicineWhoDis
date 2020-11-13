import Combine
import SwiftUI

public final class NotificationInfoViewState: ObservableObject {
    private let dataManager: MedicineLogDataManager
    private var cancellables = Set<AnyCancellable>()
    private let manualUpdateSubject = {
        PassthroughSubject<Date, Never>()
    }()

    // View state
    @Published var notificationModels = [NotificationInfoViewModel]()
    @Published var permissionsGranted = false

    init(_ dataManager: MedicineLogDataManager) {
        self.dataManager = dataManager
    }

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
            .map{ _ in
                print(Thread.isMainThread)
                let semaphore = DispatchSemaphore(value: 0)
                var fetchedRequests: [UNNotificationRequest] = []
                UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
                    fetchedRequests = requests
                    semaphore.signal()
                }
                semaphore.wait()
                return fetchedRequests
            }
            .handleEvents(receiveOutput: { models in
                log { Event("Got pending notifications: \(models.count)") }
            })
            .eraseToAnyPublisher()
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

    func scheduleForDrug(_ drug: Drug = Drug.init("TestDrug", [], 0.1)) {
        let notificationCenter = UNUserNotificationCenter.current()
        let request = drug.asNotificationRequest
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
