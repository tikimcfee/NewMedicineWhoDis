//
//  DrugListEditorView.swift
//  Drugs!
//
//  Created by Ivan Lugo on 6/7/20.
//  Copyright © 2020 Ivan Lugo. All rights reserved.
//

import SwiftUI
import RealmSwift

struct DrugListEditorView: View {

    @ObservedResults(RLM_AvailableDrugList.self) var results
    @EnvironmentObject var editorState: DrugListEditorViewState
    @State private var focusedDrug: RLM_Drug? = nil

    var body: some View {
        return VStack(spacing: 0) {
            subviewDrugList.boringBorder.padding(8).zIndex(99)
            subviewEditor
        }
        .navigationBarItems(trailing: modeSwitchControls)
        .alert(item: $editorState.deleteTargetItem) { target in
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
                buttonForMode(mode)
                    .disabled(editorState.currentMode == mode)
            }
        }
    }

    private func buttonForMode(_ mode: EditMode) -> some View {
        Button(action: {
            withAnimation { editorState.currentMode = mode }
        }, label: {
            HStack {
                mode.image.foregroundColor(mode.color)
                Text(mode.description)
            }.padding(4).boringBorder
        })
   }

    private var subviewDrugList: some View {
        ForEach(results) { drugList in
            ScrollView {
                VStack{
                    ForEach(Array(drugList.drugs.sorted(by: \.name)), id: \.id) { drug in
                        HStack{
                            textGroup(drug)
                            HStack { Divider() }
                            if editorState.currentMode != .add {
                                rowButtonForCurrentMode(drug)
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

    func rowButtonForCurrentMode(_ drug: RLM_Drug) -> some View {
        let mode = editorState.currentMode
        return mode
            .image
            .foregroundColor(mode.color)
            .padding(8)
            .boringBorder
            .asButton { withAnimation(.easeInOut) {
                switch mode {
                case .edit:
                    editorState.focusedDrug = drug
                    editorState.deleteTargetItem = nil
                case .delete:
                    editorState.focusedDrug = nil
                    editorState.deleteTargetItem = drug
                case .add:
                    editorState.focusedDrug = nil
                    editorState.deleteTargetItem = nil
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
        QuickEditView(rootState: editorState)
    }
}

struct QuickEditView: View {
    @ObservedObject var rootState: DrugListEditorViewState
    
    @ViewBuilder
    var body: some View {
        switch rootState.currentMode {
        case .add:
            editingBoxWithSave("Enter new drug name", "Save") {
                rootState.saveChanges()
            }
        case .edit:
            editingBoxWithSave("Edit drug: \(rootState.focusedDrug?.name ?? "<error>")", "Save") {
                rootState.saveChanges()
            }
        case .delete:
            EmptyView()
        }
    }
    
    @ViewBuilder
    private func editingBoxWithSave(_ initialText: String,
                                    _ buttonTitle: String,
                                    _ action: @escaping () -> Void) -> some View {
        editingBox()
        Components.fullWidthButton(buttonTitle) {
            withAnimation { action() }
        }
        .onSubmit { if rootState.isSaveEnabled { action() }}
        .disabled(!rootState.isSaveEnabled)
        .boringBorder
    }
    
    @ViewBuilder
    private func editingBox() -> some View {
        HStack {
            TextField(
                "Enter a name",
                text: $rootState.currentName
            )
            .padding()
            .frame(minHeight: 64, maxHeight: 64, alignment: .center)
            .boringBorder
            Picker(selection: $rootState.currentTime, label: EmptyView()) {
                ForEach((0..<25)) { hour in
                    Text("\("hour".simplePlural(hour, "Any time"))").tag(Double(hour))
                }
            }.frame(maxWidth: 128, maxHeight: 64).clipped().boringBorder
        }
    }
}

#if DEBUG
struct DrugListEditorView_Previews: PreviewProvider {
    static var previews: some View {
        let dataManager = DefaultRealmManager()
        
        return NavigationView {
            DrugListEditorView()
                .modifier(dataManager.makeModifier())
                .environmentObject(DrugListEditorViewState())
                .navigationBarTitle(Text("Test Navigation"), displayMode: .inline)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}
#endif
