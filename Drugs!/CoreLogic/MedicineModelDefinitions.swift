//
//  MedicineDefinitions.swift
//  Drugs!
//
//  Created by Ivan Lugo on 9/7/19.
//  Copyright © 2019 Ivan Lugo. All rights reserved.
//

import Foundation

public struct Drug: Storable {
	
	public struct Ingredient: Storable {
		let ingredientName: String
		init(_ name: String) { self.ingredientName = name }
	}

    let drugName		: String
    let ingredients		: [Ingredient]
    let hourlyDoseTime	: Int
    
    static func blank() -> Drug {
        Drug(
			drugName: "<default drug binding\(UUID.init().uuidString)>",
            ingredients: [],
            hourlyDoseTime: 4
        )
    }
}

public struct MedicineEntry: Storable {
    
	let date			: Date
    let drugsTaken		: [Drug:Int]
    let uuid			: String
    
    init(
        date: Date,
        drugsTaken: [Drug:Int],
        _ randomId: String = UUID.init().uuidString
    ) {
        self.date = date
        self.drugsTaken = drugsTaken
        self.uuid = randomId
    }
}
