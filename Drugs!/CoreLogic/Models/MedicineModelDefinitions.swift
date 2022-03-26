import Foundation

public struct AvailableDrugList: EquatableFileStorable {
    public static let empty = AvailableDrugList([])
    
    var drugs: [Drug]

    init(_ list: [Drug]) {
        self.drugs = list
    }
}

public typealias DrugId = String
public struct Drug: EquatableFileStorable, Comparable, Identifiable {
    public var drugName: String
    public var ingredients: [Ingredient]
    public var hourlyDoseTime: Double
    public var id: DrugId

    public init(_ drugName: String = "",
                _ ingredients: [Ingredient] = [],
                _ hourlyDoseTime: Double = 6,
                id: DrugId = UUID().uuidString) {
        self.drugName = drugName
        self.ingredients = ingredients
        self.hourlyDoseTime = hourlyDoseTime
        self.id = id
    }

    public static func < (lhs: Drug, rhs: Drug) -> Bool {
        return lhs.drugName < rhs.drugName
    }

    public static func == (lhs: Drug, rhs: Drug) -> Bool {
        return lhs.drugName == rhs.drugName
            && lhs.ingredients == rhs.ingredients
            && lhs.hourlyDoseTime == rhs.hourlyDoseTime
            && lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(ingredients)
        hasher.combine(hourlyDoseTime)
        hasher.combine(drugName)
    }
}

public struct Ingredient: EquatableFileStorable {
    let ingredientName: String
    public init(_ ingredientName: String) {
        self.ingredientName = ingredientName
    }
}

public typealias DrugCountMap = [Drug: Double]
public struct MedicineEntry: EquatableFileStorable, Identifiable {
    let uuid: String
    public var date: Date
    public var drugsTaken: DrugCountMap
    public var id: String { uuid }
    init(
        _ date: Date,
        _ drugsTaken: DrugCountMap,
        _ uuid: String = UUID.init().uuidString
    ) {
        self.date = date
        self.drugsTaken = drugsTaken
        self.uuid = uuid
    }
}

// MARK: String output

fileprivate let modelDescriptionEncoder: JSONEncoder = {
    let encoder = JSONEncoder()
    encoder.outputFormatting = .withoutEscapingSlashes
    return encoder
}()

fileprivate func jsonDescription<C: Codable>(of codable: C) -> String {
    guard let data = try? modelDescriptionEncoder.encode(codable) else {
        return "{Failed to encode \(type(of: codable))} \(codable)"
    }
    guard let string = String(data: data, encoding: .utf8) else {
        return "{Failed to decode \(type(of: codable))} \(codable)"
    }
    return string
}

//extension MedicineEntry: CustomStringConvertible {
//    public var description: String { jsonDescription(of: self) }
//}
//
//extension Drug: CustomStringConvertible {
//    public var description: String { jsonDescription(of: self) }
//}
//
//extension Ingredient: CustomStringConvertible {
//    public var description: String { jsonDescription(of: self) }
//}
//
//extension AvailableDrugList: CustomStringConvertible {
//    public var description: String { jsonDescription(of: self) }
//}

protocol Changeable { }

extension Changeable {
    func update<T>(_ path: WritableKeyPath<Self, T>, to value: T) -> Self {
        var clone = self
        clone[keyPath: path] = value
        return clone
    }
}
