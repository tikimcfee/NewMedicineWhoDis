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
	
	func slightlyRaised() -> some View {
		return self
			.shadow(color: Color.gray, radius: 0.5, x: 0.0, y: 0.5)
			.padding(4.0)
	}
}


struct DrugEntryView: View {

    private let drugList = DefaultDrugList.shared.drugs
    
    @ObservedObject var inProgressEntry: InProgressEntry = InProgressEntry()
    @State var currentSelectedDrug: Drug? = nil
    
    var body: some View {
        ZStack {
			HStack(alignment: .center) {
                ScrollView {
                    ForEach(drugList, id: \.self) { drug in
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
			text().padding(
				EdgeInsets.init(top: 4.0, leading: 8.0, bottom: 4.0, trailing: 8.0)
			)
		}.background(Color.buttonBackground.slightlyRaised())
			
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
            Text("(\(String(self.inProgressEntry.entryMap[trackedDrug] ?? 0)))")
                .fontWeight(.thin)
				
        if trackedDrug == currentSelectedDrug {
			title = title.foregroundColor(Color.medicineCellSelected)
            count = count.foregroundColor(Color.medicineCellSelected)
        } else {
            title = title.foregroundColor(Color.medicineCellNotSelected)
            count = count.foregroundColor(Color.medicineCellNotSelected)
        }
        
		return HStack {
			title
			count
		}.padding(
			EdgeInsets.init(top: 0, leading: 4.0, bottom: 0, trailing: 4.0)
		)
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
//            RootAppStartupView()
//                .environmentObject(makeTestMedicineOperator())
            DrugEntryView()
        }
    }
}

#endif
