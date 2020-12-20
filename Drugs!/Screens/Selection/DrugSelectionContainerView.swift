import SwiftUI
import Combine

typealias SelectableDrugId = String

struct SelectableDrug {
    let drugName: String
    let drugId: SelectableDrugId
}

struct InProgressEntry {
	var entryMap: [Drug: Int]
    var date: Date
    init(
        _ map: [Drug: Int] = [:],
        _ date: Date = Date()
    ) {
        self.entryMap = map
        self.date = date
    }
}

struct DrugSelectionContainerModel {
    var inProgressEntry = InProgressEntry()
    var currentSelectedDrug: Drug?
    var info = AvailabilityInfo()
    var availableDrugs = AvailableDrugList.defaultList

    func count(for drug: Drug) -> Int {
        inProgressEntry.entryMap[drug] ?? 0
    }

    mutating func updateCount(_ count: Int?, for drug: Drug) {
        inProgressEntry.entryMap[drug] = count
    }

    mutating func resetEdits() {
        inProgressEntry = InProgressEntry()
        currentSelectedDrug = nil
    }
}

struct DrugSelectionContainerView: View {
    @Binding var model: DrugSelectionContainerModel

    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            DrugSelectionListView(model: listModel)
                .padding(4)
                .boringBorder
                .padding(4)
            DrugEntryNumberPad(model: numberPadModel)
                .padding(EdgeInsets(top: 8, leading: 4, bottom: 8, trailing: 8))
        }
    }

    private var listModel: DrugSelectionListModel {
        func didSelect(_ drug: Drug) {
            let wasSelected = model.currentSelectedDrug == drug
            let newOrToggledSelection = wasSelected ? nil : drug
            model.currentSelectedDrug = newOrToggledSelection
        }

        let drugModels = model.availableDrugs.drugs.map { drug in
            DrugSelectionListRowModel(
                drug: SelectableDrug(drugName: drug.drugName, drugId: drug.id),
                count: model.count(for: drug),
                canTake: model.info.canTake(drug),
                isSelected: model.currentSelectedDrug == drug,
                didSelect: { didSelect(drug) }
            )
        }

        let listModel = DrugSelectionListModel(
            availableDrugs: drugModels
        )

        return listModel
    }

    private var numberPadModel: DrugEntryNumberPadModel {
        var selection: (String, Int)?
        if let selectedDrug = model.currentSelectedDrug {
            let count = model.count(for: selectedDrug)
            selection = (selectedDrug.drugName, count)
        }
        return DrugEntryNumberPadModel(
            currentSelection: selection,
            didSelectNumber: { number in
                guard let selectedDrug = model.currentSelectedDrug
                else { return }
                let countForSelection = model.count(for: selectedDrug)
                let setOrToggleOff = countForSelection != number ? number : nil
                model.updateCount(setOrToggleOff, for: selectedDrug)
            }
        )
    }
}

private extension AvailabilityInfo {
    func canTake(_ drug: Drug) -> Bool {
        return self[drug]?.canTake == true
    }
}


#if DEBUG

struct DrugEntryView_Preview: PreviewProvider {
    static var wrapper = WrappedBinding(DrugSelectionContainerModel())
    static var previews: some View {
        DrugSelectionContainerView(
            model: Self.wrapper.binding
        )
    }
}

#endif

