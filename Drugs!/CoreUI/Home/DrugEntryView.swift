//
//  DrugEntryView.swift
//  Drugs!
//
//  Created by Ivan Lugo on 9/8/19.
//  Copyright © 2019 Ivan Lugo. All rights reserved.
//

import Foundation
import SwiftUI

/**Model and View Extensions */
// ----------------------------------------------

class InProgressEntry: ObservableObject {
    @Published private var backingEntries: [Drug:Int] = [:]
    
    var entryMap: [Drug:Int] {
        get { return backingEntries }
        set(value) {
            self.backingEntries = value
            self.objectWillChange.send()
        }
    }
}

extension View {
    func prettyBorder() -> some View {
        return self
            .padding(8.0)
            .border(Color.init(red: 0.65, green: 0.85, blue: 0.95), width: 2.0)
            .cornerRadius(4.0)
    }
    
    func buttonBorder() -> some View {
        return self
            .padding(16.0)
            .border(Color.init(red: 0.65, green: 0.85, blue: 0.95), width: 2.0)
            .cornerRadius(4.0)
    }
}

// ----------------------------------------------

struct DrugEntryView: View {
    
    @ObservedObject var inProgressEntry: InProgressEntry = InProgressEntry()
    @State var currentSelectedDrug: Drug? = nil
    
    var body: some View {
        HStack() {
            ScrollView {
                ForEach(__testData__listOfDrugs, id: \.self) { drug in
                    DrugEntryViewCell(
                        inProgressEntry: self.inProgressEntry,
                        currentSelectedDrug: self.$currentSelectedDrug,
                        trackedDrug: drug
                    )
                }
            }
        
            VStack {
                DrugEntryNumberPad(
                    inProgressEntry: self.inProgressEntry,
                    currentSelectedDrug: self.$currentSelectedDrug
                )
            }
        }
        .frame(maxHeight: 240)
        .padding(4.0)
    }
    
    enum Result {
        case saved(clear: Bool)
        case error(clear: Bool)
    }
    
    func saveAndClear(with handler: ([Drug:Int]) -> Result) {
        let handlerResult = handler(self.inProgressEntry.entryMap)
        
        var shouldClear: Bool
        
        // todo: view animations, callbacks
        switch(handlerResult) {
        case .saved(let clear):
            shouldClear = clear
        case .error(let clear):
            shouldClear = clear
        }
        
        if shouldClear {
            resetState()
        }
    }
    
    func resetState(_ map: [Drug:Int] = [:]) {
        self.inProgressEntry.entryMap = map
    }
}

struct DrugEntryViewCell: View {
    
    @ObservedObject var inProgressEntry: InProgressEntry
    @Binding var currentSelectedDrug: Drug?
    let trackedDrug: Drug
    
    var body: some View {
        Button(action: onTap) {
            text()
        }.prettyBorder()
    }
    
    private func onTap() {
        self.currentSelectedDrug = self.trackedDrug
    }
    
    private func text() -> some View {
        var title =
            Text("\(trackedDrug.drugName)")
                .font(.subheadline)
                .fontWeight(.light)
        
        var subTitle =
            Text("\(trackedDrug.ingredientList)")
                .font(.footnote)
                .fontWeight(.ultraLight)
        
        var count =
            Text("\(String(self.inProgressEntry.entryMap[trackedDrug] ?? 0))")
                .fontWeight(.thin)
        
        if trackedDrug == currentSelectedDrug {
            title = title.foregroundColor(Color.blue)
            subTitle = subTitle.foregroundColor(Color.blue)
            count = count.foregroundColor(Color.blue)
        } else {
            title = title.foregroundColor(Color.black)
            subTitle = subTitle.foregroundColor(Color.black)
            count = count.foregroundColor(Color.black)
        }
        
        return VStack(alignment: .leading) {
            HStack {
                title
                FitView().foregroundColor(Color.blue)
                count
            }
            
            subTitle
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct DrugEntryNumberPad: View {
    
    @ObservedObject var inProgressEntry: InProgressEntry
    @Binding var currentSelectedDrug: Drug?
    
    let width: Int = 3
    let height: Int = 3
    
    var body: some View {
        VStack {
            HStack {
                ForEach([1, 2, 3], id:\.self) {
                    self.numberButton(trackedNumber: $0)
                }
            }
            HStack {
                ForEach([4, 5, 6], id:\.self) {
                    self.numberButton(trackedNumber: $0)
                }
            }
            HStack {
                ForEach([7, 8, 9], id:\.self) {
                    self.numberButton(trackedNumber: $0)
                }
            }
        }
    }
    
    private func numberButton(trackedNumber: Int = 1) -> some View {
        return Button(action: { self.onTap(of: trackedNumber) }) {
            numberText(trackedNumber: trackedNumber)
        }
    }
    
    private func onTap(of number: Int) {
        if let drug = self.currentSelectedDrug {
            self.inProgressEntry.entryMap[drug] = number
        }
    }
    
    private func numberText(trackedNumber: Int = 1) -> some View {
        let text = Text("\(trackedNumber)")
            .frame(width: 28.0, height: 28.0, alignment: .center)
            .buttonBorder()
            
        if let drug = currentSelectedDrug,
            (inProgressEntry.entryMap[drug] ?? nil) == trackedNumber {
            return text.foregroundColor(Color.blue)
        } else {
            return text.foregroundColor(Color.black)
        }
    }
    
}

struct FitView: View {
    let lineSize: CGFloat = 1.5
    let strokeDash: CGFloat = 3.0
    
    var body: some View {
        return Fit().stroke(
            style: StrokeStyle(
                lineCap: .round,
                dash: [strokeDash, strokeDash * 4]
            )
        ).frame(width: nil, height: lineSize, alignment: .center)
    }
    
}

struct Fit: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: 0, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        }
    }
}

#if DEBUG

struct DrugEntryView_Preview: PreviewProvider {
    @State var currentMedicineEntries: [Drug:Int]? = [:]
    
    static func drugMapBinding() -> Binding<[Drug : Int]> {
        return Binding<[Drug : Int]>(
            get: { () -> [Drug : Int] in [:] },
            set: { ([Drug : Int]) in }
        )
    }
    
    static func drugBinding() -> Binding<Drug?> {
        return Binding<Drug?>(
            get: { () -> Drug? in Drug.blank() },
            set: { (Drug) in }
        )
    }
    
    static var previews: some View {
        Group {
//            DrugEntryNumberPad(
//                didTakeMap: drugMapBinding(),
//                currentSelectedDrug: drugBinding()
//            )
            DrugEntryView()
//            DrugEntryViewCell(
//                didTakeMap: drugMapBinding(),
//                currentSelectedDrug: drugBinding(),
//                trackedDrug: Drug(
//                    drugName: "Test Drug",
//                    ingredients: [
//                        Ingredient(ingredientName: "Sunshine"),
//                        Ingredient(ingredientName: "Daisies"),
//                    ]
//                )
//            )
        }
    }
}

#endif
