//
//  MedicineDefinitions.swift
//  Drugs!
//
//  Created by Ivan Lugo on 9/7/19.
//  Copyright © 2019 Ivan Lugo. All rights reserved.
//

import Foundation


public struct Drug: Storable {
    let name: String
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
    var drugs: [Drug] = []
    drugs.append(Drug(name: "Tylenol"))
    drugs.append(Drug(name: "Advil"))
    drugs.append(Drug(name: "Excedrin"))
    drugs.append(Drug(name: "Weeeeeds!"))
    drugs.append(Drug(name: "Ibuprofen"))
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
