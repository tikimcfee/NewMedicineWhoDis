//
//  RealmMigrations.swift
//  Drugs!
//
//  Created by Ivan Lugo on 8/21/21.
//  Copyright © 2021 Ivan Lugo. All rights reserved.
//

import Foundation
import RealmSwift

public class V1Migrator {
    private var cachedMigratedDrugNames: [String: RLM_Drug] = [:]
    private var cachedMigratedIngredientNames: [String: RLM_Ingredient] = [:]
    
    public func migrateEntriesToRealmObjects(_ oldList: [MedicineEntry]) -> [RLM_MedicineEntry] {
        return oldList.map(fromV1Entry)
    }
    
    public func migrateAvailableToRealmObjects(_ oldList: AvailableDrugList) -> RLM_AvailableDrugList {
        let newList = RLM_AvailableDrugList()
        newList.drugs.append(objectsIn: oldList.drugs.map(fromV1drug))
        return newList
    }
    
    func toV1Entry(_ entry: RLM_MedicineEntry) -> MedicineEntry {
        MedicineEntry(
            entry.date,
            entry.drugsTaken.reduce(into: DrugCountMap()) { acc, entry in
                let converted = toV1Drug(entry.drug!)
                acc[converted] = entry.count
            },
            entry.id
        )
    }
    
    
    func toV1Drug(_ entry: RLM_Drug) -> Drug {
        Drug(
            entry.name,
            entry.ingredients.reduce(into: [Ingredient]()) { acc, entry in
                acc.append(Ingredient(entry.ingredientName))
            },
            entry.hourlyDoseTime
        )
    }
    
    func fromV1Entry(_ entry: MedicineEntry) -> RLM_MedicineEntry {
        let newEntry = RLM_MedicineEntry()
        newEntry.id = entry.id
        newEntry.date = entry.date
        newEntry.drugsTaken = fromV1DrugMap(entry.drugsTaken)
        return newEntry
    }
    
    func fromV1Selection(_ drug: Drug, _ count: Double) -> RLM_DrugSelection {
        let newSelection = RLM_DrugSelection()
        newSelection.count = count
        newSelection.drug = fromV1drug(drug)
        return newSelection
    }
    
    func fromV1drug(_ drug: Drug) -> RLM_Drug {
        if let cached = cachedMigratedDrugNames[drug.id] { return cached }
        let newDrug = RLM_Drug()
        newDrug.name = drug.drugName
        newDrug.hourlyDoseTime = drug.hourlyDoseTime
        newDrug.ingredients.append(
            objectsIn: drug.ingredients.map(fromV1Ingredient)
        )
        cachedMigratedDrugNames[drug.id] = newDrug
        return newDrug
    }
    
    func fromV1DrugMap(_ drugMap: DrugCountMap) -> List<RLM_DrugSelection> {
        drugMap.reduce(into: List()) { list, element in
            list.append(fromV1Selection(element.key, element.value))
        }
    }
    
    func fromV1Ingredient(_ ingredient: Ingredient) -> RLM_Ingredient {
        if let cached = cachedMigratedIngredientNames[ingredient.ingredientName] { return cached }
        
        let newIngredient = RLM_Ingredient()
        newIngredient.ingredientName = ingredient.ingredientName
        
        cachedMigratedIngredientNames[ingredient.ingredientName] = newIngredient
        return newIngredient
    }
}
