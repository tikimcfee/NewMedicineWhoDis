//
//  DrugListEditorView.swift
//  Drugs!
//
//  Created by Ivan Lugo on 6/7/20.
//  Copyright © 2020 Ivan Lugo. All rights reserved.
//

import SwiftUI

private enum EditMode: Int, CustomStringConvertible, CaseIterable {
    case add, delete, edit
    var description: String {
        switch self {
        case .add: return "New drug"
        case .delete: return "Delete"
        case .edit: return "Edit"
        }
    }
    var color: Color {
        switch self {
        case .add: return Color.green
        case .delete: return Color.red
        case .edit: return Color.primary
        }
    }
    var image: some View {
        switch self {
        case .add:
            return Image(systemName: "plus.circle.fill")
        case .edit:
            return Image(systemName: "pencil")
        case .delete:
            return Image(systemName: "minus.circle.fill")
        }
    }
}

struct DrugListEditorView: View {

    @EnvironmentObject var drugListEditorState: DrugListEditorViewState
    @State private var currentMode: EditMode = .edit {
        didSet {
            drugListEditorState.inProgressEdit.startEditingNewDrug()
        }
    }
    @State private var deleteTargetItem: Drug? = nil

    var body: some View {
        return VStack(spacing: 0) {
            subviewDrugList.boringBorder.padding(8).zIndex(99)
            subviewEditor
        }
        .navigationBarItems(trailing: modeSwitchControls)
        .alert(item: $deleteTargetItem) { target in
            Alert(
                title: Text("Delete '\(target.drugName)' from medicines?"),
                primaryButton: .destructive(Text("Delete it")) {
                    self.drugListEditorState.deleteDrug(target)
                },
                secondaryButton: .default(Text("Cancel"))
            )
        }
    }

    private var modeSwitchControls: some View {
        HStack {
            Spacer()
            ForEach(EditMode.allCases, id: \.rawValue) { mode in
                self.buttonForMode(mode)
                    .disabled(self.currentMode == mode)
            }
        }
    }

    private func buttonForMode(_ mode: EditMode) -> some View {
        Button(action: { withAnimation {
            self.currentMode = mode
        }}) {
            HStack {
                mode.image.foregroundColor(mode.color)
                Text(mode.description)
            }
            .padding(4).boringBorder
        }
    }

    private var subviewDrugList: some View {
        return ScrollView {
            VStack{
                ForEach(drugList, id: \.self) { drug in
                    HStack{
                        self.textGroup(drug)
                        HStack{ Divider() }
                        if self.currentMode != .add {
                            self.rowButtonForCurrentMode(drug)
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: 44.0, alignment: .trailing)
                    .padding(4)
                    .boringBorder
                    .padding(.horizontal, 8)
                }
            }.padding(.vertical, 8.0)
        }
    }

    func rowButtonForCurrentMode(_ drug: Drug) -> some View {
        currentMode
            .image.foregroundColor(currentMode.color)
            .padding(8)
            .boringBorder
            .asButton { withAnimation(.easeInOut) {
                switch self.currentMode {
                case .add:
                    // Shouldn't see the add button here.. woot, bad architecture design!
                    break
                case .edit:
                    self.drugListEditorState.inProgressEdit.setTarget(drug: drug)
                case .delete:
                    self.deleteTargetItem = drug
                }
            }}
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
        return VStack(spacing: 0) {
            if currentMode == .edit {
                editModeView
                    .padding(8)
                    .background(Color(red: 0.8, green: 0.9, blue: 0.9))
            } else if currentMode == .add {
                addModeView
                    .padding(8)
                    .background(Color(red: 0.8, green: 0.9, blue: 0.9))
            }
        }
    }

    private var editModeView: some View {
        return editingBottomView(currentDrugName, "Save Changes",
                                 drugListEditorState.canSaveAsEdit) {
            self.drugListEditorState.saveAsEdit()
        }
    }

    private var addModeView: some View {
        return editingBottomView("Enter new drug name", "Save",
                                 drugListEditorState.canSaveAsNew) {
            self.drugListEditorState.saveAsNew()
        }
    }

    private func editingBottomView(_ initialText: String,
                                   _ buttonTitle: String,
                                   _ isEnabled: Bool,
                                   _ action: @escaping () -> Void) -> some View {
        return Group {
            HStack {
                TextField(
                    initialText,
                    text: inProgressEdit.drugName
                )
                    .padding()
                    .frame(minHeight: 64, maxHeight: 64, alignment: .center)
                    .boringBorder
                Picker(selection: $drugListEditorState.inProgressEdit.doseTime, label: EmptyView()) {
                    ForEach((0..<25)) { hour in
                        Text("\("hour".simplePlural(hour, "Any time"))").tag(hour)
                    }
                }.frame(maxWidth: 128, maxHeight: 64).clipped().boringBorder
            }

            Components.fullWidthButton(buttonTitle) {
                withAnimation { action() }
            }
            .disabled(!isEnabled)
            .boringBorder
        }
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
        NavigationView {
            DrugListEditorView().environmentObject(
                DrugListEditorViewState(makeTestMedicineOperator())
            ).navigationBarTitle(
                Text("Test Navigation"),
                displayMode: .inline
            )
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}
#endif
