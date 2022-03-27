import Foundation

struct SelectableDrug: Hashable, Equatable {
    let drugName: String
    let drugId: DrugId
    let selectedCountAutoUpdate: (Double?) -> Void
    func hash(into hasher: inout Hasher) {
        hasher.combine(drugName)
        hasher.combine(drugId)
    }
    static func == (lhs: SelectableDrug, rhs: SelectableDrug) -> Bool {
        return lhs.drugId == rhs.drugId
            && rhs.drugName == rhs.drugName
    }
}

// MARK: Container for list and number

enum SelectionError: Error {
    case drugMappingError
}
struct DrugSelectionContainerModel {
    
    var isInitial = true
    var entryMap: [SelectableDrug: Double] = [:]
        { didSet { isInitial = false }}
    
    var currentSelectedDrug: SelectableDrug?
    var info = AvailabilityInfo()
    var availableDrugs = AvailableDrugList([Drug]())

    func count(for drug: SelectableDrug) -> Double {
        entryMap[drug] ?? 0
    }
    
    func roundedCount(for drug: SelectableDrug) -> Double {
        count(for: drug).rounded(.down)
    }

    mutating func updateCount(_ count: Double?, for drug: SelectableDrug) {
        entryMap[drug] = count
    }

    mutating func resetEdits() {
        entryMap.removeAll()
        currentSelectedDrug = nil
    }
    
    func drugMap(in availableDrugList: AvailableDrugList) throws -> DrugCountMap {
        let drugIdMap = availableDrugList.drugs.reduce(into: [DrugId: Drug]()) { result, drug in
            result[drug.id] = drug
        }
        
        let drugMap = try entryMap.reduce(into: DrugCountMap()) { result, pair in
            guard let drug = drugIdMap[pair.key.drugId] else {
                throw SelectionError.drugMappingError
            }
            result[drug] = pair.value
        }
        
        return drugMap
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
