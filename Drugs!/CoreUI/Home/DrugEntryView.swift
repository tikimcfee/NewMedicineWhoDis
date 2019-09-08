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
    
    @State var currentMedicineEntries: [Drug:Int] = [:]
    
    var body: some View {
        VStack(alignment: .leading) {
            ForEach(__testData__listOfDrugs, id: \.self) { drug in
                DrugEntryViewCell(didTakeMap: self.$currentMedicineEntries, drug: drug)
            }
            
            VStack {
                Text("Number Pad")
            }
            .prettyBorder()
            .fixedSize(horizontal: false, vertical: false)
            .frame(width: 55, height: 44, alignment: .center)
        }
        
    }
}

struct DrugEntryViewCell: View {
    
    @Binding var didTakeMap: [Drug:Int]
    let drug: Drug
    
    
    var body: some View {
        HStack {
            Spacer().frame(width: 44.0, height: 0.0, alignment: .center)
            
            Button(
                action: { }
            ) {
                VStack(alignment: .leading) {
                    Text("\(drug.drugName)")
                        .font(.headline)
                        .fontWeight(.medium)
                        
                    Text("\(drug.ingredientList)")
                        .font(.footnote)
                        .fontWeight(.ultraLight)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
            }
            
            FitView().foregroundColor(Color.blue)

            VStack(alignment: .leading) {
                Text("\(String(didTakeMap[drug] ?? 0))")
                    .fontWeight(.thin)
            }
            .prettyBorder()
            
            Spacer().frame(width: 44.0, height: 0.0, alignment: .center)
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
                dash: [strokeDash, strokeDash + 2, strokeDash + 4]
            )
        ).frame(width: nil, height: lineSize, alignment: .center)
    }
    
}

struct Fit: Shape {
    func path(in rect: CGRect) -> Path {
        Path { path in
            path.move(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: rect.maxX, y: 0))
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
}

#if DEBUG

struct DrugEntryView_Preview: PreviewProvider {
    @State var currentMedicineEntries: [Drug:Int]? = [:]
    
    static var previews: some View {
        Group {
            DrugEntryView()
            DrugEntryViewCell(
                didTakeMap: Binding<[Drug : Int]>(get: { () -> [Drug : Int] in
                    [:]
                }, set: { ([Drug : Int]) in
                    
                }),
                drug: Drug(
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
