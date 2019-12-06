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
	@Published var entryMap: [Drug:Int] = [:]
}

extension View {
    func prettyBorder() -> some View {
        return self
            .padding(8.0)
            .border(Color.viewBorder, width: 2.0)
            .cornerRadius(4.0)
    }
    
    func buttonBorder() -> some View {
        return self
            .padding(16.0)
            .border(Color.buttonBorder, width: 2.0)
            .cornerRadius(4.0)
    }
	
	func slightlyRaised() -> some View {
		return self
			.shadow(color: Color.gray, radius: 0.5, x: 0.0, y: 0.5)
			.padding(4.0)
	}
}


struct DrugEntryView: View {
    
    @ObservedObject var inProgressEntry: InProgressEntry = InProgressEntry()
    @State var currentSelectedDrug: Drug? = nil
    
    var body: some View {
        ZStack {
			HStack(alignment: .center) {
                ScrollView {
                    ForEach(__testData__listOfDrugs, id: \.self) { drug in
                        DrugEntryViewCell(
                            inProgressEntry: self.inProgressEntry,
                            currentSelectedDrug: self.$currentSelectedDrug,
                            trackedDrug: drug
                        ).padding(
                            EdgeInsets.init(
                                top: 0.0, leading: 0.0,
                                bottom: 4.0, trailing: 0.0
                            )
                        )
                    }
				}.padding(
					EdgeInsets.init(
						top: 4.0, leading: 4.0,
						bottom: 4.0, trailing: 0.0
					)
				)
            
                DrugEntryNumberPad(
                    inProgressEntry: self.inProgressEntry,
                    currentSelectedDrug: self.$currentSelectedDrug
				).padding(.trailing, 2.0)
				
            }
        }
        .frame(height:280)
        .background(
			Color(red: 0.8, green: 0.9, blue: 0.9)
		).slightlyRaised()
        
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
			case .saved(let clear), 
				 .error(let clear):
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
            text().padding(.trailing, 16.0)
        }
    }
    
    private func onTap() {
        if let selected = self.currentSelectedDrug, selected == self.trackedDrug {
            self.currentSelectedDrug = nil
        } else {
            self.currentSelectedDrug = self.trackedDrug
        }
    }
    
    private func text() -> some View {
        var title =
            Text("\(trackedDrug.drugName)")
                .font(.subheadline)
                .fontWeight(.light)
        
        
        
        var count =
            Text("\(String(self.inProgressEntry.entryMap[trackedDrug] ?? 0))")
                .fontWeight(.thin)
        
        if trackedDrug == currentSelectedDrug {
			title = title.foregroundColor(Color.medicineCellSelected)
            count = count.foregroundColor(Color.medicineCellSelected)
        } else {
            title = title.foregroundColor(Color.medicineCellSelected)
            count = count.foregroundColor(Color.medicineCellSelected)
        }
        
        return VStack(alignment: .leading) {
            HStack {
                title
                Spacer()
                count
            }
//            subTitle.fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct DrugEntryNumberPad: View {
    
    @ObservedObject var inProgressEntry: InProgressEntry
    @Binding var currentSelectedDrug: Drug?
    
    private var currentDrugCount: Int {
        guard let drug = currentSelectedDrug else { return 0 }
        return self.inProgressEntry.entryMap[drug] ?? 0
    }
    
    var body: some View {
        VStack {
            headerLabel()
            
            HStack {
                createButtonsFor(1, 2, 3)
            }
            HStack {
                createButtonsFor(4, 5, 6)
            }
			HStack {
                createButtonsFor(7, 8, 9)
            }
        }
    }
    
    private func headerLabel() -> some View {
        var headerText: Text
        if let selectedDrug = currentSelectedDrug {
            let title = "\(selectedDrug.drugName) (\(currentDrugCount))"
            
            headerText = Text(title)
                .bold()
                .font(.subheadline)
        } else {
            headerText = Text("Pick a thing from the list")
                .fontWeight(.ultraLight)
                .italic()
        }
        return headerText
    }
    
    private func createButtonsFor(_ numbersIn: Int...) -> some View {
        return ForEach(numbersIn, id:\.self) {
            self.numberButton(trackedNumber: $0)
        }
    }
    
    private func numberButton(trackedNumber: Int = 1) -> some View {
        return Button(action: { self.onTap(of: trackedNumber) }) {
            numberText(trackedNumber: trackedNumber)
        }.padding(EdgeInsets(top: 4.0, leading: 0.0, bottom: 4.0, trailing: 0.0))
    }
    
    private func onTap(of number: Int) {
        if let drug = self.currentSelectedDrug {
            // toggle selection
            if let lastSelection = self.inProgressEntry.entryMap[drug],
                lastSelection == number {
                self.inProgressEntry.entryMap[drug] = nil
            } else {
                self.inProgressEntry.entryMap[drug] = number
            }
            
        }
    }
    
    private func numberText(trackedNumber: Int = 1) -> some View {
        let text = Text("\(trackedNumber)")
            .frame(width: 28.0, height: 28.0, alignment: .center)
            .buttonBorder()
            
        if let drug = currentSelectedDrug,
            (inProgressEntry.entryMap[drug] ?? nil) == trackedNumber {
            return text.foregroundColor(Color.medicineCellSelected)
        } else {
            return text.foregroundColor(Color.medicineCellNotSelected)
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
            DrugEntryView()
        }
    }
}

#endif
