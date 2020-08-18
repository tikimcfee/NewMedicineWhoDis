//
//  MedicineDefinitions.swift
//  Drugs!
//
//  Created by Ivan Lugo on 9/7/19.
//  Copyright © 2019 Ivan Lugo. All rights reserved.
//

import Foundation

public struct AvailableDrugList: EquatableFileStorable {
    var drugs: [Drug]

    init(_ list: [Drug]) {
        self.drugs = list
    }
}

public struct Drug: EquatableFileStorable, Comparable {
    private(set) var drugName: String
    private(set) var ingredients: [Ingredient]
    private(set) var hourlyDoseTime: Double

    public init(_ drugName: String,
                _ ingredients: [Ingredient],
                _ hourlyDoseTime: Double) {
        self.drugName = drugName
        self.ingredients = ingredients
        self.hourlyDoseTime = hourlyDoseTime
    }

    static func blank(_ name: String = "<\(UUID.init().uuidString)>") -> Drug {
        return Drug(name, [], 4)
    }

    public static func < (lhs: Drug, rhs: Drug) -> Bool {
        return lhs.drugName < rhs.drugName
    }

    mutating func update(name: String) {
        self.drugName = name
    }

    mutating func update(ingredients: [Ingredient]) {
        self.ingredients = ingredients
    }

    mutating func update(doseTime: Double) {
        self.hourlyDoseTime = doseTime
    }
}

public struct Ingredient: EquatableFileStorable {

    let ingredientName: String
    public init(_ ingredientName: String) {
        self.ingredientName = ingredientName
    }
}

public struct MedicineEntry: EquatableFileStorable, Identifiable {
    
    let uuid: String
    var date: Date
    var drugsTaken: [Drug:Int]
    public var id: String { return uuid }
    init(
        _ date: Date,
        _ drugsTaken: [Drug:Int],
        _ uuid: String = UUID.init().uuidString
    ) {
        self.date = date
        self.drugsTaken = drugsTaken
        self.uuid = uuid
    }
}
