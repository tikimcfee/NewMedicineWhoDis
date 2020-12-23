import Foundation

public class EntryListFileStore {

    private let filestore = FileStore()

    func save(applicationData: ApplicationData, _ handler: (Result<Void, Error>) -> Void) {
        if let error = filestore.saveApplicationData(applicationData) {
            handler(.failure(error))
        } else {
            handler(.success(()))
        }
    }

    func load(_ handler: (Result<ApplicationData, Error>) -> Void) {
        let result = filestore.loadApplicationData()
        handler(result)
    }

    // Useful for testing
    func load() -> Result<ApplicationData, Error> {
        let result = filestore.loadApplicationData()
        return result
    }
}
