import SwiftUI
import Combine

struct InProgressEntry {
	var entryMap: [Drug:Int]
    var date: Date
    init(_ map: [Drug:Int] = [:], _ date: Date = Date()) {
        self.entryMap = map
        self.date = date
    }
    mutating func reset() {
        entryMap = [:]
        date = Date()
    }
}

struct DrugSelectionContainerView: View {
    @EnvironmentObject var viewState: DrugSelectionContainerViewState
    
    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            DrugSelectionListView()
                .padding(EdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 4))
            DrugEntryNumberPad()
                .padding(EdgeInsets(top: 8, leading: 4, bottom: 8, trailing: 8))
        }
        .background(Color(red: 0.8, green: 0.9, blue: 0.9))
        .environmentObject(viewState.selectionState)
    }
}

#if DEBUG

struct DrugEntryView_Preview: PreviewProvider {
    static var previews: some View {
        DrugSelectionContainerView()
            .environmentObject(
                DrugSelectionContainerViewState(
                    dataManager: makeTestMedicineOperator()
                )
            )
    }
}

#endif
