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
	
    @EnvironmentObject var selectionListViewState: DrugSelectionContainerInProgressState
	
	private var currentDrugCount: Int {
        guard let drug = selectionListViewState.currentSelectedDrug else { return 0 }
        return selectionListViewState.count(for: drug) ?? 0
	}
	
	var body: some View {
		HStack {
            VStack(spacing: 4) {
				headerLabel.frame(minHeight: 16.0)
				buttonGrid
			}
		}
	}
	
	private var buttonGrid: some View {
		return VStack(spacing: 4) {
            HStack(spacing: 4) {
				createButtonsFor(1, 2, 3)
			}
            HStack(spacing: 4) {
                createButtonsFor(4, 5, 6)
            }
            HStack(spacing: 4) {
				createButtonsFor(7, 8, 9)
			}
		}
	}
	
	private var headerLabel: some View {
		var headerText: Text
        if let selectedDrug = selectionListViewState.currentSelectedDrug {
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
			self.numberButton(trackedNumber: $0)
		}
	}
	
	private func numberButton(trackedNumber: Int) -> some View {
		return Button(action: { self.onTap(of: trackedNumber) }) {
			numberText(trackedNumber: trackedNumber)
        }
	}
	
	private func onTap(of number: Int) {
        if let drug = selectionListViewState.currentSelectedDrug {
			// toggle selection
            if let lastSelection = selectionListViewState.count(for: drug), lastSelection == number {
                selectionListViewState.forDrug(drug, set: nil)
			} else {
                selectionListViewState.forDrug(drug, set: number)
			}
		}
	}
	
	private func numberText(trackedNumber: Int) -> some View {
		let text = Text("\(trackedNumber)")
            .fontWeight(.bold)
			.frame(width: 48, height: 48, alignment: .center)
			.background(Color.buttonBackground)
            .clipShape(Circle())
		
        if let currentDrug = selectionListViewState.currentSelectedDrug,
           selectionListViewState.count(for: currentDrug) == trackedNumber {
            return text.foregroundColor(Color.medicineCellSelected)
		} else {
			return text.foregroundColor(Color.medicineCellNotSelected)
		}
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
