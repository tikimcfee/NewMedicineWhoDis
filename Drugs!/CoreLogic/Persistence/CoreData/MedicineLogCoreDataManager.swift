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
    private func wipe(_ coordinator: NSPersistentStoreCoordinator, _ url: URL) throws {
        try coordinator.destroyPersistentStore(at: url, ofType: NSSQLiteStoreType, options: nil)
        try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: nil)
    }
    
    public func clearAllContainers() {
        let descriptionUrls = loadedPersistentContainer?
            .persistentStoreDescriptions
            .compactMap { $0.url } ?? []
        
        guard
            let persistentStoreCoordinator = loadedPersistentContainer?.persistentStoreCoordinator,
            descriptionUrls.count > 0
        else {
            log { Event("Missing store coordinator or URL", .error) }
            return
        }
        
        for url in descriptionUrls {
            do {
                try wipe(persistentStoreCoordinator, url)
                log { Event("Container reset: " + url.absoluteString, .info) }
            } catch {
                log { Event("Attempted to clear persistent store: " + error.localizedDescription, .error) }
            }
        }
    }
    #endif
}

struct CoreDataMirror {
    private let context: NSManagedObjectContext
    
    static func of(_ context: NSManagedObjectContext) -> CoreDataMirror {
        CoreDataMirror(context: context)
    }
    
    func fetchOne<T: NSManagedObject>(
        _ type: T.Type,
        _ modifiers: ((NSFetchRequest<T>) -> Void)? = nil
    ) throws -> T? {
        let entityName = String(describing: type)
        let fetchRequest = NSFetchRequest<T>(entityName: entityName)
        modifiers?(fetchRequest)
        do {
            let fetchResult = try context.fetch(fetchRequest)
            let firstResult = fetchResult.first
            return firstResult
        } catch {
            throw CoreDataManagerError.fetchFailed(error as NSError)
        }
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

enum CoreDataManagerError: Error {
    case noEntityDescription(named: String)
    case invalidClass(query: String, actual: String)
    case saveFailed(NSError)
    case fetchFailed(NSError)
}
