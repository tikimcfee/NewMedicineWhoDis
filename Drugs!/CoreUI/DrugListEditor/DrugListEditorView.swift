//
//  DrugListEditorView.swift
//  Drugs!
//
//  Created by Ivan Lugo on 6/7/20.
//  Copyright © 2020 Ivan Lugo. All rights reserved.
//

import SwiftUI

struct DrugListEditorView: View {

    @EnvironmentObject var drugListEditorState: DrugListEditorViewState

    var body: some View {
        return VStack {
            subviewDrugList
            subviewEditor
        }
    }

    private var subviewDrugList: some View {
        return ScrollView {
            VStack{
                ForEach(drugList, id: \.self) { drug in
                    HStack {
                        self.textGroup(drug)
                        Spacer()
                        Image.init(systemName: "pencil")
                            .padding(8)
                            .boringBorder
                            .asButton {
                                withAnimation(.easeInOut) {
                                    self.drugListEditorState.inProgressEdit.targetDrug = drug
                                }
                            }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(4)
                    .boringBorder
                }
            }.padding(.horizontal, 16.0)
        }
    }

    private func textGroup(_ drug: Drug) -> some View {
        return HStack(alignment: .center) {
            VStack(alignment: .leading) {
                Text(drug.drugName)
                if drug.ingredientList != "" {
                    Text(drug.ingredientList)
                        .font(.footnote)
                }
            }
            Spacer()
            Text(String.init(format: "%.0f hours", drug.hourlyDoseTime))
                .font(.footnote)
        }
    }

    private var subviewEditor: some View {
        return VStack {
            HStack {
                TextField
                    .init(currentDrugName, text: inProgressEdit.updatedName)
                    .padding()
                    .frame(minHeight: 64, maxHeight: 64, alignment: .center)
                    .boringBorder
                Picker(selection: $drugListEditorState.inProgressEdit.updatedDoseTime, label: EmptyView()) {
                    ForEach((0..<25)) { hour in
                        Text("\("hour".simplePlural(hour, "Any time"))").tag(hour)
                    }
                }.frame(maxWidth: 128, maxHeight: 64).clipped().boringBorder
            }
            HStack {
                Components.fullWidthButton("Save Changes") {
                    withAnimation {
                        self.drugListEditorState.saveCurrentChanges()
                    }
                }
                .disabled(!drugListEditorState.canSave)
            }
        }
        .padding()
        .background(Color(red: 0.8, green: 0.9, blue: 0.9)).boringBorder
    }
}

private extension DrugListEditorView {
    var currentDrugName: String {
        return drugListEditorState.inProgressEdit.targetDrug?.drugName
            ?? "Select a drug to edit"
    }

    var inProgressEdit: Binding<InProgressDrugEdit> {
        return $drugListEditorState.inProgressEdit
    }

    var drugList: [Drug] {
        return drugListEditorState.currentDrugList.drugs
    }
}

#if DEBUG
struct DrugListEditorView_Previews: PreviewProvider {
    static var previews: some View {
        DrugListEditorView().environmentObject(
            DrugListEditorViewState(makeTestMedicineOperator())
        )
    }
}
#endif
