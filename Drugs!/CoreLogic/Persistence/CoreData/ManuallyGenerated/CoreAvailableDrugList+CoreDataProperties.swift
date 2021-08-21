//
//  CoreAvailableDrugList+CoreDataProperties.swift
//  Drugs!
//
//  Created by Ivan Lugo on 8/21/21.
//  Copyright © 2021 Ivan Lugo. All rights reserved.
//
//

import Foundation
import CoreData


extension CoreAvailableDrugList {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CoreAvailableDrugList> {
        return NSFetchRequest<CoreAvailableDrugList>(entityName: "CoreAvailableDrugList")
    }

    @NSManaged public var drugs: NSOrderedSet?

}

// MARK: Generated accessors for drugs
extension CoreAvailableDrugList {

    @objc(insertObject:inDrugsAtIndex:)
    @NSManaged public func insertIntoDrugs(_ value: CoreDrug, at idx: Int)

    @objc(removeObjectFromDrugsAtIndex:)
    @NSManaged public func removeFromDrugs(at idx: Int)

    @objc(insertDrugs:atIndexes:)
    @NSManaged public func insertIntoDrugs(_ values: [CoreDrug], at indexes: NSIndexSet)

    @objc(removeDrugsAtIndexes:)
    @NSManaged public func removeFromDrugs(at indexes: NSIndexSet)

    @objc(replaceObjectInDrugsAtIndex:withObject:)
    @NSManaged public func replaceDrugs(at idx: Int, with value: CoreDrug)

    @objc(replaceDrugsAtIndexes:withDrugs:)
    @NSManaged public func replaceDrugs(at indexes: NSIndexSet, with values: [CoreDrug])

    @objc(addDrugsObject:)
    @NSManaged public func addToDrugs(_ value: CoreDrug)

    @objc(removeDrugsObject:)
    @NSManaged public func removeFromDrugs(_ value: CoreDrug)

    @objc(addDrugs:)
    @NSManaged public func addToDrugs(_ values: NSOrderedSet)

    @objc(removeDrugs:)
    @NSManaged public func removeFromDrugs(_ values: NSOrderedSet)

}

extension CoreAvailableDrugList : Identifiable {

}
