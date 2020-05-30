public struct ApplicationData: EquatableFileStorable {

    public enum CodingKeys: CodingKey {
        case mainEntryList
    }

    public var mainEntryList = [MedicineEntry]()

    public init() { }

    public init(from decoder: Decoder) throws {
        let codedKeys = try decoder.container(keyedBy: ApplicationData.CodingKeys.self)
        self.mainEntryList = try codedKeys.decode(Array<MedicineEntry>.self, forKey: .mainEntryList)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: ApplicationData.CodingKeys.self)
        try container.encode(mainEntryList, forKey: .mainEntryList)
    }

    public static func == (lhs: ApplicationData, rhs: ApplicationData) -> Bool {
        return lhs.mainEntryList == rhs.mainEntryList
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(mainEntryList)
    }

}
