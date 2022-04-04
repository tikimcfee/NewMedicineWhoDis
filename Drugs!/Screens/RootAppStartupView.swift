import SwiftUI
import Combine

enum RootShare {
    case none
    case file(URL)
}

extension URL: Identifiable {
    public var id: String { absoluteString }
}

struct RootAppStartupView: View {

    @EnvironmentObject var container: MasterEnvironmentContainer
    @State private var selectionTag: RootScreenTabTag = .addEntry

    @State private var showingActionSheet = false
    @State private var showingShareSheetURL: URL?
    @State private var cleanAppLogsAlert = false

    var body: some View {
        TabView(selection: $selectionTag) {
            addEntryView
            entryListView
            notificationsView
            drugListEditorView
        }
        .sheet(item: $showingShareSheetURL) { activityViewShareSheet($0) }
        .actionSheet(isPresented: $showingActionSheet) { actionSheetHelpOptions }
        .alert(isPresented: $cleanAppLogsAlert) { alertViewClearAppLogsConfirm }
    }


    // MARK: Action Sheet

    private var actionSheetHelpOptions: ActionSheet {
        ActionSheet(title: Text("Help and Settings"),
                    message: Text("What would you like to do?"),
                    buttons: [
                        .default(Text("Send app logs")) { self.showingShareSheetURL = AppEvents.shared.logFile },
                        .default(Text("Backup data")) { self.showingShareSheetURL = AppFiles.entryLogRealm },
                        .default(Text("Delete app logs")) { didTapCleanAppLogs() },
                        .cancel()
                    ])
    }

    private func didTapAddEntryViewGearButton() {
        showingActionSheet = true
    }

    // MARK: Share Sheet (ActivityView)

    private func activityViewShareSheet(_ url: URL) -> some View {
//        let eventsFile = AppEvents.shared.logFile
        return ActivityView(activityItems: [url] as [Any],
                            applicationActivities: nil)
    }

    // MARK: App log clearing

    private var alertViewClearAppLogsConfirm: Alert {
        Alert(title: Text("Clear out logs and start fresh?"),
              message: nil,
              primaryButton: Alert.Button.destructive(Text("Yep, start fresh")) {
                didConfirmCleanAppLogs()
              },
              secondaryButton: .cancel()
        )
    }

    private func didTapCleanAppLogs() {
        cleanAppLogsAlert = true
    }

    private func didConfirmCleanAppLogs() {
        AppEvents.shared.eraseLogs()
    }
}

// View helpers
extension RootAppStartupView {
    private var addEntryView: some View {
        NavigationView {
            AddNewEntryView()
                .navigationBarTitle("", displayMode: .inline)
                .navigationBarItems(trailing: {
                    Button(action: didTapAddEntryViewGearButton) {
                        HStack {
                            Image(systemName: "gear")
                                .foregroundColor(.gray)
                            Text("Help")
                                .foregroundColor(.gray)
                        }
                    }
                }())
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .asAddEntryTab
    }

    private var entryListView: some View {
        NavigationView {
            EntryListView()
                .navigationBarTitle("", displayMode: .inline)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .asEntryListTab
    }

    private var notificationsView: some View {
        NotificationInfoView()
            .asNotificationsTab
    }

    private var drugListEditorView: some View {
        NavigationView {
            DrugListEditorView()
                .environmentObject(container.makeNewDrugEditorState())
                .navigationBarTitle("", displayMode: .inline)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .asMedicinesTab
    }
}

enum RootScreenTabTag {
    case addEntry
    case entryList
    case notifications
    case drugList

    var configuration: (String, String, AppTabAccessID) {
        switch self {
        case .addEntry:
            return ("Add Entry", "plus.square.fill", .addEntry)
        case .entryList:
            return ("Entries", "list.dash", .entryList)
        case .notifications:
            return ("Reminders", "calendar.circle.fill", .notifications)
        case .drugList:
            return ("Med List", "heart.circle.fill", .drugList)
        }
    }
}

struct TagModifier: ViewModifier {
    let tag: RootScreenTabTag
    func body(content: Content) -> some View {
        let configuration = tag.configuration
        return content.tabItem {
            Image(systemName: configuration.1)
            Text(configuration.0)
        }
        // warning: don't do this; it sets the id on the first visible element
//        .accessibility(identifier: configuration.2.rawValue)
        .tag(tag)
    }
}

extension View {
    var asAddEntryTab: some View {
        return modifier(TagModifier(tag: .addEntry))
    }

    var asEntryListTab: some View {
        return modifier(TagModifier(tag: .entryList))
    }

    var asNotificationsTab: some View {
        return modifier(TagModifier(tag: .notifications))
    }

    var asMedicinesTab: some View {
        return modifier(TagModifier(tag: .drugList))
    }
}

#if DEBUG
struct RootAppStartupView_Previews: PreviewProvider {
    static var previews: some View {
        let dataManager = DefaultRealmManager()
        let notificationState = NotificationInfoViewState()
        let scheduler = NotificationScheduler(notificationState: notificationState)
        let infoCalculator = AvailabilityInfoCalculator(manager: dataManager)
        let rootState = AddEntryViewState(
            dataManager,
            scheduler
        )
        return RootAppStartupView()
            .modifier(dataManager.makeModifier())
            .environmentObject(rootState)
            .environmentObject(infoCalculator)
    }
}
#endif
