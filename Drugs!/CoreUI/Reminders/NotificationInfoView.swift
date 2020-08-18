import UserNotifications
import Combine
import SwiftUI

public struct NotificationInfoViewModel: Identifiable {
    let notificationId: String
    let titleText: String
    let messageText: String
    let triggerDateText: String
    public var id: String { return notificationId }
}

public final class NotificationInfoViewState: ObservableObject {

    @Published var permissionsGranted = false
    @Published var notificationModels = [NotificationInfoViewModel]()
    private var cancellables = Set<AnyCancellable>()

    init() {

    }

    var permissionStateStream: AnyPublisher<Bool, Never> {
        return $permissionsGranted.eraseToAnyPublisher()
    }

    func removeCurrentNotifications() {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        DispatchQueue.main.async { [weak self] in
            self?.notificationModels = []
        }
    }

    func fetchCurrentNotifications() {
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests { [weak self] requests in
            let viewModels = requests.compactMap{ $0.asInfoViewModel }
            asyncMain {
                self?.notificationModels = viewModels
            }
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

    func scheduleForDrug(_ drug: Drug = Drug.init("TestDrug", [], 0.001)) {
        let notificationCenter = UNUserNotificationCenter.current()
        let request = drug.asNotificationRequest
        notificationCenter.add(request) { [weak self] error in
            if let error = error {
                loge{ Event("Failed to schedule notification: \(error)", .error) }
            }
            logd{ Event("Notification scheduling resolved", .debug) }
            self?.fetchCurrentNotifications()
        }
    }
}

public struct NotificationInfoView: View {
    @EnvironmentObject private var viewState: NotificationInfoViewState

    public var body: some View {
        return VStack(alignment: .center) {
            ScrollView {
                notificationListView
            }.boringBorder

            Button(action: { viewState.requestPermissions() }) {
                Text("Request notification permissions")
            }.padding(8).boringBorder

            if viewState.permissionsGranted {
                Button(action: { viewState.scheduleForDrug() }) {
                    Text("Schedule default notification test")
                }.padding(8).boringBorder

                Button(action: { viewState.removeCurrentNotifications() }) {
                    Text("Clear pending notifications")
                }.padding(8).boringBorder
            }
        }
        .onAppear(
            perform: {
                viewState.requestPermissions()
                viewState.fetchCurrentNotifications()
            }
        )
    }

    private var notificationListView: some View {
        return ForEach(viewState.notificationModels, id: \.notificationId) { model in
            VStack(alignment: .leading, spacing: 4) {
                VStack(alignment: .leading) {
                    Text(model.titleText).font(.body).fontWeight(.semibold)
                    Text(model.messageText).font(.subheadline)
                }.padding(8).frame(maxWidth: .infinity, alignment: .leading).boringBorder
                Text(model.triggerDateText).font(.caption)
                    .fontWeight(.light)
                Text(model.notificationId).font(.caption)
                    .fontWeight(.ultraLight)
            }.padding(8)
        }
    }
}

extension Drug {
    var asNotificationRequest: UNNotificationRequest {
        let sourceDate = Date().advanced(by: doseTimeInSeconds)
        let calendar = Calendar.current

        // Make content
        let content = UNMutableNotificationContent()
        content.title = "You can take \(drugName)"
        content.body = "Scheduled reminder for \(dateFormatterSmall.string(from: sourceDate))."
        content.sound = UNNotificationSound(named: .init("slow-spring-board.caf"))

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
    var asInfoViewModel: NotificationInfoViewModel? {
        guard let trigger = trigger as? UNCalendarNotificationTrigger,
              let triggerDate = trigger.nextTriggerDate(),
              let formattedTriggerDate = dateFormatterSmall.string(for: triggerDate)
            else { return nil }
        
        let timeUntilTrigger = Date().distanceString(triggerDate,
                                                     postfixSelfIsBefore: "from now",
                                                     postfixSelfIsAfter: "ago")
        return NotificationInfoViewModel(
            notificationId: identifier,
            titleText: content.title,
            messageText: content.body,
            triggerDateText: "Scheduled for \(formattedTriggerDate), \(timeUntilTrigger)."
        )
    }
}

#if DEBUG
struct NotificationInfoView_Previews: PreviewProvider {
    private static func testModels() -> [NotificationInfoViewModel] {
        AvailableDrugList.defaultList.drugs
            .map { $0.asNotificationRequest }
            .compactMap{ $0.asInfoViewModel }
    }

    static var previews: some View {
        let state = NotificationInfoViewState()
        state.notificationModels = testModels()
        return NotificationInfoView().environmentObject(state)
    }
}
#endif

