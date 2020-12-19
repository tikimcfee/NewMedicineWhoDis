import UserNotifications
import Combine
import SwiftUI

public struct NotificationInfoViewModel: Identifiable, Equatable {
    let notificationId: String
    let titleText: String
    let messageText: String
    let triggerDateText: String
    let deleteTitleName: String
    let triggerDate: Date
    public var id: String { return notificationId }
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


            #if DEBUG
            // TODO: Remove test buttons or abstract cleanly
            testButtons
            #endif

        }
        .padding(8)
        .alert(item: $deleteRequestModel) { model in
            Alert(
                title: Text("Delete reminder for \(model.deleteTitleName)?"),
                message: nil,
                primaryButton: .default(Text("Keep it")),
                secondaryButton: .destructive(Text("Delete it")) {
                    self.viewState.removeExistingNotification(model.notificationId)
                }
            )
        }
        .onAppear(perform: { self.viewState.startPublishing() })
        .onDisappear(perform: { self.viewState.stopPublishing() })
    }

    private var notificationListView: some View {
        return ForEach(self.viewState.notificationModels, id: \.notificationId) { model in
            Group {
                VStack(alignment: .leading, spacing: 2) {
                    self.stackForModel(model)
                }
                Divider()
            }
        }.animation(.default)
    }

    private func stackForModel(_ model: NotificationInfoViewModel) -> some View {
        return Group {

            ZStack(alignment: .trailing) {
                // Preview box
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
                    .asButton { self.deleteRequestModel = model }
            }.background(Color(.displayP3, red: 0, green: 0, blue: 0, opacity: 0.1))

            // Schedule info
            Text(model.triggerDateText)
                .font(.caption)
                .fontWeight(.thin)
                .italic()
        }

    }

    private var testButtons: some View {
        VStack(spacing: 2) {
            if self.viewState.permissionsGranted {
                Components.fullWidthButton("Schedule default notification test") {
                    self.viewState.scheduleForDrug()
                }

                Components.fullWidthButton("Clear pending notifications") {
                    self.viewState.removeCurrentNotifications()
                }
            } else {
                Components.fullWidthButton("Request notification permissions") {
                    self.viewState.requestPermissions()
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
        content.body = "Scheduled reminder for \(DateFormatting.DefaultDateShortTime.string(from: sourceDate))."
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
    var logInfo: String {
        return String(describing: trigger)
            .appending("\n--")
            .appending(String(describing: (trigger as? UNCalendarNotificationTrigger)?.nextTriggerDate()))
            .appending("\n--")
            .appending(String(describing: content.userInfo["drugName"] as? String))
    }

    var asInfoViewModel: NotificationInfoViewModel? {
        guard let trigger = trigger as? UNCalendarNotificationTrigger,
              let triggerDate = trigger.nextTriggerDate(),
              let drugName = content.userInfo["drugName"] as? String
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

