import SwiftUI
import Combine

enum RootScreenTabTag {
    case addEntry
    case entryList
    case notifications
    case drugList
}

struct TagModifier: ViewModifier {
    let tag: RootScreenTabTag
    func body(content: Content) -> some View {
        switch tag {
        case .addEntry:
            return content.tabItem {
                Image(systemName: "plus.square.fill")
                Text("Add Entry")
            }.tag(RootScreenTabTag.addEntry)
        case .entryList:
            return content.tabItem {
                Image(systemName: "list.dash")
                Text("Entries")
            }.tag(RootScreenTabTag.entryList)
        case .notifications:
            return content.tabItem {
                Image(systemName: "calendar.circle.fill")
                Text("Reminders")
            }.tag(RootScreenTabTag.notifications)
        case .drugList:
            return content.tabItem {
                Image(systemName: "heart.circle.fill")
                Text("Medicines")
            }.tag(RootScreenTabTag.drugList)
        }
    }
}


struct RootAppStartupView: View {

    @EnvironmentObject var container: MasterEnvironmentContainer
    @State var selectionTag: RootScreenTabTag = .addEntry

    var body: some View {
        TabView(selection: $selectionTag) {
            addEntryView
            entryListView
            notificationsView
            drugListEditorView
        }
    }
}

// View helpers
extension RootAppStartupView {
    private var addEntryView: some View {
        AddNewEntryView()
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
