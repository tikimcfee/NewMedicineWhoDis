//
//  DrugEntryNumberPad.swift
//  Drugs!
//
//  Created by Ivan Lugo on 1/12/20.
//  Copyright © 2020 Ivan Lugo. All rights reserved.
//

import Foundation
import SwiftUI

struct DrugEntryNumberPadModel {
    let currentSelection: (drugName: String, count: Int)?
    let didSelectNumber: (Int) -> Void
}

struct DrugEntryNumberPad: View {
    private let sharedSpacing: CGFloat = 8.0

    let model: DrugEntryNumberPadModel
	
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
        if let selection = model.currentSelection {
            let title = "\(selection.drugName) (\(selection.count))"
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
		return Button(action: {
            model.didSelectNumber(trackedNumber)
        }) {
			numberText(trackedNumber: trackedNumber)
        }
	}
	
	private func numberText(trackedNumber: Int) -> some View {
        let isSelected = model.currentSelection?.count == trackedNumber

		let text = Text("\(trackedNumber)")
            .fontWeight(.bold)
			.frame(width: 48, height: 48, alignment: .center)
			.background(
                isSelected
                ? Color.buttonBackground
                : Color.init(.displayP3, red: 0.3, green: 0.3, blue: 0.3, opacity: 0.1)
            )

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
            DrugEntryNumberPad(
                model: DrugEntryNumberPadModel(
                    currentSelection: ("A Drug", 19),
                    didSelectNumber: { _ in }
                )
            )
        }
    }
}

#endif
