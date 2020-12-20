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
        /** As of:
         * XCode 12.0 beta 4 (12A8179i)
         * iOS 14.0 Beta 5 (18A5351d), and iOS 14.0 'default simulator'
         *
         * TabView automatically recreates and keeps alive tabs that aren't selected.
         * This means any subscriptions and lifecyle events are kept around. This is
         * best tested with a .viewAppeared(). So, there's a great little hack:
         * Use selection state to simply not show the view, forcing SwiftUI to recreate
         * the hierarchy entirely with a new view, seemingly defeating whatever optimization or
         * retention is occuring. How long this will work is completely unknown.
         *
         * Note: This breaks quite hard in MacOS
         */
        return makeView()
    }

    private func makeView() -> some View {
        AnyView(
            TabView(selection: $selectionTag) {
                addEntryView
                entryListView
                notificationsView
                drugListEditorView
            }
        )
    }
}

// View helpers
extension RootAppStartupView {
    private var addEntryView: some View {
        AddNewEntryView()
            .asAddEntryTab
    }

    private var entryListView: some View {
        MedicineLogView()
            .asEntryListTab
    }

    private var notificationsView: some View {
        NotificationInfoView()
            .asNotificationsTab
    }

    private var drugListEditorView: some View {
        DrugListEditorView()
            .asMedicinesTab
            .environmentObject(container.makeNewDrugEditorState())
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
        let rootState = RootScreenState(dataManager, scheduler)
        return RootAppStartupView()
            .environmentObject(dataManager)
            .environmentObject(rootState)
    }
}
#endif
