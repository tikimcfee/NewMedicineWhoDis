//
//  CoreIngredient+CoreDataProperties.swift
//  Drugs!
//
//  Created by Ivan Lugo on 8/21/21.
//  Copyright © 2021 Ivan Lugo. All rights reserved.
//
//

import Foundation
import CoreData


extension CoreIngredient {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CoreIngredient> {
        return NSFetchRequest<CoreIngredient>(entityName: "CoreIngredient")
    }

    @NSManaged public var ingredientName: String?
    @NSManaged public var id: UUID?
    @NSManaged public var targetDrug: CoreDrug?

}

extension CoreIngredient : Identifiable {

}
