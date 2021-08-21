//
//  CoreMedicineEntrySelection+CoreDataProperties.swift
//  Drugs!
//
//  Created by Ivan Lugo on 8/21/21.
//  Copyright © 2021 Ivan Lugo. All rights reserved.
//
//

import Foundation
import CoreData


extension CoreMedicineEntrySelection {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CoreMedicineEntrySelection> {
        return NSFetchRequest<CoreMedicineEntrySelection>(entityName: "CoreMedicineEntrySelection")
    }

    @NSManaged public var count: Double
    @NSManaged public var drugId: String?
    @NSManaged public var sourceEntry: CoreMedicineEntry?

}

extension CoreMedicineEntrySelection : Identifiable {

}
