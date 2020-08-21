import SwiftUI
import Combine

enum TabTags {
    case home, notifications
}

struct RootAppStartupView: View {

    @State var selectionTag: TabTags = .home

    var body: some View {
        TabView(selection: $selectionTag) {
            homeViewOrEmpty
            infoViewOrEmpty
        }
    }

    private var homeViewOrEmpty: some View {
        Group {
            if selectionTag == .home {
                homeView
            } else {
                VStack {
                    ActivityIndicator(isAnimating: .constant(true), style: .large)
                    Text("Loading home...")
                }
            }
        }.tabItem {
            Image(systemName: "scroll.fill")
            Text("Medicine Log")
        }.tag(TabTags.home)
    }

    private var infoViewOrEmpty: some View {
        Group {
            if selectionTag == .notifications {
                NotificationInfoView()
            } else {
                VStack {
                    ActivityIndicator(isAnimating: .constant(true), style: .large)
                    Text("Loading reminders...")
                }
            }
        }.tabItem {
            Image(systemName: "calendar.badge.clock")
            Text("Reminders")
        }.tag(TabTags.notifications)
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
