//
//  RealmModelExtensions.swift
//  Drugs!
//
//  Created by Ivan Lugo on 4/3/22.
//  Copyright © 2022 Ivan Lugo. All rights reserved.
//

import Foundation
import RealmSwift

extension RLM_MedicineEntry {
    static func observableResults(_ realm: Realm) -> Results<RLM_MedicineEntry> {
        realm.objects(RLM_MedicineEntry.self)
    }
}

extension RLM_MedicineEntryGroup {
    static func observableResults(_ realm: Realm) -> Results<RLM_MedicineEntryGroup> {
        realm.objects(RLM_MedicineEntryGroup.self)
    }
}

extension RLM_AvailabilityInfoContainer {
    public static let defaultId = "defaultAvailabilityInfoId"
    static func defaultFrom(_ realm: Realm) -> RLM_AvailabilityInfoContainer? {
        realm.object(ofType: RLM_AvailabilityInfoContainer.self, forPrimaryKey: defaultId)
    }
    
    static func observableResults(_ realm: Realm) -> Results<RLM_AvailabilityInfoContainer> {
        realm.objects(RLM_AvailabilityInfoContainer.self)
            .where { $0.id == defaultId }
    }
}

extension Map: _PersistableInsideOptional where Key == Drug.ID, Value == RLM_AvailabilityStats {
    public static func _rlmGetPropertyOptional(_ obj: ObjectBase, _ key: PropertyKey) -> Self? {
        //        log("OptionalPersistable called for RLM_AvailabilityStats map; what is this even doing and why does it work?")
        return _rlmGetProperty(obj, key)
    }
}

extension RLM_AvailableDrugList {
    public static let defaultId = "defaultAvailabilityInfoId"
    static func defaultFrom(_ realm: Realm) -> RLM_AvailableDrugList? {
        realm.object(ofType: RLM_AvailableDrugList.self, forPrimaryKey: Self.defaultId)
    }
    
    static func observableResults(_ realm: Realm) -> Results<RLM_AvailableDrugList> {
        realm.objects(RLM_AvailableDrugList.self)
            .where { $0.id == Self.defaultId }
    }
}

extension RLM_AppMigrationData {
    static let defaultQueryId = "RLM_AppMigrationData_AppMigrationDataId"
    public static func from(_ realm: Realm) -> RLM_AppMigrationData? {
        realm.object(ofType: RLM_AppMigrationData.self, forPrimaryKey: defaultQueryId)
    }
}

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
    
    func simpleDateKey(_ date: Date) -> String {
        DateFormatting
            .CustomFormatRLM_YearMonthDay
            .string(from: date)
    }
}

extension Date: RLM_EntryDateRepresentable {
    var representableDate: Date { self }
}
