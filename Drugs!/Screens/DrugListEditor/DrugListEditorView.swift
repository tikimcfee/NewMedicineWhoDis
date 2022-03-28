//
//  DrugListEditorView.swift
//  Drugs!
//
//  Created by Ivan Lugo on 6/7/20.
//  Copyright © 2020 Ivan Lugo. All rights reserved.
//

import SwiftUI
import RealmSwift

enum EditMode: Int, CustomStringConvertible, CaseIterable {
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

    @ObservedResults(RLM_AvailableDrugList.self) var results
    @EnvironmentObject var drugListEditorState: DrugListEditorViewState

    var body: some View {
        return VStack(spacing: 0) {
            subviewDrugList.boringBorder.padding(8).zIndex(99)
            subviewEditor
        }
        .navigationBarItems(trailing: modeSwitchControls)
        .alert(item: $drugListEditorState.deleteTargetItem) { target in
            Alert(
                title: Text("Delete '\(target.name)' from medicines?"),
                primaryButton: .destructive(Text("Delete it")) {
                    guard let thawedTarget = target.thaw(),
                          let thawedResults = results.first?.thaw(),
                          let removalIndex = thawedResults.drugs.firstIndex(of: thawedTarget),
                          let realm = thawedTarget.realm else {
                        log(EditorError.missingDrugThaw)
                        return
                    }
                    
                    try? realm.write {
                        thawedResults.drugs.remove(at: removalIndex)
                        log("-- Removed drug from list")
                    }
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
                    .disabled(self.drugListEditorState.currentMode == mode)
            }
        }
    }

    private func buttonForMode(_ mode: EditMode) -> some View {
        Button(action: { withAnimation {
            self.drugListEditorState.currentMode = mode
        }}) {
            HStack {
                mode.image.foregroundColor(mode.color)
                Text(mode.description)
            }
            .padding(4).boringBorder
        }
    }

    @ViewBuilder
    private var subviewDrugList: some View {
        if results.isEmpty {
            EmptyView()
        } else {
            ForEach(results) { drugList in
                ScrollView {
                    VStack{
                        ForEach(Array(drugList.drugs.sorted(by: \.name)), id: \.id) { drug in
                            HStack{
                                self.textGroup(drug)
                                HStack{ Divider() }
                                if self.drugListEditorState.currentMode != .add {
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
        }
    }

    func rowButtonForCurrentMode(_ drug: RLM_Drug) -> some View {
        let mode = drugListEditorState.currentMode
        return mode
            .image
            .foregroundColor(mode.color)
            .padding(8)
            .boringBorder
            .asButton { withAnimation(.easeInOut) {
                switch mode {
                case .add:
                    // Shouldn't see the add button here.. woot, bad architecture design!
                    break
                case .edit:
                    drugListEditorState.inProgressEdit.setTarget(drug: drug)
                case .delete:
                    drugListEditorState.deleteTargetItem = drug
                }
            }}
    }

    private func textGroup(_ drug: RLM_Drug) -> some View {
        return HStack(alignment: .center) {
            VStack(alignment: .leading) {
                Text(drug.name)
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
        return editingBox(currentDrugName)
    }

    private var addModeView: some View {
        return editingBoxWithSave("Enter new drug name", "Save") {
            self.drugListEditorState.saveAsNew()
        }
    }

    @ViewBuilder
    private func editingBoxWithSave(_ initialText: String,
                                    _ buttonTitle: String,
                                    _ action: @escaping () -> Void) -> some View {
        editingBox(initialText)
        Components.fullWidthButton(buttonTitle) {
            withAnimation { action() }
        }
        .disabled(!drugListEditorState.inProgressEdit.isNewSaveEnabled)
        .boringBorder
    }
    
    @ViewBuilder
    private func editingBox(_ initialText: String) -> some View {
        HStack {
            TextField(
                initialText,
                text: $drugListEditorState.inProgressEdit.drugName
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
    }
}

private extension DrugListEditorView {
    var currentDrugName: String {
        return drugListEditorState.inProgressEdit.drugName
    }
    
    var currentMode: EditMode {
        return drugListEditorState.currentMode
    }
}

#if DEBUG
struct DrugListEditorView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            DrugListEditorView().environmentObject(
                DrugListEditorViewState()
            ).navigationBarTitle(
                Text("Test Navigation"),
                displayMode: .inline
            )
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}
#endif
