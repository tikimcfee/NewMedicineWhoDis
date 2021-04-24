public struct ApplicationData: EquatableFileStorable {

    public var mainEntryList: [MedicineEntry] = []
    public var availableDrugList: AvailableDrugList = .defaultList

    public static func == (lhs: ApplicationData, rhs: ApplicationData) -> Bool {
        return lhs.mainEntryList == rhs.mainEntryList
            && lhs.availableDrugList == rhs.availableDrugList
    }
}

extension ApplicationData {
    public mutating func updateEntryList(_ handler: (inout [MedicineEntry]) -> Void) {
        log { Event("MedicineEntry list updating") }
        handler(&mainEntryList)
    }

    public mutating func updateDrugList(_ handler: (inout AvailableDrugList) -> Void) {
        log { Event("AvailableDrugList updating") }
        handler(&availableDrugList)
    }
}
