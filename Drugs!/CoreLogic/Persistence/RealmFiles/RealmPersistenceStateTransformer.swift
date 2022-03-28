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
        worker.start()
        worker.run { [weak self] runLoop in
            guard let self = self else { return }
            
            func completion(_ state: Subscribers.Completion<Error>) {
                switch state {
                case .finished:
                    log("Published reported finished state")
                case let .failure(error):
                    log(error)
                }
            }
            
            self.manager.access { realm in
                self.bag = [
                    realm.objects(RLM_MedicineEntry.self)
                        .sorted(by: \.date, ascending: false)
                        .collectionPublisher
                        .receive(on: runLoop)
                        .compactMap { results in
                            let migrator = V1Migrator()
                            let mapped = results.map { migrator.toV1Entry($0) }
                            return Array(mapped)
                        }
                        .receive(on: RunLoop.main)
                        .sink(receiveCompletion: completion,
                            receiveValue: { results in
                                self.appData.mainEntryList = results
                            }
                        ),
                    RLM_AvailableDrugList.defeaultObservableListFrom(realm)
                        .collectionPublisher
                        .receive(on: runLoop)
                        .compactMap { results -> AvailableDrugList? in
                            guard let first = results.first else { return nil }
                            log("Drug list on \(Thread.current)")
                            return V1Migrator().toV1DrugList(first)
                        }
                        .receive(on: RunLoop.main)
                        .sink(
                            receiveCompletion: completion,
                            receiveValue: { results in
                                log("Drug list send on \(Thread.current)")
                                self.appData.availableDrugList = results
                            }
                        )
                ]
            }
        }
    }
}
