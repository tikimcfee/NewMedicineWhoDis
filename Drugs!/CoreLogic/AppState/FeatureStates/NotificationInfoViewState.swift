import Combine
import SwiftUI

class TimerWrapper : ObservableObject {
    private static let defaultInterval = 2.0
    private var timer : Timer!

    @Published var now: Date = Date()

    func start(withTimeInterval interval: Double = defaultInterval) {
        timer?.invalidate()
        timer = Timer.scheduledTimer(
            withTimeInterval: interval,
            repeats: true
        ){ [weak self] _ in
            self?.now = Date()
        }
    }

    func stop() {
        timer?.invalidate()
    }

    deinit {
        timer?.invalidate()
        timer = nil
    }
}

public final class NotificationInfoViewState: ObservableObject {
    private let dataManager: MedicineLogDataManager
    private var cancellables = Set<AnyCancellable>()
    private let manualUpdateSubject = {
        PassthroughSubject<Date, Never>()
    }()
//    private let timerWrapper = TimerWrapper()

    private lazy var timerStream: AnyPublisher<Date, Never> = {
//        timerWrapper.$now
        Timer.publish(every: 2, on: .current, in: .common)
            .autoconnect()
            .map{ _ in Date() }
            .merge(with: manualUpdateSubject)
            .merge(with: Just(.init()))
            .receive(on: DispatchQueue.global())
            .eraseToAnyPublisher()
    }()

    // View state
    @Published var notificationModels = [NotificationInfoViewModel]()
    @Published var permissionsGranted = false
    @Published var fetchActive = false

    // Unpublished state to avoid automatic objectWillChange calls
    private var publishing = false

    init(_ dataManager: MedicineLogDataManager) {
        self.dataManager = dataManager
    }

    public func startPublishing() {
        guard !publishing else {
            logd{ Event("Unbalanced startPublishing()") }
            return
        }
//        timerWrapper.start()
        publishing = true
        modelStream
            .subscribe(on: DispatchQueue.global())
            .receive(on: DispatchQueue.main)
            .handleEvents(
                receiveSubscription: { _ in logd{ Event("ModelStream subscription started") } },
                receiveOutput: { model in logd{ Event("Model produced: \(model.count)") } },
                receiveCancel: { logd{ Event("ModelStream subscription cancelled") } }
            )
            .sink(receiveValue: { [weak self] value in
                self?.notificationModels = value
            })
            .store(in: &cancellables)
    }

    public func stopPublishing() {
        guard publishing else {
            logd{ Event("Unbalanced stopPublishing()") }
            return
        }
//        timerWrapper.stop()
        cancellables = Set()
        publishing = false
    }

    var pendingRequestStream: AnyPublisher<[UNNotificationRequest], Never> {
        return timerStream
            .handleEvents(receiveOutput: { date in
                logd{ Event("\(date): Fetching pending notifications") }
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
                logd{ Event("Got pending notifications: \(models.count)") }
            })
            .eraseToAnyPublisher()
    }

    var modelStream: AnyPublisher<[NotificationInfoViewModel], Never> {
        return pendingRequestStream.map{ requests in
            requests
                .compactMap{ $0.asInfoViewModel }
                .sorted{ $0.deleteTitleName < $1.deleteTitleName }
        }.eraseToAnyPublisher()
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
                loge{ Event("Failed to acquire notificaiton permissions: \(error)", .error)}
            }
            logd{ Event("Notifcation grant state: \(granted)", .debug)}
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
                loge{ Event("Failed to schedule notification: \(error)", .error) }
            }
            logd{ Event("Notification scheduling resolved", .debug) }
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
