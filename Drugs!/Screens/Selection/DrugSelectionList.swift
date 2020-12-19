import Foundation
import SwiftUI
import Combine

struct DrugSelectionContainerModel {
    var currentInfo = AvailabilityInfo()
    var availableDrugs = AvailableDrugList.defaultList
    var inProgressEntry = InProgressEntry()
    var currentSelectedDrug: Drug?
}

final class DrugSelectionContainerInProgressState: ObservableObject {
    private let dataManager: MedicineLogDataManager
    private var cancellables = Set<AnyCancellable>()

    @Published var model = DrugSelectionContainerModel()

    init(_ dataManager: MedicineLogDataManager) {
        self.dataManager = dataManager

        // Start publishing data
        dataManager.availabilityInfoStream
            .receive(on: RunLoop.main)
            .sink(receiveValue: { [weak self] in self?.model.currentInfo = $0 })
            .store(in: &cancellables)

        dataManager.drugListStream
            .receive(on: RunLoop.main)
            .sink(receiveValue: { [weak self] in self?.model.availableDrugs = $0 })
            .store(in: &cancellables)
    }

    func update(entry: InProgressEntry) {
        model.inProgressEntry = entry
    }

    func forDrug(_ drug: Drug, set count: Int?) {
        model.inProgressEntry.entryMap[drug] = count
    }

    func count(for drug: Drug) -> Int {
        model.inProgressEntry.entryMap[drug] ?? 0
    }
}

struct DrugSelectionListView: View {

    @EnvironmentObject var viewState: DrugSelectionContainerInProgressState

    var body: some View {
        let drugs = viewState.model.availableDrugs.drugs
        let half = drugs.count / 2
        let drugsSliceLeft = drugs[0..<half]
        let drugsSliceRight = drugs[half..<drugs.count]
        return ScrollView {
            HStack(alignment: .top, spacing: 0) {
                VStack {
                    ForEach(drugsSliceLeft, id: \.drugName) { drug in
                        DrugEntryViewCell(model: modelFor(drug: drug))
                    }.padding(4.0)
                }
                VStack {
                    ForEach(drugsSliceRight, id: \.drugName) { drug in
                        DrugEntryViewCell(model: modelFor(drug: drug))
                    }.padding(4.0)
                }
            }
            .listStyle(PlainListStyle())
            .listRowBackground(Color.clear)
            .environment(\.defaultMinListRowHeight, 0)
        }
    }

    private func modelFor(drug: Drug) -> DrugEntryViewCellModel {
        DrugEntryViewCellModel(
            drugName: drug.drugName,
            count: viewState.count(for: drug),
            isSelected: viewState.model.currentSelectedDrug == drug,
            canTake: viewState.model.currentInfo.canTake(drug),
            tapAction: { didSelect(drug: drug) }
        )
    }

    private func didSelect(drug: Drug) {
        if viewState.model.currentSelectedDrug == drug {
            viewState.model.currentSelectedDrug = nil
        } else {
            viewState.model.currentSelectedDrug = drug
        }
    }
}

private extension AvailabilityInfo {
    func canTake(_ drug: Drug) -> Bool {
        return self[drug]?.canTake == true
    }
}

#if DEBUG
struct DrugSelectionListView_Preview: PreviewProvider {
    static var previews: some View {
        Group {
            DrugSelectionListView().environmentObject(
                DrugSelectionContainerInProgressState(makeTestMedicineOperator())
            )
        }
    }
}
#endif
