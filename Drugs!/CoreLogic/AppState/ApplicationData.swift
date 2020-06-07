public struct ApplicationData: EquatableFileStorable {

    public enum CodingKeys: CodingKey {
        case listState
        case availableDrugList
    }

    public var mainEntryList = [MedicineEntry]()
    public var availableDrugList = AvailableDrugList.defaultList

    public init() { }

    public mutating func updateEntryList(_ handler: (inout [MedicineEntry]) -> Void) {
        handler(&mainEntryList)
    }

    public mutating func updateDrugList(_ handler: (inout AvailableDrugList) -> Void) {
        handler(&availableDrugList)
    }

    public init(from decoder: Decoder) throws {
        let codedKeys = try decoder.container(keyedBy: ApplicationData.CodingKeys.self)
        self.mainEntryList = try codedKeys.decode(Array<MedicineEntry>.self, forKey: .listState)
        do {
            self.availableDrugList = try codedKeys.decode(AvailableDrugList.self, forKey: .availableDrugList)
        } catch {
            logd { Event("AppDataInit", "Couldn't load drug list; reverting to default; \(error)", .debug) }
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: ApplicationData.CodingKeys.self)
        try container.encode(mainEntryList, forKey: .listState)
        try container.encode(availableDrugList, forKey: .availableDrugList)
    }

    public static func == (lhs: ApplicationData, rhs: ApplicationData) -> Bool {
        return lhs.mainEntryList == rhs.mainEntryList
            && lhs.availableDrugList == rhs.availableDrugList
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(mainEntryList)
        hasher.combine(availableDrugList)
    }

}
