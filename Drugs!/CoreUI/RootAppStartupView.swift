import SwiftUI
import Combine

struct RootAppStartupView: View {
    var body: some View {
        NavigationView {
            HomeDrugView()
                .navigationBarTitle(
                    Text("When did I..."),
                    displayMode: .inline
                )
        }.navigationViewStyle(
            DoubleColumnNavigationViewStyle()
        )
    }
}
