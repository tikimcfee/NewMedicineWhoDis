import Foundation

typealias SelectableDrugId = String

struct SelectableDrug: Hashable, Equatable {
    let drugName: String
    let drugId: SelectableDrugId
}

struct InProgressEntry {
    var entryMap: [Drug: Int]
    var date: Date
    init(
        _ map: [Drug: Int] = [:],
        _ date: Date = Date()
    ) {
        self.entryMap = map
        self.date = date
    }
}
