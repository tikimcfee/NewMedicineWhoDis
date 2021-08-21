//
//  CoreDrug+CoreDataProperties.swift
//  Drugs!
//
//  Created by Ivan Lugo on 8/21/21.
//  Copyright © 2021 Ivan Lugo. All rights reserved.
//
//

import Foundation
import CoreData


extension CoreDrug {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CoreDrug> {
        return NSFetchRequest<CoreDrug>(entityName: "CoreDrug")
    }

    @NSManaged public var drugName: String?
    @NSManaged public var hourlyDoseTime: Double
    @NSManaged public var id: UUID?
    @NSManaged public var ingredients: NSOrderedSet?
    @NSManaged public var sourceList: CoreAvailableDrugList?

}

// MARK: Generated accessors for ingredients
extension CoreDrug {

    @objc(insertObject:inIngredientsAtIndex:)
    @NSManaged public func insertIntoIngredients(_ value: CoreIngredient, at idx: Int)

    @objc(removeObjectFromIngredientsAtIndex:)
    @NSManaged public func removeFromIngredients(at idx: Int)

    @objc(insertIngredients:atIndexes:)
    @NSManaged public func insertIntoIngredients(_ values: [CoreIngredient], at indexes: NSIndexSet)

    @objc(removeIngredientsAtIndexes:)
    @NSManaged public func removeFromIngredients(at indexes: NSIndexSet)

    @objc(replaceObjectInIngredientsAtIndex:withObject:)
    @NSManaged public func replaceIngredients(at idx: Int, with value: CoreIngredient)

    @objc(replaceIngredientsAtIndexes:withIngredients:)
    @NSManaged public func replaceIngredients(at indexes: NSIndexSet, with values: [CoreIngredient])

    @objc(addIngredientsObject:)
    @NSManaged public func addToIngredients(_ value: CoreIngredient)

    @objc(removeIngredientsObject:)
    @NSManaged public func removeFromIngredients(_ value: CoreIngredient)

    @objc(addIngredients:)
    @NSManaged public func addToIngredients(_ values: NSOrderedSet)

    @objc(removeIngredients:)
    @NSManaged public func removeFromIngredients(_ values: NSOrderedSet)

}

extension CoreDrug : Identifiable {

}
