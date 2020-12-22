import SwiftUI
import Combine

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
        func didSelect(_ drug: SelectableDrug) {
            let wasSelected = model.currentSelectedDrug == drug
            let newOrToggledSelection = wasSelected ? nil : drug
            model.currentSelectedDrug = newOrToggledSelection
        }

        let drugModels = model.availableDrugs.drugs.map { drug -> DrugSelectionListRowModel in
            let selectableDrug = SelectableDrug(drugName: drug.drugName, drugId: drug.id)
            return DrugSelectionListRowModel(
                drug: selectableDrug,
                count: model.count(for: selectableDrug),
                canTake: model.info.canTake(drug),
                isSelected: model.currentSelectedDrug == selectableDrug,
                didSelect: { didSelect(selectableDrug) }
            )
        }

        let listModel = DrugSelectionListModel(
            selectableDrugs: drugModels
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

#if DEBUG

struct DrugEntryView_Preview: PreviewProvider {
    static var wrapper = WrappedBinding({ () -> DrugSelectionContainerModel in
        var model = DrugSelectionContainerModel()
        model.availableDrugs = AvailableDrugList.defaultList
        return model
    }())
    static var previews: some View {
        DrugSelectionContainerView(
            model: Self.wrapper.binding
        )
    }
}

#endif

