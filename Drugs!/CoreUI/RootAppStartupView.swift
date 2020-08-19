import SwiftUI
import Combine

struct RootAppStartupView: View {
    @EnvironmentObject var dataManager: MedicineLogDataManager

    var body: some View {
        NavigationView {
//            HomeDrugView()
//                .navigationBarTitle(
//                    Text("When did I..."),
//                    displayMode: .inline
//                )
            NotificationInfoView()
                .environmentObject(NotificationInfoViewState(dataManager))
                .navigationBarTitle(
                    Text("Upcoming notifications:"),
                    displayMode: .inline
                )
        }.navigationViewStyle(
            DoubleColumnNavigationViewStyle()
        )
    }
}
