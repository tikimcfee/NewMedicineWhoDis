//
//  RealmEnvironmentModifier.swift
//  Drugs!
//
//  Created by Ivan Lugo on 3/31/22.
//  Copyright © 2022 Ivan Lugo. All rights reserved.
//

import Foundation
import RealmSwift
import Combine
import SwiftUI

struct DefaultRealmModifer: ViewModifier {
    let manager: DefaultRealmManager
    
    @ObservedObject var infoCalculator: AvailabilityInfoCalculator
    
    private var modifier: RealmPersistenceManagerEnvironment? {
        manager.accessImmediate {
            RealmPersistenceManagerEnvironment(
                sourceRealm: $0,
                infoCalculator: infoCalculator
            )
        }
    }
    
    @ViewBuilder
    public func body(content: Content) -> some View {
        if let modifier = modifier {
            content.modifier(modifier)
        } else {
            content
        }
    }
}

struct RealmPersistenceManagerEnvironment: ViewModifier {
    let sourceRealm: Realm
    let infoCalculator: AvailabilityInfoCalculator
    func body(content: Content) -> some View {
        return content
            .environment(\.realm, sourceRealm)
            .environment(\.realmConfiguration, sourceRealm.configuration)
            .environmentObject(infoCalculator)
    }
}
