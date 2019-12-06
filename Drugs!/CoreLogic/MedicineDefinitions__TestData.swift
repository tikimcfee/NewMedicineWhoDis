//
//  MedicineDefinitions__TestData.swift
//  Drugs!
//
//  Created by Ivan Lugo on 12/5/19.
//  Copyright © 2019 Ivan Lugo. All rights reserved.
//

import Foundation

public let __testData__listOfDrugs: [Drug] = {
	var drugs: [Drug] = [
		Drug(
			drugName: "Tylenol",
			ingredients: [
				Drug.Ingredient("Acetaminophen")
			],
			hourlyDoseTime: 6
		),
		Drug(
			drugName: "Advil",
			ingredients: [
				Drug.Ingredient("Naproxen Sodium")
			],
			hourlyDoseTime: 6
		),
		Drug(
			drugName: "Venlafaxine",
			ingredients: [
				Drug.Ingredient("Venlafaxine")
			],
			hourlyDoseTime: 6
		),
		Drug(
			drugName: "Excedrin",
			ingredients: [
				Drug.Ingredient("Acetaminophen"),
				Drug.Ingredient("Aspirin"),
				Drug.Ingredient("Caffeine")
			],
			hourlyDoseTime: 6
		),
		Drug(
			drugName: "Ibuprofen",
			ingredients: [
				Drug.Ingredient("Ibuprofen")
			],
			hourlyDoseTime: 6
		),
		Drug(
			drugName: "Propranolol",
			ingredients: [
				Drug.Ingredient("Propranolol")
			],
			hourlyDoseTime: 12
		),
		Drug(
			drugName: "Buspirone",
			ingredients: [
				Drug.Ingredient("Buspirone")
			]
			,
			hourlyDoseTime: 24
		),
		Drug(
			drugName: "Trazadone",
			ingredients: [
				Drug.Ingredient("Trazadone")
			],
			hourlyDoseTime: 24
		),
		Drug(
			drugName: "Tums",
			ingredients: [
				Drug.Ingredient("Sodium Bicarbonate")
			],
			hourlyDoseTime: 4
		),
		Drug(
			drugName: "Herb",
			ingredients: [
				Drug.Ingredient("THC"),
				Drug.Ingredient("CBD")
			],
			hourlyDoseTime: 1
		),
		Drug(
			drugName: "Diphenhydramine",
			ingredients: [
				Drug.Ingredient("Diphenhydramine"),
			],
			hourlyDoseTime: 1
		),
		Drug(
			drugName: "Simethicone",
			ingredients: [
				Drug.Ingredient("Simethicone"),
			],
			hourlyDoseTime: 1
		),
	]
	return drugs
}()

public let __testData__anEntry: MedicineEntry = {
	return MedicineEntry(
		date: Calendar.current.date(byAdding: .hour, value: -2, to: Date())!,
		drugsTaken: [
			Drug(
				drugName: "Drugs",
				ingredients: [Drug.Ingredient("Sunshine")],
				hourlyDoseTime: 1
			) : 2,
			Drug(
				drugName: "A great stuff",
				ingredients: [Drug.Ingredient("Milk")],
				hourlyDoseTime: 2
			) : 1,
			Drug(
				drugName: "Allthepots",
				ingredients: [Drug.Ingredient("Sunshine")],
				hourlyDoseTime: 3
			) : 2,
			Drug(
				drugName: "Pepto",
				ingredients: [
					Drug.Ingredient("Guafenisin"),
					Drug.Ingredient("Calcium Carbonate"),
					Drug.Ingredient("Magic"),
					Drug.Ingredient("Science"),
					Drug.Ingredient("Extremely Sciencey Things"),
				],
				hourlyDoseTime: 4
			) : 1,
			Drug(
				drugName: "Sugar",
				ingredients: [Drug.Ingredient("Sunshine")],
				hourlyDoseTime: 24
			) : 3,
		]
	)
}()

public let __testData__coreMedicineOperator: MedicineLogOperator = {
	let medicineStore = MedicineLogStore()
	let loadedState = medicineStore.load()
	
	return MedicineLogOperator(
		medicineStore: medicineStore,
		coreAppState: loadedState
	)
}()
