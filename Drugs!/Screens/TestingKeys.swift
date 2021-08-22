enum AppTabAccessID: String {
    case addEntry
    case entryList
    case notifications
    case drugList
}

enum MedicineLogScreen: String {
    case saveEntry

    case entryCellList
    case entryCellButton
    case entryCellBody
    case entryCellTitleText
    case entryCellSubtitleText
}

enum DetailScreen: String {
    case editThisEntry
}

enum EditEntryScreen: String {
    case saveEditsButton
    case cancelEditsButton

    case oldTimeLabel
    case newTimeLabel
    case datePickerButton
}

enum DrugList: String, CaseIterable {
    case Gabapentin = "Gabapentin"
    case Tylenol = "Tylenol"
    case Venlafaxine = "Venlafaxine"
    case Dramamine = "Dramamine"
    case Excedrin = "Excedrin"
    case Ibuprofen = "Ibuprofen"
    case Omeprazole = "Omeprazole"
    case Melatonin = "Melatonin"
    case Tums = "Tums"
    case Vitamins = "Vitamins"
}

enum NumberPad: String, CaseIterable {
    case one    = "1"
    case two    = "2"
    case three  = "3"
    case four   = "4"
    case five   = "5"
    case six    = "6"
    case seven  = "7"
    case eight  = "8"
    case nine   = "9"
}
