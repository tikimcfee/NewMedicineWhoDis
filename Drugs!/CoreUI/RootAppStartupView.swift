import SwiftUI
import Combine

struct RootAppStartupView: View {
    @EnvironmentObject var dataManager: MedicineLogDataManager

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
                .environmentObject(NotificationInfoViewState(dataManager))
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
        let rootState = RootScreenState(dataManager)
        return RootAppStartupView()
            .environmentObject(dataManager)
            .environmentObject(rootState)
    }
}
#endif
