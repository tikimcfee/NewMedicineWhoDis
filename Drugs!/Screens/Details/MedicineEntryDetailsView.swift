import Combine
import SwiftUI

struct MedicineEntryDetailsView: View {

    @EnvironmentObject var detailsState: MedicineEntryDetailsViewState

    var body: some View {
        return VStack(alignment: .leading) {
            Text(detailsState.viewModel.displayDate)
                .font(.body)
            ScrollView {
                VStack {
                    ForEach (detailsState.viewModel.displayModels, id: \.self) { item in
                        DetailEntryModelCell(model: item)
                            .listRowInsets(EdgeInsets())
                            .drawingGroup() // this thing apparrently takes forever to render
                    }
                }
            }
            Spacer()
            Components.fullWidthButton("Edit this entry") {
                self.detailsState.startEditing()
            }.accessibility(identifier: DetailScreen.editThisEntry.rawValue)
		}
		.padding(8.0)
        .navigationBarTitle(Text(self.detailsState.viewModel.title))
        .sheet(isPresented: self.$detailsState.editorIsVisible) {
            DrugEntryEditorView()
                .environmentObject(self.detailsState.editorState!)
                .environmentObject(self.detailsState.dataManager)
        }
    }
}

struct DetailEntryModelCell: View {
    let model: DetailEntryModel
    
    var body: some View {
		let titleColor: Color
		if model.canTakeAgain {
			titleColor = Color.black
		} else {
			titleColor = Color.black
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
                    ? Color.computedCanTake
                    : Color.computedCannotTake
            )
			.cornerRadius(4.0)
            .shadow(color: Color.gray, radius: 0.5, x: 0.0, y: 0.5)
            .padding(4.0)
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

public struct DetailEntryModel: Identifiable, EquatableFileStorable {
    public var id = UUID()
    let drugName: String
    let countMessage: String
    let timeForNextDose: String
    let canTakeAgain: Bool
	let ingredientList: String
}


#if DEBUG
struct DrugDetailView_Previews: PreviewProvider {
    @State var selected: MedicineEntry = DefaultDrugList.shared.defaultEntry
    static var previews: some View {
        let data = makeTestMedicineOperator()
        let state = MedicineEntryDetailsViewState(data, data.TEST_getAMedicineEntry.id)
        return MedicineEntryDetailsView().environmentObject(state)
    }
}
#endif
