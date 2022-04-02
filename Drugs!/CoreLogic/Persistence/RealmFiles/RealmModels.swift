//
//  RealmModels.swift
//  Drugs!
//
//  Created by Ivan Lugo on 8/21/21.
//  Copyright © 2021 Ivan Lugo. All rights reserved.
//

import Foundation
import RealmSwift

let CURRENT_SCHEMA_VERSION: UInt64 = 2

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

public class RLM_MedicineEntryGroup: Object, ObjectKeyIdentifiable, RLM_EntryDateRepresentable {
    @Persisted(primaryKey: true) public var id: String = UUID().uuidString
    @Persisted(indexed: true) public var representableDate: Date = Date()
    @Persisted public var entries: List<RLM_MedicineEntry> = List()
}

public class RLM_MedicineEntry: Object, ObjectKeyIdentifiable, RLM_EntryDateRepresentable {
    @Persisted(primaryKey: true) public var id: String = UUID().uuidString
    @Persisted(indexed: true) public var date: Date = Date()
    @Persisted public var drugsTaken: List<RLM_DrugSelection> = List()
    public var representableDate: Date { date }
}

public class RLM_AvailableDrugList: Object, Identifiable {
	@Persisted(primaryKey: true) public var id: String = RLM_AvailableDrugList.defaultId
	@Persisted public var drugs: List<RLM_Drug> = List()
    @Persisted public var didSetDefaultList: Bool = false // Added: V.2
}

public class RLM_AvailabilityInfoContainer: Object, Identifiable {
    @Persisted(primaryKey: true) public var id: String = RLM_AvailabilityInfoContainer.defaultId
    @Persisted public var allInfo: Map<Drug.ID, RLM_AvailabilityStats>?
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

protocol RLM_EntryDateRepresentable {
    var representableDate: Date { get }
    var simpleDateKey: String { get }
}

extension RLM_EntryDateRepresentable {
    var simpleDateKey: String {
        DateFormatting
            .CustomFormatRLM_YearMonthDay
            .string(from: representableDate)
    }
}

extension RLM_MedicineEntry {
    static func observableResults(_ realm: Realm) -> Results<RLM_MedicineEntry> {
        realm.objects(RLM_MedicineEntry.self)
    }
}

extension RLM_AvailabilityInfoContainer {
    static let defaultId = "defaultAvailabilityInfoId"
    
    static func defaultFrom(_ realm: Realm) -> RLM_AvailabilityInfoContainer? {
        realm.object(ofType: RLM_AvailabilityInfoContainer.self, forPrimaryKey: Self.defaultId)
    }
    
    static func observableResults(_ realm: Realm) -> Results<RLM_AvailabilityInfoContainer> {
        realm.objects(RLM_AvailabilityInfoContainer.self)
            .where { $0.id == Self.defaultId }
    }
}

extension RLM_AvailableDrugList {
	static let defaultId = "defaultDrugListKeyId"

	static func defaultFrom(_ realm: Realm) -> RLM_AvailableDrugList? {
		realm.object(ofType: RLM_AvailableDrugList.self, forPrimaryKey: Self.defaultId)
	}
	
	static func observableResults(_ realm: Realm) -> Results<RLM_AvailableDrugList> {
		realm.objects(RLM_AvailableDrugList.self)
            .where { $0.id == Self.defaultId }
	}
}

//protocol DefaultIdentifiable {
//    static var defaultId: String { get }
//}
//
//protocol DefaultQueryable {
//    associatedtype Q
//    static func defaultFrom<Q: Object>(_ realm: Realm) -> Q?
//    static func observableResults<Q: Object>(_ realm: Realm) -> Results<Q>
//}
//
//extension DefaultQueryable {
//    static func defaultFrom<Q: Object>(_ realm: Realm) -> Q? {
//        guard let defaultId = (Q.self as? DefaultIdentifiable.Type)?.defaultId else {
//            return nil
//        }
//        return realm.object(ofType: Q.self, forPrimaryKey: defaultId)
//    }
//
//    static func observableResults<Q: Object>(_ realm: Realm) -> Results<Q> {
//        realm.objects(Q.self)
//    }
//}
//
//extension RLM_MedicineEntry: DefaultQueryable {
//    typealias Q = RLM_MedicineEntry
//}
//
//extension RLM_AvailabilityInfoContainer: DefaultIdentifiable, DefaultQueryable {
//    static let defaultId = "defaultAvailabilityInfoId"
//}
//
//extension RLM_AvailableDrugList: DefaultIdentifiable, DefaultQueryable {
//    static let defaultId = "defaultDrugListKeyId"
//}

extension RLM_Drug {
    var doseTimeInSeconds: Double {
        return Double(hourlyDoseTime) * 60.0 * 60.0
    }
    
    private var onlyIngredientIsSelf: Bool {
        return ingredients.count == 1
        && ingredients.first?.ingredientName == name
    }
    
    var ingredientList: String {
        guard !onlyIngredientIsSelf else { return "" }
        return ingredients.map { $0.ingredientName }.joined(separator: ", ")
    }
}

extension Map: _PersistableInsideOptional where Key == Drug.ID, Value == RLM_AvailabilityStats {
    public static func _rlmGetPropertyOptional(_ obj: ObjectBase, _ key: PropertyKey) -> Self? {
        //        log("OptionalPersistable called for RLM_AvailabilityStats map; what is this even doing and why does it work?")
        return _rlmGetProperty(obj, key)
    }
}
