//
//  Drugs_RealmTests.swift
//  Drugs!Tests
//
//  Created by Ivan Lugo on 8/21/21.
//  Copyright © 2021 Ivan Lugo. All rights reserved.
//

import XCTest
import RealmSwift

class Drugs_RealmTests: XCTestCase {

    override func setUpWithError() throws {
        
    }

    override func tearDownWithError() throws {
        
    }

    func testExample() throws {
        
    }


}

public class RLM_AvailableDrugList: Object {
    @Persisted var drugs: List<RLM_Drug>
}

public class RLM_Drug: EmbeddedObject {
    @Persisted(primaryKey: true) public var drugName: String
    @Persisted public var ingredients: List<RLM_Ingredient>
    @Persisted public var hourlyDoseTime: Double
}

public class RLM_Ingredient: EmbeddedObject {
    @Persisted var ingredientName: String
}

public typealias RLM_DrugCountMap = RLM_DrugCount
public class RLM_DrugCount: EmbeddedObject {
    @Persisted public var drug: RLM_Drug
    @Persisted public var count: Double
}
public class RLM_MedicineEntry: Object {
    @Persisted(primaryKey: true) public var uuid: String
    @Persisted public var date: Date
    @Persisted public var drugsTaken: List<RLM_DrugCount>
}
