//
//  ApplicationState.swift
//  Drugs!
//
//  Created by Ivan Lugo on 9/8/19.
//  Copyright © 2019 Ivan Lugo. All rights reserved.
//

import Foundation
import Combine

public class AppState: FileStorable, ObservableObject {

    public enum CodingKeys: CodingKey {
        case listState
    }
    
    @Published private(set) var mainEntryList: [MedicineEntry] = []

    public init() { }

    public required init(from decoder: Decoder) throws {
        let codedKeys = try decoder.container(keyedBy: AppState.CodingKeys.self)
        self.mainEntryList = try codedKeys.decode(Array<MedicineEntry>.self, forKey: .listState)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: AppState.CodingKeys.self)
        try container.encode(mainEntryList, forKey: .listState)
    }
    
    public static func == (lhs: AppState, rhs: AppState) -> Bool {
        return lhs.mainEntryList == rhs.mainEntryList
    }
    
    public func hash(into hasher: inout Hasher) {
		hasher.combine(mainEntryList)
    }
}

extension AppState {
    func addEntry(medicineEntry: MedicineEntry) {
        mainEntryList.insert(medicineEntry, at: 0)
    }
    
    func removeEntry(id: String) {
        mainEntryList.removeAll { $0.uuid == id }
    }
}
