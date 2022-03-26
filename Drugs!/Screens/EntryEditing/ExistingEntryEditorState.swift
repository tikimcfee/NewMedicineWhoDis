import Foundation
import Combine
import UserNotifications
import RealmSwift
import SwiftUI

enum EditorError: String, Error {
    case realmNotAvailable
    case failedToCreateSelectionModel
    case modelDeleted
}

extension ExistingEntryEditorState: InfoReceiver {
    var selectionModelReceiver: ((inout DrugSelectionContainerModel) -> Void) -> () {
        return { receiver in
            receiver(&self.selectionModel)
        }
    }
}

public final class ExistingEntryEditorState: ObservableObject {
    @Published var editorError: AppStateError? = nil
    @Published var selectionModel = DrugSelectionContainerModel()
    @ObservedRealmObject public var targetModel: RLM_MedicineEntry
    
    lazy var calculator = AvailabilityInfoCalculator(receiver: self)
    private var bag = Set<AnyCancellable>()
    private var tokens = Set<NotificationToken>()
    
    public init(_ unsafeTarget: RLM_MedicineEntry) {
        self.targetModel = unsafeTarget
        calculator.bindModel(unsafeTarget)
        setInitialProgressEntry()
    }
    
    private func setInitialProgressEntry() {
        log("Setting initial entry: \(targetModel.id)")
        selectionModel.inProgressEntry = Self.buildInitialEntry(targetModel)
    }
    
    private static func buildInitialEntry(
        _ entry: RLM_MedicineEntry
    ) -> InProgressEntry {
        return InProgressEntry(
            entry.drugsTaken.reduce(into: InProgressDrugCountMap()) { result, selection in
                guard let drug = selection.drug else { return }
                let selectableDrug = SelectableDrug(
                    drugName: drug.name,
                    drugId: drug.id
                )
                result[selectableDrug] = selection.count
            },
            entry.date
        )
    }

    func saveEdits(_ didComplete: @escaping Action) {
        editorError = AppStateError.notImplemented()
        
        guard
            let thawedEntry = targetModel.thaw(),
            let thawedRealm = targetModel.realm?.thaw()
        else {
            log("Unable to retrieve editing model to save changes")
            return
        }

        do {
            let migrator = V1Migrator()
            let newMap = try selectionModel.inProgressEntry
                .drugMap(in: selectionModel.availableDrugs)
            let newSelection = migrator.fromV1DrugMap(newMap)

            try thawedRealm.write(withoutNotifying: Array(calculator.realmTokens)) {
                newSelection.forEach { thawedRealm.add($0.drug!, update: .modified) }
                thawedEntry.drugsTaken.removeAll()
                thawedEntry.drugsTaken.insert(contentsOf: newSelection, at: 0)
                thawedEntry.date = selectionModel.inProgressEntry.date
            }
            
            updateExistingNotifications(targetModel)
            editorError = nil

            didComplete()
        } catch InProgressEntryError.mappingBackToDrugs {
            let error = AppStateError.generic(message: "Missing drug during save mapping.")
            log(error)
            editorError = error
        } catch {
            log(error, "Failed to write entry updates")
            editorError = error as? AppStateError ?? AppStateError.updateError
        }
    }

    private func updateExistingNotifications(_ source: RLM_MedicineEntry) {
        let entry = V1Migrator().toV1Entry(source)
        
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
