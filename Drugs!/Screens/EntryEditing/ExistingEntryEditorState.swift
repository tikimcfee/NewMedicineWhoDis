import Foundation
import Combine
import UserNotifications

public final class ExistingEntryEditorState: ObservableObject {
    private let dataManager: MedicineLogDataManager
    private var cancellables = Set<AnyCancellable>()

    @Published var editorIsVisible: Bool = false
    @Published var editorError: AppStateError? = nil
    @Published var selectionModel = DrugSelectionContainerModel()

    var sourceEntry: MedicineEntry

    public init(dataManager: MedicineLogDataManager,
                sourceEntry: MedicineEntry) {
        self.dataManager = dataManager
        self.sourceEntry = sourceEntry
        self.selectionModel.inProgressEntry = sourceEntry.editableEntry

        dataManager.availabilityInfoStream
            .sink { [weak self] in self?.selectionModel.info = $0 }
            .store(in: &cancellables)

        dataManager.sharedDrugListStream
            .sink { [weak self] in self?.selectionModel.availableDrugs = $0 }
            .store(in: &cancellables)
    }

    func saveEdits(_ didComplete: @escaping Action) {
        guard selectionModel.inProgressEntry != sourceEntry else { return }

        var safeCopy = sourceEntry
        safeCopy.date = selectionModel.inProgressEntry.date
        do {
            safeCopy.drugsTaken = try selectionModel.inProgressEntry.drugMap(
                in: selectionModel.availableDrugs
            )
        } catch InProgressEntryError.mappingBackToDrugs {
            log { Event("Missing drug from known available map", .error) }
        } catch {
            log { Event("Unexpected error during drug map: \(error.localizedDescription)", .error) }
        }

        dataManager.updateEntry(updatedEntry: safeCopy) { [weak self] result in
            guard let self = self else { return }
            switch result {
                case .success:
                    self.sourceEntry = safeCopy
                    self.editorIsVisible = false
                    self.editorError = nil
                    self.updateExistingNotifications(safeCopy)
                    didComplete()

                case .failure(let error):
                    self.editorError = error as? AppStateError ?? .updateError
            }
        }
    }

    private func updateExistingNotifications(_ entry: MedicineEntry) {
        let notificationCenter = UNUserNotificationCenter.current()
        log { Event("Starting drug reminder update for: \(entry)") }
        notificationCenter.getPendingNotificationRequests { notifications in
            log { Event("Fetched notifications for update: \(notifications.count)") }

            let knownReminders: [
                (info: DrugNotificationUserInfo, request: UNNotificationRequest)
            ] = notifications.compactMap { request in
                guard let info = DrugNotificationUserInfo(request.content.userInfo)
                else { return nil }
                return (info, request)
            }

            entry.drugsTaken.keys.forEach { drug in
                guard let request = knownReminders.first(where: { $0.info.drugId == drug.id }) else {
                    log { Event("No request for: \(drug.drugName)") }
                    return
                }
                log { Event("Found matching request: \(request.info)") }
                notificationCenter.removePendingNotificationRequests(
                    withIdentifiers: [request.request.identifier]
                )
                let updatedRequest = drug.asNotificationRequest(entry.date)
                notificationCenter.add(updatedRequest) { error in
                    log { Event("Updated request: \(error?.localizedDescription ?? "success")") }
                }
            }
        }
    }
}
