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
    let currentSelection: (drugName: String, count: Double)?
    let didSelectNumber: (Int) -> Void
    let didIncrementSelection: (Double) -> Void
    let didDecrementSelection: (Double) -> Void
}

struct DrugEntryNumberPad: View {
    private let sharedSpacing: CGFloat = 8.0

    let model: DrugEntryNumberPadModel
    private var currentCount: Double {
        model.currentSelection?.count ?? 0
    }
	
	var body: some View {
        HStack {
            Spacer()
            VStack {
                headerLabel
                fractionalInputs
            }
            Spacer()
            buttonGrid
		}
	}
    
    static let twelveStack = [
        [1, 2, 3, 4, 5, 6],
        [7, 8, 9, 10, 11, 12]
    ]
    
    static let fourWide = [
        [1, 2, 3, 4],
        [5, 6, 7, 8],
        [9, 10, 11, 12],
    ]
    
    static let threeWide = [
        [1, 2, 3],
        [4, 5, 6],
        [7, 8, 9],
        [10, 11, 12],
    ]
    
    private var fractionalInputs: some View {
        return HStack {
            Button("- ½", action: {
                model.didDecrementSelection(0.5)
            })
            .foregroundColor(.black)
            .padding(8)
            .boringBorder
            
            
            Button("+ ½", action: {
                model.didIncrementSelection(0.5)
            })
            .foregroundColor(.black)
            .padding(8)
            .boringBorder
        }
    }
	
	private var buttonGrid: some View {
        let grid = Self.threeWide
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
		return VStack {
            if let selection = model.currentSelection {
                Text(selection.drugName)
                    .bold()
                    .font(.headline)
                if selection.count > 0 {
                    Text(String(format: "%0.2f", selection.count))
                        .font(.subheadline)
                }
            } else {
                Text("No med selected")
                    .fontWeight(.ultraLight)
                    .italic()
            }
        }
        .padding(2)
            
	}
	
	private func numberButton(trackedNumber: Int) -> some View {
		return Button(action: {
            model.didSelectNumber(trackedNumber)
        }) {
			numberText(trackedNumber: trackedNumber)
        }
	}
	
	private func numberText(trackedNumber: Int) -> some View {
        let roundedSelection = Int(currentCount.rounded(.toNearestOrAwayFromZero))
        let isSelected = roundedSelection == trackedNumber

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
                    didSelectNumber: { _ in },
                    didIncrementSelection: { _ in },
                    didDecrementSelection: { _ in }
                )
            )
        }
    }
}

#endif
