import Foundation
import CoreData

public class MedicineLogCoreDataManager {
    
    typealias CoreContextAction = (
        _ coreDataMirror: CoreDataMirror
    ) -> Void
    
    private static let containerName = "EntryModels"
    
    private var loadedPersistentContainer: NSPersistentContainer?
    
    func mirror(_ action: @escaping CoreContextAction) {
        loadedPersistentContainer.map {
            action(CoreDataMirror.of($0.viewContext))
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
        self.loadedPersistentContainer = container
        semaphore.wait()
    }
    
    #if DEBUG
    public func clearFirstContainer() {
        guard
            let persistentStoreCoordinator = loadedPersistentContainer?.persistentStoreCoordinator,
            let url = loadedPersistentContainer?.persistentStoreDescriptions.first?.url
        else {
            log { Event("Missing store coordinator or URL", .error) }
            return
        }

        do {
            try persistentStoreCoordinator.destroyPersistentStore(
                at:url, ofType: NSSQLiteStoreType, options: nil)
            try persistentStoreCoordinator.addPersistentStore(
                ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: nil)
            log { Event("Container reset: " + url.absoluteString, .info) }
        } catch {
            log { Event("Attempted to clear persistent store: " + error.localizedDescription, .error) }
        }
    }
    #endif
}

struct CoreDataMirror {
    private let context: NSManagedObjectContext
    
    static func of(_ context: NSManagedObjectContext) -> CoreDataMirror {
        CoreDataMirror(context: context)
    }
    
    func insertNew<T: NSManagedObject>(of type: T.Type) throws -> T {
        let entityName = String(describing: type)
        
        guard let entityDescription = NSEntityDescription.entity(
            forEntityName: entityName,
            in: context
        ) else { throw CoreDataManagerError.noEntityDescription(named: entityName) }
        
        let newObject = T(entity: entityDescription, insertInto: context)
        
        return newObject
    }
    
    func save() throws {
        guard context.hasChanges else { return }

        do {
            try context.save()
        } catch {
            throw CoreDataManagerError.saveFailed(error as NSError)
        }
    }
}

extension CoreDataMirror {
    func insertNew<T: NSManagedObject>(
        of type: T.Type,
        _ action: (Result<T, NSError>) -> Void
    ) {
        do {
            let newValue = try insertNew(of: type)
            action(.success(newValue))
        } catch {
            action(.failure(error as NSError))
        }
    }
    
    func save(_ action: (Result<Void, NSError>) -> Void) {
        do {
            try save()
            action(.success(()))
        } catch {
            action(.failure(error as NSError))
        }
    }
}

enum CoreDataManagerError: Error {
    case noEntityDescription(named: String)
    case invalidClass(query: String, actual: String)
    case saveFailed(NSError)
}
