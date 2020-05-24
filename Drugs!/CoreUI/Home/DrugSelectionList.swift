import Foundation
import SwiftUI
import Combine

private extension AvailabilityInfo {
    func canTake(_ drug: Drug) -> Bool {
        return self[drug]?.canTake == true
    }
}

struct AutoCancel: ViewModifier {
    private static var nextId: Int = 0
    private static let getId: () -> Int = { nextId += 1; return nextId  }
    let id = getId()

    @State var cancellable: AnyCancellable? = nil
    let timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()
    let action: (Date) -> Void

    public init(_ with: @escaping (Date) -> Void) {
        self.action = with
    }

    func body(content: Content) -> some View {
        return content
            .onAppear {
                self.cancellable = self.timer.sink {
                    print("Refreshing view -> \(self.id)")
                    self.action($0)
                }
            }
            .onDisappear { self.cancellable?.cancel() }
    }
}

extension View {
    func refreshTimer(_ with: @escaping (Date) -> Void) -> some View {
        return modifier(AutoCancel(with))
    }
}


struct DrugSelectionListView: View {

    @EnvironmentObject var logOperator: MedicineLogOperator
    @Binding var inProgressEntry: InProgressEntry
    @Binding var currentSelectedDrug: Drug?
    @State var refreshDate: Date = Date()
    private let drugList = DefaultDrugList.shared.drugs

    var body: some View {
        let info = logOperator.coreAppState.mainEntryList.availabilityInfo(refreshDate)
        return ScrollView {
            ForEach(DefaultDrugList.shared.drugs, id: \.self) { drug in
                DrugEntryViewCell(
                    inProgressEntry: self.$inProgressEntry,
                    currentSelectedDrug: self.$currentSelectedDrug,
                    trackedDrug: drug,
                    canTake: info.canTake(drug)
                ).padding(4)
            }
        }.refreshTimer { self.refreshDate = $0 }
    }
}

#if DEBUG

struct DrugSelectionListView_Preview: PreviewProvider {
    static var previews: some View {
        Group {
            DrugSelectionListView(
                inProgressEntry: DefaultDrugList.$inProgressEntry,
                currentSelectedDrug: DefaultDrugList.drugBinding()
            ).environmentObject(makeTestMedicineOperator())
        }
    }
}

#endif
