//
//  DrugEntryNumberPad.swift
//  Drugs!
//
//  Created by Ivan Lugo on 1/12/20.
//  Copyright © 2020 Ivan Lugo. All rights reserved.
//

import Foundation
import SwiftUI

struct DrugEntryNumberPad: View {

    private let sharedSpacing: CGFloat = 8.0
	
    @EnvironmentObject var selectionListViewState: DrugSelectionContainerInProgressState
	
	private var currentDrugCount: Int {
        guard let drug = selectionListViewState.model.currentSelectedDrug else { return 0 }
        return selectionListViewState.count(for: drug)
	}
	
	var body: some View {
		HStack {
            VStack(spacing: sharedSpacing) {
                headerLabel
                    .frame(width: 196, height: 32)
                    .padding(.horizontal)
                    .boringBorder
				buttonGrid
			}
		}
	}
	
	private var buttonGrid: some View {
        let grid = [
            [1, 2, 3, 4, 5, 6],
            [7, 8, 9, 10, 11, 12]
        ]
		return VStack(spacing: sharedSpacing) {
            ForEach(grid, id: \.self) { row in
                HStack(spacing: sharedSpacing) {
                    ForEach(row, id: \.self) {
                        numberButton(trackedNumber: $0)
                    }
                }
            }
		}
	}
	
	private var headerLabel: some View {
		var headerText: Text
        if let selectedDrug = selectionListViewState.model.currentSelectedDrug {
			let title = "\(selectedDrug.drugName) (\(currentDrugCount))"
			headerText = Text(title)
				.bold()
				.font(.subheadline)
		} else {
			headerText = Text("No med selected")
				.fontWeight(.ultraLight)
				.italic()
		}
		return headerText
	}
	
	private func createButtonsFor(_ numbersIn: Int...) -> some View {
		return ForEach(numbersIn, id:\.self) {
			numberButton(trackedNumber: $0)
		}
	}
	
	private func numberButton(trackedNumber: Int) -> some View {
		return Button(action: { self.onTap(of: trackedNumber) }) {
			numberText(trackedNumber: trackedNumber)
        }
	}
	
	private func onTap(of number: Int) {
        if let drug = selectionListViewState.model.currentSelectedDrug {
			// toggle selection
            if selectionListViewState.count(for: drug) == number {
                selectionListViewState.forDrug(drug, set: nil)
			} else {
                selectionListViewState.forDrug(drug, set: number)
			}
		}
	}
	
	private func numberText(trackedNumber: Int) -> some View {
        var isSelected = false
        if let currentDrug = selectionListViewState.model.currentSelectedDrug,
           selectionListViewState.count(for: currentDrug) == trackedNumber {
            isSelected = true
        }

		let text = Text("\(trackedNumber)")
            .fontWeight(.bold)
			.frame(width: 48, height: 48, alignment: .center)
			.background(
                isSelected
                ? Color.buttonBackground
                : Color.init(.displayP3, red: 0.3, green: 0.3, blue: 0.3, opacity: 0.1)
            )
//            .clipShape(Circle())

        return text.foregroundColor(
            isSelected
                ? Color.medicineCellSelected
                : Color.medicineCellNotSelected
        ).boringBorder
	}
	
}

#if DEBUG

struct DrugEntryNumberPad_Preview: PreviewProvider {
    static var previews: some View {
        Group {
            DrugEntryNumberPad()
                .environmentObject(DrugSelectionContainerInProgressState(
                    makeTestMedicineOperator()
                ))
        }
    }
}

#endif
