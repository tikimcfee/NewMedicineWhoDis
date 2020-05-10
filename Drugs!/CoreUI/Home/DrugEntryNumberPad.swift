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
	
	@ObservedObject var inProgressEntry: InProgressEntry
	@Binding var currentSelectedDrug: Drug?
	
	private var currentDrugCount: Int {
		guard let drug = currentSelectedDrug else { return 0 }
		return self.inProgressEntry.entryMap[drug] ?? 0
	}
	
	var body: some View {
		HStack {
			VStack {
				headerLabel.frame(minHeight: 16.0)
				buttonGrid
			}
			
			
			//			saveButton.padding(
			//				EdgeInsets.init(top: 4.0, leading: 0.0, bottom: 8.0, trailing: 4.0)
			//			)
		}
		
	}
	
	func onTapSave() {
		
	}
	
	private var saveButton: some View {
		Button(
			action: onTapSave
		) {
			Color.buttonBackground.slightlyRaised()
		}
	}
	
	private var buttonGrid: some View {
		return VStack {
			HStack {
				createButtonsFor(1, 2, 3, 4)
			}
			HStack {
				createButtonsFor(5, 6, 7, 8)
			}
		}
	}
	
	private var headerLabel: some View {
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
	
	private func numberButton(trackedNumber: Int) -> some View {
		return Button(action: { self.onTap(of: trackedNumber) }) {
			numberText(trackedNumber: trackedNumber)
		}
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
	
	private func numberText(trackedNumber: Int) -> some View {
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
