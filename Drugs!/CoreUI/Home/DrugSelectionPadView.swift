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

extension View {
	func slightlyRaised() -> some View {
		return self
			.shadow(color: Color.gray, radius: 0.5, x: 0.0, y: 0.5)
			.padding(4.0)
	}
}

public final class DrugSelectionPadViewState: ObservableObject {
    private let dataManager: MedicineLogDataManager
    private var cancellables = Set<AnyCancellable>()

    @Published var inProgressEntry = InProgressEntry()
    @Published var currentSelectedDrug: Drug?
    @Published var selectionState: DrugSelectionListViewState

    init(dataManager: MedicineLogDataManager) {
        self.dataManager = dataManager
        self.selectionState = DrugSelectionListViewState(dataManager)

        selectionState.$inProgressEntry
            .assign(to: \.inProgressEntry, on: self)
            .store(in: &cancellables)
        selectionState.$currentSelectedDrug
            .assign(to: \.currentSelectedDrug, on: self)
            .store(in: &cancellables)
    }
}

struct DrugSelectionPadView: View {
    @EnvironmentObject var viewState: DrugSelectionPadViewState
    
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
        DrugSelectionPadView()
            .environmentObject(
                DrugSelectionPadViewState(
                    dataManager: makeTestMedicineOperator()
                )
            )
    }
}

#endif
