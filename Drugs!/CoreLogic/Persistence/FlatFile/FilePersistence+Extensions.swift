//
//  FlatFilePersistence+Extensions.swift
//  Drugs!
//
//  Created by Ivan Lugo on 8/23/21.
//  Copyright © 2021 Ivan Lugo. All rights reserved.
//

import Foundation

extension ApplicationData: EquatableFileStorable {
    public enum CodingKeys: CodingKey {
        case listState
        case availableDrugList
    }
    
    public init(from decoder: Decoder) throws {
        let codedKeys = try decoder.container(keyedBy: ApplicationData.CodingKeys.self)
        self.mainEntryList = codedKeys.decodedEntryList
        self.availableDrugList = codedKeys.decodedDrugList
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: ApplicationData.CodingKeys.self)
        try container.encode(mainEntryList, forKey: .listState)
        try container.encode(availableDrugList, forKey: .availableDrugList)
    }
    
    public static func == (lhs: ApplicationData, rhs: ApplicationData) -> Bool {
        return lhs.mainEntryList == rhs.mainEntryList
            && lhs.availableDrugList == rhs.availableDrugList
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(mainEntryList)
        hasher.combine(availableDrugList)
    }
}

// MARK: - Helper for simpler handling of decoding keys
extension KeyedDecodingContainer where Key == ApplicationData.CodingKeys {
    var decodedEntryList: [MedicineEntry] {
        do {
            defer { log { Event("Decoded existing entry list") } }
            return try decode(Array<MedicineEntry>.self, forKey: .listState)
        } catch {
            log{ Event("Failed to decode MedicineList, returning empty") }
            return []
        }
    }
    
    var decodedDrugList: AvailableDrugList {
        do {
            defer { log { Event("Decoded existing drug list") } }
            return try decode(AvailableDrugList.self, forKey: .availableDrugList)
        } catch {
            log{ Event("Failed to decode AvailableDrugList, returning defaultList") }
            return AvailableDrugList.defaultList
        }
    }
}
