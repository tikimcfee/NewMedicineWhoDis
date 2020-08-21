import SwiftUI
import Combine

struct RootAppStartupView: View {
    @State var selectionTag: Int = 0

    var body: some View {
        TabView(selection: $selectionTag) {
            if selectionTag == 0 {
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
                .tag(0)
            }else {
                Text("WUT 0").tabItem {
                    Image(systemName: "calendar.badge.clock")
                    Text("Medicine Log")
                }.tag(0)
            }

            if selectionTag == 1 {
                NotificationInfoView()
                    .tabItem {
                        Image(systemName: "calendar.badge.clock")
                        Text("Reminders")
                    }.tag(1)
            } else {
                Text("WUT 1").tabItem {
                    Image(systemName: "calendar.badge.clock")
                    Text("Reminders")
                }.tag(1)
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
