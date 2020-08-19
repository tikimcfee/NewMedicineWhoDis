import UserNotifications
import Combine
import SwiftUI

public struct NotificationInfoViewModel: Identifiable {
    let notificationId: String
    let titleText: String
    let messageText: String
    let triggerDateText: String
    let deleteTitleName: String
    let triggerDate: Date
    public var id: String { return notificationId }
}

public final class NotificationInfoViewState: ObservableObject {
    private let dataManager: MedicineLogDataManager
    private var cancellables = Set<AnyCancellable>()

    @Published var permissionsGranted = false
    @Published var notificationModels = [NotificationInfoViewModel]()
    @Published var fetchActive = false

    init(_ dataManager: MedicineLogDataManager) {
        self.dataManager = dataManager

        Timer.publish(every: 5, on: .current, in: .common)
            .autoconnect()
            .sink(receiveValue: { [weak self] _ in self?.fetchCurrentNotifications() })
            .store(in: &cancellables)
    }

    var permissionStateStream: AnyPublisher<Bool, Never> {
        return $permissionsGranted.eraseToAnyPublisher()
    }

    func removeExistingNotification(_ notificationId: String) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [notificationId])
        fetchCurrentNotifications()
    }

    func removeCurrentNotifications() {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        DispatchQueue.main.async { [weak self] in
            self?.notificationModels = []
        }
    }

    func fetchCurrentNotifications() {
        guard !fetchActive else { return }
        asyncMain { [weak self] in
            self?.fetchActive = true
            logd{ Event("Fetching pending notifications...", .debug) }
            let center = UNUserNotificationCenter.current()
            center.getPendingNotificationRequests { requests in
                let viewModels = requests
                    .compactMap{ $0.asInfoViewModel }
                    .sorted { $0.triggerDate > $1.triggerDate}

                asyncMain {
                    self?.notificationModels = viewModels
                    self?.fetchActive = false
                }
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

    func scheduleForDrug(_ drug: Drug = Drug.init("TestDrug", [], 0.1)) {
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

    @State private var deleteRequestModel: NotificationInfoViewModel? = nil

    public var body: some View {
        VStack(alignment: .leading) {
            ScrollView {
                notificationListView
                    .padding(8)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }.boringBorder
            testButtons
        }.padding(8)
        .alert(item: $deleteRequestModel) { model in
            Alert(
                title: Text("Delete reminder for \(model.deleteTitleName)?"),
                message: nil,
                primaryButton: .default(Text("Keep it")),
                secondaryButton: .destructive(Text("Delete it")) {
                    viewState.removeExistingNotification(model.notificationId)
                }
            )
        }
        .navigationBarItems(
            leading: viewState.fetchActive
                ? AnyView(ActivityIndicator(isAnimating: .constant(true), style: .medium))
                : AnyView(EmptyView())
        )
        .onAppear(
            perform: {
                viewState.requestPermissions()
                viewState.fetchCurrentNotifications()
            }
        )
    }

    private var notificationListView: some View {
        ForEach(viewState.notificationModels, id: \.notificationId) { model in
            VStack(alignment: .leading, spacing: 2) {
                // Preview box
                ZStack(alignment: .trailing) {
                    VStack(alignment: .leading) {
                        Text(model.titleText).font(.headline).fontWeight(.light)
                        Text(model.messageText).font(.subheadline).fontWeight(.thin)
                    }.padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .boringBorder

                    // Remove
                    Image(systemName: "minus.circle.fill")
                        .imageScale(.large)
                        .foregroundColor(Color.init(.displayP3, red: 1, green: 0, blue: 0))
                        .padding(8)
                        .asButton { deleteRequestModel = model }
                }.background(Color(.displayP3, red: 0, green: 0, blue: 0, opacity: 0.1))

                // Schedule info
                Text(model.triggerDateText)
                    .font(.caption)
                    .fontWeight(.thin)
                    .italic()
            }
            Divider()
        }.animation(.default)
    }

    private var testButtons: some View {
        VStack(spacing: 2) {
            if viewState.permissionsGranted {
                Components.fullWidthButton("Schedule default notification test") {
                    viewState.scheduleForDrug()
                }

                Components.fullWidthButton("Clear pending notifications") {
                    viewState.removeCurrentNotifications()
                }
            } else {
                Components.fullWidthButton("Request notification permissions") {
                    viewState.requestPermissions()
                }
            }
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
        content.userInfo = ["drugName": drugName]

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
              let drugName = content.userInfo["drugName"] as? String
            else { return nil }
        
        let timeUntilTrigger = Date().distanceString(triggerDate,
                                                     postfixSelfIsBefore: "from now",
                                                     postfixSelfIsAfter: "ago")
        return NotificationInfoViewModel(
            notificationId: identifier,
            titleText: content.title,
            messageText: content.body,
            triggerDateText: "Scheduled for \(timeUntilTrigger).",
            deleteTitleName: drugName,
            triggerDate: triggerDate
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
        let state = NotificationInfoViewState(makeTestMedicineOperator())
        state.notificationModels = testModels()
        return NotificationInfoView().environmentObject(state)
    }
}
#endif

