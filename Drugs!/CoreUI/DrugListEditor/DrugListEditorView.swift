//
//  DrugListEditorView.swift
//  Drugs!
//
//  Created by Ivan Lugo on 6/7/20.
//  Copyright © 2020 Ivan Lugo. All rights reserved.
//

import SwiftUI

extension View {
    func asButton(_ action: @escaping () -> Void) -> some View{
        return modifier(AsButtonMod(action: action))
    }
}

struct AsButtonMod: ViewModifier {
    let action: () -> Void
    func body(content: Content) -> some View {
        return Button(action: action) { content }
    }
}

struct DrugListEditorView: View {

    @EnvironmentObject var drugListEditorState: DrugListEditorViewState

    var body: some View {
        return VStack(spacing: 0) {
            subviewDrugList
            subviewEditor
        }
    }

    private func textGroup(_ drug: Drug) -> some View {
        return Group {
            Text(drug.drugName)
            if drug.ingredientList != "" {
                Text(drug.ingredientList)
                    .font(.footnote)
            }
            Text(String.init(format: "Every %.0f hours", drug.hourlyDoseTime))
                .font(.footnote)
        }
    }

    private var subviewDrugList: some View {
        return ScrollView {
            VStack{
                ForEach(drugList, id: \.self) { drug in
                    HStack {
                        textGroup(drug)
                        Spacer()
                        Image.init(systemName: "pencil")
                            .padding(4)
                            .boringBorder
                            .asButton {
                                drugListEditorState.inProgressEdit.targetDrug = drug
                            }

                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(4)
                    .boringBorder
                }
            }.padding(.horizontal, 16.0)
        }
    }

    private var subviewEditor: some View {
        return VStack {
            HStack {
                Text("Name:")
                TextField.init(currentDrugName, text: inProgressEdit.updatedName)
            }
            HStack {
                Text("Dose time:")
                TextField.init(currentDrugName, text: inProgressEdit.updatedName)
            }
        }
        .padding()
        .background(Color(red: 0.8, green: 0.9, blue: 0.9))
    }
}

private extension DrugListEditorView {
    var currentDrugName: String {
        return drugListEditorState.inProgressEdit.targetDrug.drugName
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
        DrugListEditorView().environmentObject(makeTestMedicineOperator())
    }
}
#endif
