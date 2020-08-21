import SwiftUI
import Combine

enum RootScreenTabTag {
    case home, notifications
}

struct RootAppStartupView: View {

    @State var selectionTag: RootScreenTabTag = .home

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
         */
        if #available(iOS 14.0, *) {
            TabView(selection: $selectionTag) {
                homeViewOrEmpty
                infoViewOrEmpty
            }
        } else {
            TabView(selection: $selectionTag) {
                homeView.asHomeTab
                notificationsView.asNotificationsTab
            }
        }
    }

    private var homeViewOrEmpty: some View {
        Group {
            if selectionTag == .home {
                homeView
            } else {
                loadingStack("Loading home...")
            }
        }.asHomeTab
    }

    private var infoViewOrEmpty: some View {
        Group {
            if selectionTag == .notifications {
                notificationsView
            } else {
                loadingStack("Loading reminders...")
            }
        }.asNotificationsTab
    }

    private var homeView: some View {
        NavigationView {
            HomeDrugView().navigationBarTitle(
                Text("When did I..."),
                displayMode: .inline
            )
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    private var notificationsView: some View {
        NotificationInfoView()
    }

    private func loadingStack(_ text: String) -> some View {
        VStack {
            ActivityIndicator(isAnimating: .constant(true), style: .large)
            Text(text)
        }
    }
}

extension View {
    var asHomeTab: some View {
        return modifier(TagModifier(tag: .home))
    }

    var asNotificationsTab: some View {
        return modifier(TagModifier(tag: .notifications))
    }
}

struct TagModifier: ViewModifier {
    let tag: RootScreenTabTag
    func body(content: Content) -> some View {
        switch tag {
        case .home:
            return content.tabItem {
                Image(systemName: "list.bullet")
                Text("Medicine Log")
            }.tag(RootScreenTabTag.home)
        case .notifications:
            return content.tabItem {
                Image(systemName: "calendar.circle.fill")
                Text("Reminders")
            }.tag(RootScreenTabTag.notifications)
        }
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
