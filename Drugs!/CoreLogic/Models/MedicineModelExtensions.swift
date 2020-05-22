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
            return drugsTaken.keys
                .sorted { $0.drugName <= $1.drugName }
                .map { $0.drugName }
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
    func availabilityInfo() -> AvailabilityInfo {
        let now = Date()

        var drugDates = [Drug: Date]()
        DefaultDrugList.shared.drugs.forEach { drugDates[$0] = now }
        forEach { entry in
            entry.timesDrugsAreNextAvailable.forEach { drug, date in
                guard let existing = drugDates[drug] else {
                    drugDates[drug] = date
                    return
                }
                // If this date is later, it means we have to wait longer
                if date > existing {
                    drugDates[drug] = date
                }
            }
        }

        return drugDates.reduce(into: AvailabilityInfo()) { result, entry in
            result[entry.key] = (entry.value <= now, entry.value)
        }
    }
}
