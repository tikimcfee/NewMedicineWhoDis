import Foundation

extension Drug {
    private var onlyIngredientIsSelf: Bool {
        return ingredients.count == 1
            && ingredients.first?.ingredientName == drugName
    }

	var ingredientList: String {
        guard !onlyIngredientIsSelf else { return "" }
		return ingredients.map { $0.ingredientName }.joined(separator: ", ")
	}
	
	var doseTimeInSeconds: Double {
		return Double(hourlyDoseTime) * 60.0 * 60.0
	}
}

extension Drug {
    var asSelectableDrug: SelectableDrug {
        SelectableDrug(
            drugName: drugName,
            drugId: id
        )
    }
}

extension MedicineEntry {
	var drugList: String {
		if drugsTaken.count == 0 {
			return "(Nothing taken)"
		} else {
            return drugsTaken
                .sorted { $0.key.drugName < $1.key.drugName }
                .map { $0.key.drugName }
                .joined(separator: ", ")
		}
	}
	
	var timesDrugsAreNextAvailable: [Drug: Date] {
		var result: [Drug: Date] = [:]
		drugsTaken.forEach { pair in
			result[pair.key] = self.date.advanced(by: pair.key.doseTimeInSeconds)
		}
		return result
	}

    var editableEntry: InProgressEntry {
        return InProgressEntry(
            drugsTaken.reduce(into: [SelectableDrug: Int]()) { result, pair in
                result[pair.key.asSelectableDrug] = pair.value
            },
            date
        )
    }
}

extension AvailableDrugList {
    public static let defaultList = AvailableDrugList(defaultDrugs)
    private static let defaultDrugs: [Drug] = [
        Drug("Gabapentin",  [Ingredient("Gabapentin")],     12),
        Drug("Tylenol",     [Ingredient("Acetaminophen")],  5),
        Drug("Venlafaxine", [Ingredient("Venlafaxine")],    24),
        Drug("Dramamine",   [Ingredient("Dimenhydrinate"),], 24),
        Drug("Excedrin",    [Ingredient("Acetaminophen"),
                             Ingredient("Aspirin"),
                             Ingredient("Caffeine")],       5),
        Drug("Ibuprofen",   [Ingredient("Ibuprofen")],      8),
        Drug("Omeprazole",  [Ingredient("Omeprazole")],     12),
        Drug("Melatonin",   [Ingredient("Melatonin")],      24),
        Drug("Tums",        [Ingredient("Sodium Bicarbonate")], 4),
        Drug("Vitamins",    [Ingredient("Vitamins")],       0),
    ]
}

public typealias AvailabilityInfo = [Drug: (canTake: Bool, when: Date)]

extension AvailabilityInfo {
    func canTake(_ drug: Drug) -> Bool {
        return self[drug]?.canTake == true
    }
}

class AvailabilityInfoCalculator {
    static func computeInfo(startDate: Date = Date(),
                            availableDrugs: AvailableDrugList,
                            entries: [MedicineEntry]) -> AvailabilityInfo {
        var drugDates = [Drug: Date]()
        availableDrugs.drugs.forEach { drugDates[$0] = startDate }

        // Use the newest drug info if there is one.
        // This is important so old entries don't step on new drugs.
        for entry in entries {
            for (drug, _) in entry.drugsTaken {
                let newestDrug = availableDrugs.drugFor(id: drug.id) ?? drug
                let nextDoseTime = entry.date.advanced(by: newestDrug.doseTimeInSeconds)

                guard let lastKnownTakenDate = drugDates[newestDrug] else {
                    drugDates[newestDrug] = nextDoseTime
                    continue
                }

                if nextDoseTime > lastKnownTakenDate {
                    drugDates[newestDrug] = nextDoseTime
                }
            }
        }

        return drugDates.reduce(into: AvailabilityInfo()) { result, entry in
            result[entry.key] = (entry.value <= startDate, entry.value)
        }
    }
}

private extension AvailableDrugList {
    func drugFor(id: DrugId) -> Drug? {
        drugs.first(where: { $0.id == id })
    }
}
