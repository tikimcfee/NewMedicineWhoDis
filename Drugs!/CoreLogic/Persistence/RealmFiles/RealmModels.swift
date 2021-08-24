//
//  RealmModels.swift
//  Drugs!
//
//  Created by Ivan Lugo on 8/21/21.
//  Copyright © 2021 Ivan Lugo. All rights reserved.
//

import Foundation
import RealmSwift

public class RLM_Ingredient: Object {
    @Persisted(primaryKey: true) public var id: String = UUID().uuidString
    @Persisted var ingredientName: String = ""
}

public class RLM_Drug: Object {
    @Persisted(primaryKey: true) public var id: DrugId = UUID().uuidString
    @Persisted public var name: String = ""
    @Persisted public var ingredients: List<RLM_Ingredient> = List()
    @Persisted public var hourlyDoseTime: Double = 0.0
}

public class RLM_DrugSelection: Object {
    @Persisted public var drug: RLM_Drug?
    @Persisted public var count: Double = 0.0
}

public class RLM_MedicineEntry: Object {
    @Persisted(primaryKey: true) public var id: String = UUID().uuidString
    @Persisted public var date: Date = Date()
    @Persisted public var drugsTaken: List<RLM_DrugSelection> = List()
}

public class RLM_AvailableDrugList: Object {
	@Persisted(primaryKey: true) public var id: String = RLM_AvailableDrugList.defaultDrugListKeyId
	@Persisted public var drugs: List<RLM_Drug> = List()
}

extension RLM_AvailableDrugList {
	static let defaultDrugListKeyId = "defaultDrugListKeyId"
	
	static func makeFrom(_ list: AvailableDrugList) -> RLM_AvailableDrugList {
		let migrator = V1Migrator()
		let migratedDrugs = AvailableDrugList.defaultList.drugs.map(migrator.fromV1drug)
		
		let newList = RLM_AvailableDrugList()
		newList.drugs.append(objectsIn: migratedDrugs)
		return newList
	}
	
	static func defaultFrom(_ realm: Realm) -> RLM_AvailableDrugList? {
		realm.object(ofType: RLM_AvailableDrugList.self, forPrimaryKey: Self.defaultDrugListKeyId)
	}
	
	static func defaultListFrom(_ realm: Realm) -> Results<RLM_AvailableDrugList> {
		realm.objects(RLM_AvailableDrugList.self)
			.filter(NSPredicate(format: "id == %@", Self.defaultDrugListKeyId))
	}
}
