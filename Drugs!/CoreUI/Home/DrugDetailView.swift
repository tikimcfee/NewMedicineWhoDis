//
//  DrugDetailView.swift
//  Drugs!
//
//  Created by Ivan Lugo on 9/21/19.
//  Copyright © 2019 Ivan Lugo. All rights reserved.
//

import SwiftUI

struct DrugDetailView: View {
    let medicineEntry: MedicineEntry
	
	init(_ entry: MedicineEntry) {
		self.medicineEntry = entry
	}

    var body: some View {
		let data: [DetailEntryModel] = medicineEntry.toDetailEntryModels()
		let count = data.count
		let screenTitle: String
		if count == 1 {
			screenTitle = "... take this?"
		} else {
			screenTitle = "... take these?"
		}
        
        return VStack(alignment: .leading) {
			
			Text("at \(medicineEntry.date, formatter: dateFormatter)")
				.font(.title)
				.underline()

            List {
                ForEach (data, id: \.self) { item in
                    DetailEntryModelCell(model: item, fromEntry: self.medicineEntry)
                        .listRowInsets(EdgeInsets())
                }
            }
		}
		.padding(8.0)
		.navigationBarTitle(Text(screenTitle))
    }
}

struct DetailEntryModelCell: View {
    let model: DetailEntryModel
    let fromEntry: MedicineEntry
    
    var body: some View {
		let titleColor: Color
		if model.canTakeAgain {
			titleColor = Color.black
		} else {
			titleColor = Color.gray
		}
		
        return VStack(alignment: .leading, spacing: 0) {
			HStack {
				canTakeMedicineView
				Text(model.drugName)
					.padding(4.0)
					.font(.headline)
					.foregroundColor(titleColor)
				subtitleView
				Spacer()
			}
				
			HStack {
				Spacer()
				Text(model.timeForNextDose)
					.padding(.top, 10.0)
			}				
        }.padding(4.0)
			.background(
                model.canTakeAgain
                    ? Color.timeForNextDoseReady
                    : Color.timeForNextDose
            )
			.cornerRadius(4.0)
			.slightlyRaised()
    }
	
	private var subtitleView: some View {
		return Text("\(self.model.ingredientList)")
			.font(.footnote)
			.fontWeight(.ultraLight)
			.fixedSize(horizontal: false, vertical: true)
	}
	
	private var canTakeMedicineView: some View {
		let config: (image: String, color: Color)
		if model.canTakeAgain {
			config = ("checkmark.circle.fill", Color.timeForNextDoseImageNow)
		} else {
			config = ("multiply.circle", Color.timeForNextDoseImageLater)
		}
		return Image(systemName: config.image)
			.foregroundColor(config.color)
	}
    
}

struct DetailEntryModel: Identifiable, FileStorable {
    var id = UUID()
    let drugName: String
    let timeForNextDose: String
    let canTakeAgain: Bool
	let ingredientList: String
}

extension MedicineEntry {
	
	func toDetailEntryModels() -> [DetailEntryModel] {
		let now = Date()
		return timesDrugsAreNextAvailable.map { (drug, date) in
			
			let canTakeAgain = now >= date
			let formattedDate = dateFormatterSmall.string(from: date)
			let ingredientList = drug.ingredientList
			
			let text: String
			if canTakeAgain {
				text = "You can take some \(drug.drugName) now"
			} else {
				text = "Wait 'till about \(formattedDate)"
			}
			
            return DetailEntryModel(
                drugName: drug.drugName,
                timeForNextDose: text,
                canTakeAgain: canTakeAgain,
				ingredientList: ingredientList
            )
        }.sorted { $0.drugName < $1.drugName }
	}
	
}

#if DEBUG

struct DrugDetailView_Previews: PreviewProvider {
    private static let entry = DefaultDrugList.shared.defaultEntry
    static var previews: some View {
		DrugDetailView(entry)
    }
}

#endif
