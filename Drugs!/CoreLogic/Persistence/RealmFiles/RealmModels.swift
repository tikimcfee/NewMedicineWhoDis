//
//  RealmModels.swift
//  Drugs!
//
//  Created by Ivan Lugo on 8/21/21.
//  Copyright © 2021 Ivan Lugo. All rights reserved.
//

import Foundation
import RealmSwift

public class RLM_AppMigrationData: Object {
    private static let AppMigrationDataId = "RLM_AppMigrationData_AppMigrationDataId"
    @Persisted(primaryKey: true) public var id: String = AppMigrationDataId
    @Persisted var flatFileMigrationComplete: Bool = false
    
    public static func from(_ realm: Realm) -> RLM_AppMigrationData? {
        guard let migrationObject = realm.object(
            ofType: RLM_AppMigrationData.self, forPrimaryKey: AppMigrationDataId)
        else {
            return nil
        }
        
        return migrationObject
    }
}

public class RLM_Ingredient: Object {
    @Persisted(primaryKey: true) public var id: String = UUID().uuidString
    @Persisted var ingredientName: String = ""
}

public class RLM_Drug: Object, ObjectKeyIdentifiable {
    @Persisted(primaryKey: true) public var id: String = UUID().uuidString
    @Persisted public var name: String = ""
    @Persisted public var ingredients: List<RLM_Ingredient> = List()
    @Persisted public var hourlyDoseTime: Double = 0.0
}

public class RLM_DrugSelection: Object {
    @Persisted public var drug: RLM_Drug?
    @Persisted public var count: Double = 0.0
}

public class RLM_MedicineEntry: Object, ObjectKeyIdentifiable {
    @Persisted(primaryKey: true) public var id: String = UUID().uuidString
    @Persisted public var date: Date = Date()
    @Persisted public var drugsTaken: List<RLM_DrugSelection> = List()
}

public class RLM_AvailableDrugList: Object, Identifiable {
	@Persisted(primaryKey: true) public var id: String = RLM_AvailableDrugList.defaultDrugListKeyId
	@Persisted public var drugs: List<RLM_Drug> = List()
}

public class RLM_AvailabilityInfoContainer: Object, Identifiable {
    @Persisted(primaryKey: true) public var id: String = RLM_AvailabilityInfoContainer.defaultInfoId
    @Persisted public var allInfo: Map<Drug.ID, RLM_AvailabilityStats>?
}

extension Map: _PersistableInsideOptional where Key == Drug.ID, Value == RLM_AvailabilityStats {
    public static func _rlmGetPropertyOptional(_ obj: ObjectBase, _ key: PropertyKey) -> Self? {
        log("OptionalPersistable called for RLM_AvailabilityStats map; what is this even doing and why does it work?")
        return _rlmGetProperty(obj, key)
    }
}

public class RLM_AvailabilityStats: Object {
    @Persisted public var canTake: Bool = false
    @Persisted public var when: Date = Date()
    convenience init(canTake: Bool, when: Date) {
        self.init()
        self.canTake = canTake
        self.when = when
    }
}

extension RLM_AvailabilityInfoContainer {
    static let defaultInfoId = "defaultAvailabilityInfoId"
    
    static func defaultFrom(_ realm: Realm) -> RLM_AvailabilityInfoContainer? {
        realm.object(ofType: RLM_AvailabilityInfoContainer.self, forPrimaryKey: Self.defaultInfoId)
    }
    
    static func defeaultObservableListFrom(_ realm: Realm) -> Results<RLM_AvailabilityInfoContainer> {
        realm.objects(RLM_AvailabilityInfoContainer.self)
            .filter(NSPredicate(format: "id == %@", Self.defaultInfoId))
    }
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
	
	static func defeaultObservableListFrom(_ realm: Realm) -> Results<RLM_AvailableDrugList> {
		realm.objects(RLM_AvailableDrugList.self)
			.filter(NSPredicate(format: "id == %@", Self.defaultDrugListKeyId))
	}
}

extension RLM_Drug {
    var doseTimeInSeconds: Double {
        return Double(hourlyDoseTime) * 60.0 * 60.0
    }
}
