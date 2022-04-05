//
//  TestComponents.swift
//  Drugs!
//
//  Created by Ivan Lugo on 4/4/22.
//  Copyright © 2022 Ivan Lugo. All rights reserved.
//

import Foundation
import SwiftUI
import RealmSwift

func testButton() -> some View {
    let dataManager = DefaultRealmManager()
    let initializer = RealmStateInitializer()
    let migrator = V1Migrator()
    let realm = try! dataManager.loadEntryLogRealm()
    try! initializer.ensureInitialRealmState(realm)
    
    func clearEverything() {
        dataManager.access { realm in
            try realm.write {
                realm.deleteAll()
            }
        }
    }
    
    func addRandom() {
        let toCreate = 3177
        dataManager.access { realm in
            guard let drugList = RLM_AvailableDrugList.defaultFrom(realm) else {
                log("No drug list to insert samples")
                return
            }
            
            try realm.write {
                for _ in (0...toCreate) {
                    let random = TestData.shared.randomEntry(using: drugList)
                    let test = migrator.fromV1Entry(random)
                    realm.add(test, update: .all)
                }
            }
        }
    }
    
    return VStack {
        Components.fullWidthButton("Clear everything", clearEverything)
        Components.fullWidthButton("Add random everythings", addRandom)
    }.padding(8.0)
}
