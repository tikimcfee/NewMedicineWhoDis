import Foundation

public class MedicineLogFileStore {

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

    func load() -> Result<ApplicationData, Error> {
        // TODO: get rid of this, and load everything
        // asynchronously with lazies and yadda yadda
        let result = filestore.loadApplicationData()
        return result
    }
}
