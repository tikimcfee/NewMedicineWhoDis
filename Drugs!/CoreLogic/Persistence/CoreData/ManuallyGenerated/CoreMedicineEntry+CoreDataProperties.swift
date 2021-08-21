//
//  CoreMedicineEntry+CoreDataProperties.swift
//  Drugs!
//
//  Created by Ivan Lugo on 8/21/21.
//  Copyright © 2021 Ivan Lugo. All rights reserved.
//
//

import Foundation
import CoreData


extension CoreMedicineEntry {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CoreMedicineEntry> {
        return NSFetchRequest<CoreMedicineEntry>(entityName: "CoreMedicineEntry")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var date: Date?
    @NSManaged public var selections: NSOrderedSet?

}

// MARK: Generated accessors for selections
extension CoreMedicineEntry {

    @objc(insertObject:inSelectionsAtIndex:)
    @NSManaged public func insertIntoSelections(_ value: CoreMedicineEntrySelection, at idx: Int)

    @objc(removeObjectFromSelectionsAtIndex:)
    @NSManaged public func removeFromSelections(at idx: Int)

    @objc(insertSelections:atIndexes:)
    @NSManaged public func insertIntoSelections(_ values: [CoreMedicineEntrySelection], at indexes: NSIndexSet)

    @objc(removeSelectionsAtIndexes:)
    @NSManaged public func removeFromSelections(at indexes: NSIndexSet)

    @objc(replaceObjectInSelectionsAtIndex:withObject:)
    @NSManaged public func replaceSelections(at idx: Int, with value: CoreMedicineEntrySelection)

    @objc(replaceSelectionsAtIndexes:withSelections:)
    @NSManaged public func replaceSelections(at indexes: NSIndexSet, with values: [CoreMedicineEntrySelection])

    @objc(addSelectionsObject:)
    @NSManaged public func addToSelections(_ value: CoreMedicineEntrySelection)

    @objc(removeSelectionsObject:)
    @NSManaged public func removeFromSelections(_ value: CoreMedicineEntrySelection)

    @objc(addSelections:)
    @NSManaged public func addToSelections(_ values: NSOrderedSet)

    @objc(removeSelections:)
    @NSManaged public func removeFromSelections(_ values: NSOrderedSet)

}

extension CoreMedicineEntry : Identifiable {

}
