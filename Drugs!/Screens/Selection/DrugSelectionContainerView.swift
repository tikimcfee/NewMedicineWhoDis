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
        .background(Color(red: 0.8, green: 0.9, blue: 0.9))
    }

    private var listModel: DrugSelectionListModel {
        let tuples = model.availableDrugs.drugs.map { drug in
            (drug, model.count(for: drug), model.info.canTake(drug))
        }
        let listModel = DrugSelectionListModel(
            availableDrugs: tuples,
            didSelectDrug: { drug in
                let wasSelected = model.currentSelectedDrug == drug
                let toSet = wasSelected ? nil : drug
                model.currentSelectedDrug = toSet
            },
            selectedDrug: model.currentSelectedDrug
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

