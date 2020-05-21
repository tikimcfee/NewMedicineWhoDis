//
//  TestingAppState.swift
//  Drugs!
//
//  Created by Ivan Lugo on 5/21/20.
//  Copyright © 2020 Ivan Lugo. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

public class EditorState: ObservableObject {
    @Published var inProgressEntry: InProgressEntry
    @Published var editorIsVisible: Bool = false
    @Published var editorError: AppStateError?
    private var cancellables: Set<AnyCancellable> = []

    public init (sourceEntry: MedicineEntry) {
        self.inProgressEntry = InProgressEntry(sourceEntry.drugsTaken)
        sink(inProgressEntry.objectWillChange, objectWillChange, &cancellables)
    }
}

public class DetailsState: ObservableObject {
    @Published var selectedEntry: MedicineEntry =
        DefaultDrugList.shared.defaultEntry
    @Published var editedState: DrugEntryEditorState =
        DrugEntryEditorState(sourceEntry: DefaultDrugList.shared.defaultEntry)
}

public class AppMedicineEntriesState: ObservableObject {
    @Published var listState: [MedicineEntry] = []
}

public class AppState2: ObservableObject {
    @Published var detailsState = DetailsState()
    @Published var entriesState = AppMedicineEntriesState()
    private var cancellables: Set<AnyCancellable> = []
    init() {
        sink(detailsState.objectWillChange, objectWillChange, &cancellables)
        sink(entriesState.objectWillChange, objectWillChange, &cancellables)
    }
}

func sink(_ x: ObservableObjectPublisher,
          _ y: ObservableObjectPublisher,
          _ set: inout Set<AnyCancellable>) {
    set.insert( x.sink { (_) in y.send() } )
}
