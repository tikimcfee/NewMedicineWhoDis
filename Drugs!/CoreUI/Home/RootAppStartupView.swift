//
//  ContentView.swift
//  Drugs!
//
//  Created by Ivan Lugo on 8/31/19.
//  Copyright © 2019 Ivan Lugo. All rights reserved.
//

import SwiftUI

// Statically used
private let dateFormatter: DateFormatter = {
    let dateFormatter = DateFormatter()
    dateFormatter.dateStyle = .none
    dateFormatter.timeStyle = .medium
    return dateFormatter
}() // <--- ok so we're defining and then, at runtime, executing the function to create the formatter. Ok, cheeky.

private let dateFormatterSmall: DateFormatter = {
    let dateFormatter = DateFormatter()
    dateFormatter.timeStyle = .short
    return dateFormatter
}()

// ---------------------------------------------------
// Core UI Structure
// ---------------------------------------------------
struct RootAppStartupView: View {
    
    private var coreOperator : MedicineLogOperator = __testData__coreMedicineOperator

    // Main view
    var body: some View {
        NavigationView {
            RootDrugView(coreOperator: coreOperator)
                .navigationBarTitle(Text("When did I..."))
//                .navigationBarItems(
//                    leading: createEditButton(),
//                    trailing: createTrailingAddButton()
//                )
            DetailView()
        }.navigationViewStyle(DoubleColumnNavigationViewStyle())
    }
    
    // Edit button
    func createEditButton() -> some View {
        return EditButton()
    }
    
//    // Add button
//    func createTrailingAddButton() -> some View {
//        return Button (
//            action: { withAnimation { self.doAdd } }
//        ) {
//            Image(systemName: "plus")
//        }.frame(width: 44.0, height: 44.0, alignment: .center)
//    }
    
//    var doAdd: () {
//        self.coreOperator.addEntry(medicineEntry: self.createNewEntry())
//    }
//
//    func createNewEntry() -> MedicineEntry {
//        return MedicineEntry(date: Date(), drugsTaken: [])
//    }
}

struct RootDrugView: View {
    @ObservedObject var coreOperator: MedicineLogOperator
    let drugEntryView: DrugEntryView = DrugEntryView()

    var body: some View {
        VStack {
            List {
                ForEach(coreOperator.currentEntries, id: \.self) { entry in
                    self.makeNavigationLink(medicineEntry: entry)
                }.onDelete { indices in
                    indices.forEach { index in
                        let id = self.coreOperator.currentEntries[index].randomId
                        self.coreOperator.removeEntry(id: id)
                    }
                }
            }.frame(maxHeight: 440.0)
            
            self.drugEntryView
            
            makeSaveButton()
        }
    }
    
    func makeNavigationLink(medicineEntry: MedicineEntry) -> some View {
        return RootDrugMedicineCell(medicineEntry: medicineEntry)
    }
    
    func makeSaveButton() -> some View {
        return Button(
            action: saveTapped
        ) {
            Text("Take some drugs")
                .foregroundColor(Color.white)
                .padding(8.0)
                .frame(maxWidth: UIScreen.main.bounds.width - 8.0)
                .background(
                    Rectangle()
                        .cornerRadius(4.0)
                        .foregroundColor(Color.init(red: 0.4, green: 0.8, blue: 0.9))
                )
        }.padding(8.0)
    }
    
    private func saveTapped() {
        self.drugEntryView.saveAndClear { drugMap in
            let hasEntries = drugMap.count > 0
            let hasNonZeroEntries = drugMap.values.allSatisfy { $0 > 0 }
            guard hasEntries && hasNonZeroEntries else {
                print("Skipping entry save: hasEntries=\(hasEntries), hasNonZeroEntries=\(hasNonZeroEntries)")
                return .error(clear: false)
            }
            
            self.coreOperator.addEntry(medicineEntry: self.createNewEntry(with: drugMap))
            return .saved(clear: true)
        }
    }
        
    func createNewEntry(with map: [Drug:Int]) -> MedicineEntry {
        return MedicineEntry(date: Date(), drugsTaken: map)
    }
}

struct RootDrugMedicineCell: View {
    let medicineEntry: MedicineEntry
    
    var body: some View {
        NavigationLink(
            destination: DetailView(medicineEntry: medicineEntry)
        ) {
            VStack(alignment: .leading) {
                Text("\(medicineEntry.drugList)")
                    .fontWeight(.semibold)
                
                Text("\(medicineEntry.date, formatter: dateFormatter)")
                    .fontWeight(.ultraLight)
            }
        }
    }
}

struct DetailEntryModel: Identifiable, Storable {
    var id = UUID()
    let drugName: String
    let timeForNextDose: String
    let canTakeAgain: Bool
}

struct DetailEntryModelCell: View {
    let model: DetailEntryModel
    let fromEntry: MedicineEntry
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(model.drugName)
                if model.canTakeAgain {
                    Image(systemName: "checkmark.circle.fill").foregroundColor(Color.green)
                } else {
                    Image(systemName: "multiply.circle").foregroundColor(Color.red)
                }
            }
            Text(model.timeForNextDose)
        }.padding(4.0)
    }
    
}

struct DetailView: View {
    var medicineEntry: MedicineEntry?

    var body: some View {
        let now = Date()
        let data: [DetailEntryModel] = medicineEntry?.timesDrugsAreNextAvailable.compactMap { keyPair in
            DetailEntryModel(
                drugName: keyPair.key.drugName,
                timeForNextDose: "Take again at \(dateFormatterSmall.string(from: keyPair.value))",
                canTakeAgain: now >= keyPair.value
            )
        } ?? []
        
        return VStack(alignment: .leading) {
            Text("\(Date(), formatter: dateFormatter)")
            ForEach(data, id: \.self) { item in
                DetailEntryModelCell(model: item, fromEntry: self.medicineEntry!)
            }
        }.navigationBarTitle(Text("Detail"))
    }
}

#if DEBUG

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
//            RootAppStartupView()
            DetailView(
                medicineEntry: __testData__anEntry
            )
        }
    }
}

#endif
