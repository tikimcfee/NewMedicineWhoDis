import UserNotifications
import Combine
import SwiftUI

public struct NotificationInfoViewModel {
    let displayTitle: String
    let id: String
    let message: String
    let uglyDate: String
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
            let models = requests.map{ request in
                NotificationInfoViewModel(
                    displayTitle: request.content.title,
                    id: request.identifier,
                    message: request.content.body,
                    uglyDate:
                        (request.trigger as? UNCalendarNotificationTrigger)?
                        .nextTriggerDate()?
                        .description
                        ?? ""
                )
            }
            DispatchQueue.main.async {
                self?.notificationModels = models
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
            DispatchQueue.main.async {
                self?.permissionsGranted = granted
            }
        }
    }

    func scheduleForDrug(_ drug: Drug = Drug.init("TestDrug", [], 0.001)) {
        let sourceDate = Date().advanced(by: drug.doseTimeInSeconds)
        let calendar = Calendar.current

        // Make content
        let content = UNMutableNotificationContent()
        content.title = "Reminder for \(drug.drugName)"
        content.body = "It's about \(dateFormatterSmall.string(from: sourceDate)). time to take some \(drug.drugName)."
        content.sound = UNNotificationSound(named: .init("slow-spring-board.caf"))

        // Create time to notify
        let requestedComponents = calendar.dateComponents(
            [.second, .minute, .hour, .day, .month, .year],
            from: sourceDate
        )

        let calendarTrigger = UNCalendarNotificationTrigger(
            dateMatching: requestedComponents,
            repeats: false
        )

        // Create the request
        let uuidString = UUID().uuidString
        let request = UNNotificationRequest(
            identifier: uuidString,
            content: content,
            trigger: calendarTrigger
        )

        // Schedule the request with the system.
        let notificationCenter = UNUserNotificationCenter.current()
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
    @State var canSchedule: Bool = false

    public var body: some View {
        return VStack(alignment: .center) {
            ScrollView {
                ForEach(viewState.notificationModels, id: \.id) { model in
                    VStack(alignment: .leading) {
                        Text(model.displayTitle)
                        Text(model.message)
                        Text(model.uglyDate).font(.caption)
                        Text(model.id).font(.caption)
                    }.padding(8).boringBorder
                }
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
}

#if DEBUG
struct NotificationInfoView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationInfoView().environmentObject(
            NotificationInfoViewState()
        )
    }
}
#endif

