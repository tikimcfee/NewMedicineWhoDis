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
			return drugsTaken.keys.map { $0.drugName }.joined(separator: ", ")
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
