import Foundation
import CoreData

public class MedicineLogCoreDataManager {
    private static let containerName = "EntryModels"
    
    private var container: NSPersistentContainer?
    
    func withContainer(_ action: @escaping (NSManagedObjectContext) -> Void) {
        container?.performBackgroundTask {
            action($0)
        }
    }
    
    // Blocking!
    func createContainer() {
        let semaphore = DispatchSemaphore(value: 0)
        let container = NSPersistentContainer(name: Self.containerName)
        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
            log { Event("Loaded persistent CoreData store: \(storeDescription)") }
            
            
            
            semaphore.signal()
        }
        self.container = container
        semaphore.wait()
    }

    func saveContext() {
        guard let context = container?.viewContext,
              context.hasChanges
        else {
            return
        }
        
        do {
            try context.save()
        } catch {
            let nserror = error as NSError
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
    }
}
