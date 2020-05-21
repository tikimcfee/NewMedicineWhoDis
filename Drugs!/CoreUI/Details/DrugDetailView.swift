import SwiftUI

struct DrugDetailView: View {

    @EnvironmentObject var medicineLogOperator: MedicineLogOperator

    var body: some View {
        let data: [DetailEntryModel] = medicineLogOperator.coreAppState.detailState.selectedEntry.toDetailEntryModels()

        let count = data.count
		let screenTitle: String
		if count == 1 {
			screenTitle = "take this?"
		} else {
			screenTitle = "take these?"
		}
        
        return VStack(alignment: .leading) {
			
            Text("at \(self.medicineLogOperator.coreAppState.detailState.selectedEntry.date, formatter: dateFormatter)")
				.font(.title)
				.underline()

            List {
                ForEach (data, id: \.self) { item in
                    DetailEntryModelCell(
                        model: item,
                        fromEntry: self.medicineLogOperator.coreAppState.detailState.selectedEntry
                    ).listRowInsets(EdgeInsets())
                }
            }

            Spacer()

            Components.fullWidthButton("Edit this entry") {
                self.medicineLogOperator.coreAppState.detailState.editorState.editorIsVisible = true
            }
		}
		.padding(8.0)
		.navigationBarTitle(Text(screenTitle))
        .sheet(isPresented: $medicineLogOperator.coreAppState.detailState.editorState.editorIsVisible) {
            DrugEntryEditorView()
                .environmentObject(self.medicineLogOperator)
        }
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
            HStack(spacing: 2) {
				canTakeMedicineView
                    .padding(4)
                Text(model.drugName)
                    .padding(4.0)
                    .font(.headline)
                    .foregroundColor(titleColor)
                Text(model.countMessage)
                    .padding(4)
                    .frame(width: 20)
                    .font(.footnote)
                    .foregroundColor(Color.init(red: 1.0, green: 1.0, blue: 1.0))
                    .background(Color.init(red: 0.3, green: 0.7, blue: 0.7))
                    .clipShape(Circle())
                Spacer()
				subtitleView
			}
				
            HStack(alignment: .bottom) {
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
            .padding(4)
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

struct DetailEntryModel: Identifiable, EquatableFileStorable {
    var id = UUID()
    let drugName: String
    let countMessage: String
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
                countMessage: "\(drugsTaken[drug]!)",
                timeForNextDose: text,
                canTakeAgain: canTakeAgain,
				ingredientList: ingredientList
            )
        }.sorted { $0.drugName < $1.drugName }
	}
	
}

#if DEBUG

struct DrugDetailView_Previews: PreviewProvider {
    static var previews: some View {
        DrugDetailView()
            .environmentObject(makeTestMedicineOperator())
    }
}

#endif
