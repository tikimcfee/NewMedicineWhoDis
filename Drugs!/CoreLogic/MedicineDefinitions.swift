//
//  MedicineDefinitions.swift
//  Drugs!
//
//  Created by Ivan Lugo on 9/7/19.
//  Copyright © 2019 Ivan Lugo. All rights reserved.
//

import Foundation

public struct Ingredient: Storable {
    let ingredientName: String
}

public struct Drug: Storable {
    let drugName: String
    let ingredients: [Ingredient]
}

public struct MedicineEntry: Storable {
    let date: Date
    let drugsTaken: [Drug]
    let randomId: String
    
    init(
        date: Date,
        drugsTaken: [Drug] = [],
        _ randomId: String = UUID.init().uuidString
    ) {
        self.date = date
        self.drugsTaken = drugsTaken
        self.randomId = randomId
    }
}

// ---------------------------------------------------
// ---------------------------------------------------
// ---------------------------------------------------

public let __testData__listOfDrugs: [Drug] = {
    var drugs: [Drug] = [
        Drug(
            drugName: "Tylenol",
            ingredients: [
                Ingredient(ingredientName: "Acetaminophen")
            ]
        ),
        Drug(
            drugName: "Advil",
            ingredients: [
                Ingredient(ingredientName: "Naproxen Sodium")
            ]
        ),
        Drug(
            drugName: "Venlafaxine",
            ingredients: [
                Ingredient(ingredientName: "Venlafaxine")
            ]
        ),
        Drug(
            drugName: "Excedrin",
            ingredients: [
                Ingredient(ingredientName: "Acetaminophen"),
                Ingredient(ingredientName: "Aspirin"),
                Ingredient(ingredientName: "Caffeine")
            ]
        ),
        Drug(
            drugName: "Ibuprofen",
            ingredients: [
                Ingredient(ingredientName: "Ibuprofen")
            ]
        ),
        Drug(
            drugName: "Propranolol",
            ingredients: [
                Ingredient(ingredientName: "Propranolol")
            ]
        ),
        Drug(
            drugName: "Buspirone",
            ingredients: [
                Ingredient(ingredientName: "Buspirone")
            ]
        ),
        Drug(
            drugName: "Trazadone",
            ingredients: [
                Ingredient(ingredientName: "Trazadone")
            ]
        ),
        Drug(
            drugName: "Tums",
            ingredients: [
                Ingredient(ingredientName: "Sodium Bicarbonate")
            ]
        ),
        Drug(
            drugName: "Funky Green Shit",
            ingredients: [
                Ingredient(ingredientName: "THC"),
                Ingredient(ingredientName: "CBD")
            ]
        ),
    ]
    return drugs
}()

public let __testData__coreMedicineOperator: MedicineLogOperator = {
    let medicineStore = MedicineLogStore()
    let loadedState = medicineStore.load() ?? CoreAppState()
    
    return MedicineLogOperator(
        medicineStore: medicineStore,
        coreAppState: loadedState
    )
}()
