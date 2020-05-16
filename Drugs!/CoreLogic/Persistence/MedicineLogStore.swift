import Foundation

public class MedicineLogStore {

    private let filestore = FileStore()

    func save(appState: AppState, _ handler: (Result<Void, Error>) -> Void) {
        if let error = filestore.saveAppState(appState) {
            handler(.failure(error))
        } else {
            handler(.success(()))
        }
    }

    func load(_ handler: (Result<AppState, Error>) -> Void) {
        let result = filestore.loadAppState()
        handler(result)
    }

    func load() -> Result<AppState, Error> {
        // TODO: get rid of this, and load everything
        // asynchronously with lazies and yadda yadda
        let result = filestore.loadAppState()
        return result
    }
}
