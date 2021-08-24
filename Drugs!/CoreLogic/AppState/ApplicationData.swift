public struct ApplicationData {

    public enum CodingKeys: CodingKey {
        case listState
        case availableDrugList
    }

    public var mainEntryList: [MedicineEntry] = []
    public var availableDrugList: AvailableDrugList = .defaultList

    public init() { }
}
