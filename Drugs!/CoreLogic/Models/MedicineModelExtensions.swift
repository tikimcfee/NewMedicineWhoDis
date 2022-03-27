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
