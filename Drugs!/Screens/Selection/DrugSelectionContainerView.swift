import SwiftUI
import Combine

struct DrugSelectionContainerView: View {
    @Binding var model: DrugSelectionContainerModel

    var body: some View {
        VStack(alignment: .center, spacing: 4) {
            DrugSelectionListView(model: listModel)
                .boringBorder
            DrugEntryNumberPad(model: numberPadModel)
        }.padding(4.0)
    }

    private var listModel: DrugSelectionListModel {
        func didSelect(_ drug: SelectableDrug) {
            let wasSelected = model.currentSelectedDrug == drug
            let newOrToggledSelection = wasSelected ? nil : drug
            model.currentSelectedDrug = newOrToggledSelection
        }

        let drugModels = model.availableDrugs.drugs.map { drug -> DrugSelectionListRowModel in
            let selectableDrug = SelectableDrug(drugName: drug.drugName, drugId: drug.id)
            let canTake = model.info.canTake(drug)
            let message = model.info.nextDateMessage(drug)
            return DrugSelectionListRowModel(
                drug: selectableDrug,
                count: Int(model.count(for: selectableDrug)),
                canTake: canTake,
                timingMessage: message.message,
                timingIcon: message.icon,
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
        var selection: (String, Double)?
        if let selectedDrug = model.currentSelectedDrug {
            let count = model.count(for: selectedDrug)
            selection = (selectedDrug.drugName, count)
        }
        return DrugEntryNumberPadModel(
            currentSelection: selection,
            didSelectNumber: { selectedNumber in
                guard let selectedDrug = model.currentSelectedDrug else { return }
                let number = Double(selectedNumber)
                let countForSelection = model.count(for: selectedDrug)
                let setOrToggleOff = countForSelection != number ? number : nil
                model.updateCount(setOrToggleOff, for: selectedDrug)
            },
            didIncrementSelection: { incrementAmount in
                guard let selectedDrug = model.currentSelectedDrug else { return }
                let currentCount = model.count(for: selectedDrug)
                model.updateCount(currentCount + incrementAmount, for: selectedDrug)
            },
            didDecrementSelection: { decrementAmount in
                guard let selectedDrug = model.currentSelectedDrug else { return }
                let currentCount = model.count(for: selectedDrug)
                model.updateCount(currentCount - decrementAmount, for: selectedDrug)
            }
        )
    }
}

private extension AvailabilityInfo {
    func nextDateMessage(_ drug: Drug) -> (message: String, icon: String) {
        if let date = self[drug]?.when {
            if date < Date() {
                return ("", "")
            } else {
                let formattedDate = DateFormatting.NoDateShortTime.string(from: date)
                let message = "\(formattedDate)"
                return (message, "timer")
            }
        } else {
            log { Event("Missing drug date in info for: \(drug)") }
            return ("<missing time>", "xmark.circle")
        }
    }
}

class ClockWords {
    static let clocksWithMidways = "🕐🕜🕑🕝🕒🕞🕓🕟🕔🕠🕕🕡🕖🕢🕗🕣🕘🕤🕙🕥🕚🕦🕛🕧"

    static func clockFor(_ date: Date) -> String {
        // Get time components; fixup to clock time
        var hourComponent = Calendar.current.component(.hour, from: date)
        hourComponent = hourComponent == 0 ? 12 // 00:15 is 12:15am; 01:15 is 01:15am
            : hourComponent <= 12 ? hourComponent
            : hourComponent - 12
        let minuteComponent = Calendar.current.component(.minute, from: date)

        let hourIndex = hourComponent - 1
        let indexOffsetWithMinutesAccounted = minuteComponent >= 30
            ? hourIndex * 2 + 1
            : hourIndex * 2

        let clockHourIndex = clocksWithMidways.index(
            clocksWithMidways.startIndex,
            offsetBy: indexOffsetWithMinutesAccounted
        )

        let clock = clocksWithMidways[clockHourIndex]

        return String(clock)
    }
}


#if DEBUG

struct DrugEntryView_Preview: PreviewProvider {
    static var wrapper = WrappedBinding({ () -> DrugSelectionContainerModel in
        var model = DrugSelectionContainerModel()
        model.availableDrugs = AvailableDrugList.defaultList
        model.availableDrugs.drugs.forEach {
            let now = Date()
            let date = now + TimeInterval(Int.random(in: -36000...36000))
            let canTake = date < now
            model.info[$0] = (canTake, date)
        }
        return model
    }())
    static var previews: some View {
        DrugSelectionContainerView(
            model: Self.wrapper.binding
        )
    }
}

#endif

