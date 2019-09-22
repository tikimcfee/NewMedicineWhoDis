//
//  DrugDetailView.swift
//  Drugs!
//
//  Created by Ivan Lugo on 9/21/19.
//  Copyright © 2019 Ivan Lugo. All rights reserved.
//

import SwiftUI

struct DrugDetailView: View {
    var medicineEntry: MedicineEntry?

    var body: some View {
        let data: [DetailEntryModel] = medicineEntry?.toDetailEntryModels() ?? []
        
        return VStack(alignment: .leading) {
			
            Text("\(Date(), formatter: dateFormatter)")
			
            ForEach(data, id: \.self) { item in
                DetailEntryModelCell(model: item, fromEntry: self.medicineEntry!)
            }
			
        }.navigationBarTitle(Text("Detail"))
    }
}

struct DetailEntryModelCell: View {
    let model: DetailEntryModel
    let fromEntry: MedicineEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(model.drugName)
            }
			HStack {
				canTakeMedicineView
				Text(model.timeForNextDose)
			}
			.padding(4.0)
			.background(Color.timeForNextDose)
			.cornerRadius(4.0)
				
        }.padding(4.0)
    }
	
	private var canTakeMedicineView: some View {
		let config: (image: String, color: Color)
		if model.canTakeAgain {
			config = ("checkmark.circle.fill", Color.timeForNextDoseImageNow)
		} else {
			config = ("multiply.circle", Color.timeForNextDoseImageLater )
		}
		return Image(systemName: config.image).foregroundColor(config.color)
	}
    
}

struct DetailEntryModel: Identifiable, Storable {
    var id = UUID()
    let drugName: String
    let timeForNextDose: String
    let canTakeAgain: Bool
}

extension MedicineEntry {
	
	func toDetailEntryModels() -> [DetailEntryModel] {
		let now = Date()
		return timesDrugsAreNextAvailable.compactMap { keyPair in
			
			let canTakeAgain = now >= keyPair.value
			let formattedDate = dateFormatterSmall.string(from: keyPair.value)
			
			let text: String
			if canTakeAgain {
				text = "Go for it! (was ready at \(formattedDate))"
			} else {
				text = "Wait 'till about \(formattedDate)"
			}
			
            return DetailEntryModel(
                drugName: keyPair.key.drugName,
                timeForNextDose: text,
                canTakeAgain: canTakeAgain
            )
        }
	}
	
}

#if DEBUG

struct DrugDetailView_Previews: PreviewProvider {
    static var previews: some View {
		DrugDetailView(medicineEntry: __testData__anEntry)
    }
}

#endif
