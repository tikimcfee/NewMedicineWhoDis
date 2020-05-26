//
//  MedicineModelExtensions.swift
//  Drugs!
//
//  Created by Ivan Lugo on 12/5/19.
//  Copyright © 2019 Ivan Lugo. All rights reserved.
//

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
//                .map { "\($0.key.drugName) (\($0.value))" }
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

public typealias AvailabilityInfo = [Drug: (canTake: Bool, when: Date)]

extension Array where Element == MedicineEntry {
    func availabilityInfo(_ startDate: Date = Date()) -> AvailabilityInfo {
        var drugDates = [Drug: Date]()
        DefaultDrugList.shared.drugs.forEach { drugDates[$0] = startDate }
        forEach { entry in
            entry.timesDrugsAreNextAvailable.forEach { drug, dateDrugIsAvailable in
                guard let lastKnownTakenDate = drugDates[drug] else {
                    drugDates[drug] = dateDrugIsAvailable
                    return
                }
                // If this date is later, it means we have to wait longer
                if dateDrugIsAvailable > lastKnownTakenDate {
                    drugDates[drug] = dateDrugIsAvailable
                }
            }
        }

        return drugDates.reduce(into: AvailabilityInfo()) { result, entry in
            result[entry.key] = (entry.value <= startDate, entry.value)
        }
    }
}
