import SwiftUI
import Combine

struct RootAppStartupView: View {
    var body: some View {
        TabView {
            NavigationView {
                HomeDrugView().navigationBarTitle(
                    Text("When did I..."),
                    displayMode: .inline
                )
            }
            .navigationViewStyle(StackNavigationViewStyle())
            .tabItem {
                Image(systemName: "scroll.fill")
                Text("Medicine Log")
            }

            NotificationInfoView()
                .tabItem {
                    Image(systemName: "calendar.badge.clock")
                    Text("Reminders")
                }
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
