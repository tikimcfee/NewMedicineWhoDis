import Foundation


// MARK: Container for list and number

struct SelectableDrug: Hashable, Equatable {
    let drugName: String
    let drugId: DrugId
}

struct DrugSelectionContainerModel {
    var inProgressEntry = InProgressEntry()
    var currentSelectedDrug: SelectableDrug?
    var info = AvailabilityInfo()
    var availableDrugs = [SelectableDrug]()
}

extension DrugSelectionContainerModel {
    func count(for drug: SelectableDrug) -> Double {
        inProgressEntry.entryMap[drug] ?? 0
    }
    
    func roundedCount(for drug: SelectableDrug) -> Double {
        count(for: drug).rounded(.down)
    }
    
    mutating func updateCount(_ count: Double?, for drug: SelectableDrug) {
        inProgressEntry.entryMap[drug] = count
    }
    
    mutating func resetEdits() {
        inProgressEntry = InProgressEntry()
        currentSelectedDrug = nil
    }
}

// MARK: Selectable drug rows

public struct DrugSelectionListRowModel {
    let drug: SelectableDrug
    let count: Double
    let canTake: Bool
    let timingMessage: String
    let timingIcon: String
    let isSelected: Bool
    let didSelect: Action
}

public struct DrugSelectionListModel {
    let selectableDrugs: [DrugSelectionListRowModel]
}
