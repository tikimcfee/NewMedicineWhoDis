//
//  RealmPersistenceStateTransformer.swift
//  Drugs!
//
//  Created by Ivan Lugo on 2/11/22.
//  Copyright © 2022 Ivan Lugo. All rights reserved.
//

import Foundation
import RealmSwift
import Combine


enum RealmPersistenceStateTransformerError: Error {
    case shouldNotBeRunning
}

class RealmPersistenceStateTransformer {
    @Published var appData: ApplicationData = ApplicationData()
    
    private let manager: EntryLogRealmManager
    private var observationTokens = [NotificationToken]()
    private var bag = Set<AnyCancellable>()
    
    init(manager: EntryLogRealmManager) {
        self.manager = manager
        try? setupObservations()
    }
    
    deinit {
        worker.stop()
    }
    
    let worker = BackgroundWorker()
    
    func setupObservations() throws {
        throw RealmPersistenceStateTransformerError.shouldNotBeRunning
    }
}
