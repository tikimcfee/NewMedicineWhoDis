//
//  DrugEntryView.swift
//  Drugs!
//
//  Created by Ivan Lugo on 9/8/19.
//  Copyright © 2019 Ivan Lugo. All rights reserved.
//

import Foundation
import SwiftUI

/**Model Extensions */
// ----------------------------------------------
extension Drug {
    var ingredientList: String {
        if self.ingredients.count == 1 && self.ingredients.first?.ingredientName == self.drugName {
            return ""
        } else {
            return self.ingredients.map { $0.ingredientName }.joined(separator: ", ")
        }
    }
}

// ----------------------------------------------

struct DrugEntryView: View {
    
    @State var currentSelectedDrug: Drug? = nil
    @State var currentMedicineEntries: [Drug:Int] = [:]
    
    var body: some View {
        HStack() {
            ScrollView {
                ForEach(__testData__listOfDrugs, id: \.self) { drug in
                    DrugEntryViewCell(
                        didTakeMap: self.$currentMedicineEntries,
                        currentSelectedDrug: self.$currentSelectedDrug,
                        trackedDrug: drug
                    )
                }
            }
            
        
            VStack {
                DrugEntryNumberPad(
                    didTakeMap: self.$currentMedicineEntries,
                    currentSelectedDrug: self.$currentSelectedDrug
                )
            }
        }
        .frame(maxHeight: 240)
        .padding(4.0)
    }
}

struct DrugEntryNumberPad: View {
    
    @Binding var didTakeMap: [Drug:Int]
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
            self.didTakeMap[drug] = number
        }
    }
    
    private func numberText(trackedNumber: Int = 1) -> some View {
        let text = Text("\(trackedNumber)")
            .frame(width: 44.0, height: 44.0, alignment: .center)
            .buttonBorder()
            
        if let drug = currentSelectedDrug,
            (didTakeMap[drug] ?? nil) == trackedNumber {
            return text.foregroundColor(Color.blue)
        } else {
            return text.foregroundColor(Color.black)
        }
    }
    
}

struct DrugEntryViewCell: View {
    
    @Binding var didTakeMap: [Drug:Int]
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
        var title = Text("\(trackedDrug.drugName)")
        var subTitle = Text("\(trackedDrug.ingredientList)")
        
        if trackedDrug == currentSelectedDrug {
            title = title.foregroundColor(Color.blue)
            subTitle = subTitle.foregroundColor(Color.blue)
        } else {
            title = title.foregroundColor(Color.black)
            subTitle = subTitle.foregroundColor(Color.black)
        }
        
        return VStack(alignment: .leading) {
            HStack {
                title
                    .font(.headline)
                    .fontWeight(.medium)
                FitView().foregroundColor(Color.blue)
                Text("\(String(didTakeMap[trackedDrug] ?? 0))")
                    .fontWeight(.thin)
            }
            
            subTitle
                .font(.footnote)
                .fontWeight(.ultraLight)
                .fixedSize(horizontal: false, vertical: true)
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
            DrugEntryNumberPad(
                didTakeMap: drugMapBinding(),
                currentSelectedDrug: drugBinding()
            )
            DrugEntryView()
            DrugEntryViewCell(
                didTakeMap: drugMapBinding(),
                currentSelectedDrug: drugBinding(),
                trackedDrug: Drug(
                    drugName: "Test Drug",
                    ingredients: [
                        Ingredient(ingredientName: "Sunshine"),
                        Ingredient(ingredientName: "Daisies"),
                    ]
                )
            )
        }
    }
}

#endif