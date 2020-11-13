enum HomeButtons: String {
    case saveEntry = "saveEntry"

    case entryCellList = "entryCellList"
    case entryCellButton = "entryCellButton"
    case entryCellBody = "entryCellBody"
    case entryCellTitleText = "entryCellTitleText"
    case entryCellSubtitleText = "entryCellSubtitleText"
}

enum DrugList: String {
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
