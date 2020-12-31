import SwiftUI
import Combine

struct RootAppStartupView: View {

    @EnvironmentObject var container: MasterEnvironmentContainer
    @State private var selectionTag: RootScreenTabTag = .addEntry

    @State private var showingActionSheet = false
    @State private var showingShareSheet = false
    @State private var cleanAppLogsAlert = false

    var body: some View {
        TabView(selection: $selectionTag) {
            addEntryView
            entryListView
            notificationsView
            drugListEditorView
        }
        .sheet(isPresented: $showingShareSheet, content: { activityViewShareSheet })
        .actionSheet(isPresented: $showingActionSheet) { actionSheetHelpOptions }
        .alert(isPresented: $cleanAppLogsAlert) { alertViewClearAppLogsConfirm }
    }


    // MARK: Action Sheet

    private var actionSheetHelpOptions: ActionSheet {
        ActionSheet(title: Text("Help and Settings"),
                    message: Text("What would you like to do?"),
                    buttons: [
                        .default(Text("Share app logs")) { didTapShowShareSheet() },
                        .default(Text("Delete app logs")) { didTapCleanAppLogs() },
                        .cancel()
                    ])
    }

    private func didTapAddEntryViewGearButton() {
        showingActionSheet = true
    }

    // MARK: Share Sheet (ActivityView)

    private func didTapShowShareSheet() {
        showingShareSheet = true
    }

    private var activityViewShareSheet: some View {
        let eventsFile = AppEvents.shared.logFile
        return ActivityView(activityItems: [eventsFile] as [Any],
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
        EntryListView()
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

    var configuration: (String, String) {
        switch self {
        case .addEntry:
            return ("Add Entry", "plus.square.fill")
        case .entryList:
            return ("Entries", "list.dash")
        case .notifications:
            return ("Reminders", "calendar.circle.fill")
        case .drugList:
            return ("Med List", "heart.circle.fill")
        }
    }
}

struct TagModifier: ViewModifier {
    let tag: RootScreenTabTag
    func body(content: Content) -> some View {
        content.tabItem {
            let configuration = tag.configuration
            Image(systemName: configuration.1)
            Text(configuration.0)
        }.tag(tag)
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
        let dataManager = makeTestMedicineOperator()
        let notificationState = NotificationInfoViewState(dataManager)
        let scheduler = NotificationScheduler(notificationState: notificationState)
        let rootState = AddEntryViewState(dataManager, scheduler)
        return RootAppStartupView()
            .environmentObject(dataManager)
            .environmentObject(rootState)
    }
}
#endif
