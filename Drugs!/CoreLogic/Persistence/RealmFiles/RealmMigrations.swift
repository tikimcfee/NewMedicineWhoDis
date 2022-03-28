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
    
    public func isMigrationNeeded(into realm: Realm) -> Bool {
        guard let migrationData = RLM_AppMigrationData.from(realm) else {
            log { Event("No migration data found; assuming no migration has been run.", .info) }
            return true
        }
        
        let migrationsComplete = migrationData.flatFileMigrationComplete
        let shouldMigrade = !migrationsComplete
        
        log { Event("""
Migration state query:
[migrationComplete: \(migrationsComplete)]
-> shouldMigrate = \(shouldMigrade)
""", .info) }
        
        return shouldMigrade
    }
    
    public func migrate(manager: FilePersistenceManager, into realm: Realm) throws {
        assert(!realm.isInWriteTransaction, "Migration should never start while in write transation")
        log { Event("Starting initial migration. Here we go.", .info) }
        
        guard isMigrationNeeded(into: realm) else { throw RealmPersistenceError.invalidMigrationCall }
        
        let sourceMigrationData = try manager.loadFromFileStoreImmediately()
        
        let migratedEntries = migrateEntriesToRealmObjects(sourceMigrationData.mainEntryList)
		let migratedDrugList = migrateAvailableToRealmObjects(sourceMigrationData.availableDrugList)
		try realm.write {
			realm.add(migratedEntries)
			realm.add(migratedDrugList)
            
            let migrationData = RLM_AppMigrationData.from(realm) ?? {
                log { Event("No migration data found; returning new", .info) }
                return RLM_AppMigrationData()
            }()
            migrationData.flatFileMigrationComplete = true
            realm.add(migrationData, update: .modified)
		}
	}
    
    public func migrateFromStatsContainer(
        sourceList: RLM_AvailableDrugList,
        into stats: RLM_AvailabilityInfoContainer
    ) -> AvailabilityInfo {
        return stats.allInfo?.reduce(into: AvailabilityInfo()) { results, stats in
            guard let drug = sourceList.drugs.first(where: { $0.id == stats.key }) else {
                log("No drug found in root list for: \(stats.key)")
                return
            }
            results[toV1Drug(drug)] = (stats.value.canTake, stats.value.when)
        } ?? AvailabilityInfo()
    }
    
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
            entry.hourlyDoseTime,
            id: entry.id
        )
    }
	
	func toV1DrugList(_ list: RLM_AvailableDrugList) -> AvailableDrugList {
		return AvailableDrugList(list.drugs.map(toV1Drug))
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
        newDrug.id = drug.id
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
