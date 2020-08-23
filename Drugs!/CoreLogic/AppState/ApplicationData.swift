public struct ApplicationData: EquatableFileStorable {

    public enum CodingKeys: CodingKey {
        case listState
        case availableDrugList
    }

    public var mainEntryList: [MedicineEntry] = []
    public var availableDrugList: AvailableDrugList = .defaultList

    public init() { }

    public init(from decoder: Decoder) throws {
        let codedKeys = try decoder.container(keyedBy: ApplicationData.CodingKeys.self)
        self.mainEntryList = codedKeys.decodedEntryList
        self.availableDrugList = codedKeys.decodedDrugList
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

extension ApplicationData {
    public mutating func updateEntryList(_ handler: (inout [MedicineEntry]) -> Void) {
        handler(&mainEntryList)
    }

    public mutating func updateDrugList(_ handler: (inout AvailableDrugList) -> Void) {
        handler(&availableDrugList)
    }

    public func medicineListIndexFor(_ id: String) -> Int? {
        return mainEntryList.firstIndex(where: { $0.id == id })
    }

    public func drugListIndexFor(_ drug: Drug) -> Int? {
        return availableDrugList.drugs.firstIndex(where: { $0.id == drug.id })
    }
}

// MARK: - Helper for simpler handling of decoding keys
extension KeyedDecodingContainer where Key == ApplicationData.CodingKeys {
    var decodedEntryList: [MedicineEntry] {
        do {
            return try decode(Array<MedicineEntry>.self, forKey: .listState)
        } catch {
            loge{ Event("Failed to decode MedicineList, returning empty") }
            return []
        }
    }
    var decodedDrugList: AvailableDrugList {
        do {
            return try decode(AvailableDrugList.self, forKey: .availableDrugList)
        } catch {
            loge{ Event("Failed to decode AvailableDrugList, returning defaultList") }
            return AvailableDrugList.defaultList
        }
    }
}
