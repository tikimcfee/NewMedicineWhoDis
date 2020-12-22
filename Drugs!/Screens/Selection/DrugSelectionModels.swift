import Foundation

struct SelectableDrug: Hashable, Equatable {
    let drugName: String
    let drugId: DrugId
}

struct InProgressEntry {
    var entryMap: [SelectableDrug: Int]
    var date: Date
    init(
        _ map: [SelectableDrug: Int] = [:],
        _ date: Date = Date()
    ) {
        self.entryMap = map
        self.date = date
    }
}

enum InProgressEntryError: Error {
    case mappingBackToDrugs
}

extension InProgressEntry {
    func drugMap(in availableDrugList: AvailableDrugList) throws -> [Drug: Int] {
        let drugIdMap = availableDrugList.drugs.reduce(into: [DrugId: Drug]()) { result, drug in
            result[drug.id] = drug
        }

        let drugMap = try entryMap.reduce(into: [Drug: Int]()) { result, pair in
            guard let drug = drugIdMap[pair.key.drugId] else {
                throw InProgressEntryError.mappingBackToDrugs
            }
            result[drug] = pair.value
        }

        return drugMap
    }

    static func != (_ inProgress: InProgressEntry, _ other: MedicineEntry) -> Bool {
        return !(inProgress == other)
    }

    static func == (_ inProgress: InProgressEntry, _ other: MedicineEntry) -> Bool {
        guard inProgress.date == other.date else { return false }

        // Add each set of drugs to a map and check that the ID and count exists in the other.
        // This is weak guarantee and a little non performant.
        var comparisonMap = [DrugId: Int]()
        inProgress.entryMap.forEach { comparisonMap[$0.key.drugId] = $0.value }
        return other.drugsTaken.allSatisfy { comparisonMap[$0.key.id] == $0.value }
    }
}

// MARK: Container for list and number

struct DrugSelectionContainerModel {
    var inProgressEntry = InProgressEntry()
    var currentSelectedDrug: SelectableDrug?
    var info = AvailabilityInfo()
    var availableDrugs = AvailableDrugList([Drug]())

    func count(for drug: SelectableDrug) -> Int {
        inProgressEntry.entryMap[drug] ?? 0
    }

    mutating func updateCount(_ count: Int?, for drug: SelectableDrug) {
        inProgressEntry.entryMap[drug] = count
    }

    mutating func resetEdits() {
        inProgressEntry = InProgressEntry()
        currentSelectedDrug = nil
    }
}


// MARK: Selectable drug rows

struct DrugSelectionListRowModel {
    let drug: SelectableDrug
    let count: Int
    let canTake: Bool
    let isSelected: Bool
    let didSelect: Action
}

struct DrugSelectionListModel {
    let selectableDrugs: [DrugSelectionListRowModel]
}
