//
//  MedicineDefinitions.swift
//  Drugs!
//
//  Created by Ivan Lugo on 9/7/19.
//  Copyright © 2019 Ivan Lugo. All rights reserved.
//

import Foundation

public struct Drug: FileStorable {

    let drugName: String
    let ingredients: [Ingredient]
    let hourlyDoseTime: Int
    
    static func blank(_ name: String? = nil) -> Drug {
        Drug(
			drugName: name ?? "<default drug binding\(UUID.init().uuidString)>",
            ingredients: [],
            hourlyDoseTime: 4
        )
    }
}

public struct Ingredient: FileStorable {

    let ingredientName: String

    init(
        _ ingredientName: String
    ) {
        self.ingredientName = ingredientName
    }
}

public struct MedicineEntry: FileStorable {
    
	let date: Date
    let drugsTaken: [Drug:Int]
    let uuid: String
    
    init(
        date: Date,
        drugsTaken: [Drug:Int],
        _ uuid: String = UUID.init().uuidString
    ) {
        self.date = date
        self.drugsTaken = drugsTaken
        self.uuid = uuid
    }
}
