import Foundation

public class FilePersistenceManager: PersistenceManager {

    private let medicineStore: MedicineLogFileStore

    private let mainQueue = DispatchQueue.main
    private let saveQueue = DispatchQueue.init(label: "MedicineLogOperator-Queue",
                                               qos: .userInteractive)

    init(store: MedicineLogFileStore) {
        self.medicineStore = store
    }

    func perform(operation: PersistenceOperation,
                 with appContext: ApplicationData,
                 _ handler: @escaping PersistenceCallback) {
        saveQueue.async {
            self.medicineStore.save(applicationData: appContext) { result in
                self.mainQueue.async {
                    handler(result)
                }
            }
        }
    }
}
