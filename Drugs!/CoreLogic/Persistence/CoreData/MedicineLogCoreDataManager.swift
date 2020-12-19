import Foundation
import CoreData

class MedicineLogCoreDataManager {
    private static let containerName = "MedicineLog"

    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: Self.containerName)
        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
            log { Event("Loaded persistent CoreData store: \(storeDescription)") }
        }
        return container
    }()

    func saveContext() {
        let context = persistentContainer.viewContext
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            let nserror = error as NSError
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
    }
}
