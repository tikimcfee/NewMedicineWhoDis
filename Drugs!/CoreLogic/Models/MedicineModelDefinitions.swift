//
//  MedicineDefinitions.swift
//  Drugs!
//
//  Created by Ivan Lugo on 9/7/19.
//  Copyright © 2019 Ivan Lugo. All rights reserved.
//

import Foundation

public struct Drug: EquatableFileStorable {

    let drugName: String
    let ingredients: [Ingredient]
    let hourlyDoseTime: Int
    
    static func blank(_ name: String? = nil) -> Drug {
        Drug(
			drugName: name ?? "<\(UUID.init().uuidString)>",
            ingredients: [],
            hourlyDoseTime: 4
        )
    }
}

public struct Ingredient: EquatableFileStorable {

    let ingredientName: String

    init(
        _ ingredientName: String
    ) {
        self.ingredientName = ingredientName
    }
}

public struct MedicineEntry: EquatableFileStorable, Identifiable {
    
    let uuid: String
    var date: Date
    var drugsTaken: [Drug:Int]
    public var id: String { return uuid }
    
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
