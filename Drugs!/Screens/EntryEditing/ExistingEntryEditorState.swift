import Foundation
import Combine
import UserNotifications
import RealmSwift
import SwiftUI

enum EditorError: String, Error {
    case realmNotAvailable
    case failedToCreateSelectionModel
    case modelDeleted
    case autoUpdateCancelled
    case missingDrugThaw
    case missingDrugDuringAutoUpdate
    case noIndexNoCount
}

public final class ExistingEntryEditorState: ObservableObject {
    @Published var editorError: AppStateError? = nil
    @Published var selectionModel = DrugSelectionContainerModel()
    @Published var selectedDate = Date()
    @ObservedRealmObject public var targetModel: RLM_MedicineEntry
    
    private var bag = Set<AnyCancellable>()
    private var tokens = Set<NotificationToken>()
    
    init(_ unsafeTarget: RLM_MedicineEntry) {
        self.targetModel = unsafeTarget
        self.selectedDate = unsafeTarget.date
        
        setInitialProgressEntry()
    }
    
    deinit {
        log("Editor state cleaning up for \(targetModel.id)")
    }
    
    private func setInitialProgressEntry() {
        log("Setting initial entry: \(targetModel.id)")
        selectionModel.entryMap = buildInitialEntry(targetModel)
    }
    
    private func buildInitialEntry(_ entry: RLM_MedicineEntry) -> [SelectableDrug: Double] {
        return entry.drugsTaken.reduce(into: [:]) { result, savedSelection in
            guard let drug = savedSelection.drug else { return }
            let selectableDrug = SelectableDrug(
                drugName: drug.name,
                drugId: drug.id,
                selectedCountAutoUpdate: { [weak self] newCount in
                    self?.onAutoUpdate(on: drug.id, count: newCount)
                }
            )
            result[selectableDrug] = savedSelection.count
        }
    }
    
    func onAutoUpdate(on drugId: Drug.ID, count: Double?) {
        guard let entry = targetModel.thaw(), let realm = entry.realm?.thaw() else {
            log(EditorError.autoUpdateCancelled)
            return
        }
        log("Starting auto update")
        entry.autoUpdateCount(on: drugId, in: realm, count)
        let frozen = entry.freeze()
        DispatchQueue.global().async {
            self.updateExistingNotifications(frozen)
        }
    }

    func saveEdits(
        _ calculator: AvailabilityInfoCalculator,
        _ didComplete: @escaping Action
    ) {
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
            let newMap = try selectionModel.drugMap(in: selectionModel.availableDrugs)
            let newSelection = migrator.fromV1DrugMap(newMap)

            try thawedRealm.write(withoutNotifying: calculator.realmTokens) {
                newSelection.forEach { thawedRealm.add($0.drug!, update: .modified) }
                thawedEntry.drugsTaken.removeAll()
                thawedEntry.drugsTaken.insert(contentsOf: newSelection, at: 0)
                thawedEntry.date = selectedDate
            }
            
            updateExistingNotifications(targetModel)
            editorError = nil

            didComplete()
        } catch SelectionError.drugMappingError {
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
            log { Event("Fetched notifications for update: \(entry.drugsTaken.count)-:-\(notifications.count)") }

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

extension RLM_MedicineEntry {
    func autoUpdateCount(
        on target: Drug.ID,
        in realm: Realm,
        _ count: Double?,
        _ skip: [NotificationToken] = []
    ) {
        do {
            try realm.write(withoutNotifying: skip) {
                try self._autoUpdateCountInternal(realm: realm, target, count)
            }
        } catch { log(error) }
    }
    
    private func _autoUpdateCountInternal(
        realm: Realm,
        _ target: Drug.ID,
        _ count: Double?
    ) throws {
        guard let drugsTaken = thaw()?.drugsTaken else {
            throw EditorError.missingDrugThaw
        }
        
        guard let drug = realm.object(ofType: RLM_Drug.self, forPrimaryKey: target) else {
            throw EditorError.missingDrugDuringAutoUpdate
        }
        
        let maybeExistingIndex = drugsTaken.firstIndex(where: { $0.drug?.id == target }) ?? -1
        let maybeExistingSelection = drugsTaken.indices.contains(maybeExistingIndex)
            ? drugsTaken[maybeExistingIndex].thaw()
            : nil
        
        switch (maybeExistingSelection, count) {
        case let (.some(existing), .some(updatedCount)):
            // update case, have entry and new count
            existing.count = updatedCount
            
        case (.some, .none):
            // removal case, no count
            drugsTaken.remove(at: maybeExistingIndex)
            
        case let (.none, .some(updatedCount)):
            // new selection case, first count
            let newSelection = RLM_DrugSelection()
            newSelection.drug = drug
            newSelection.count = updatedCount
            drugsTaken.insert(newSelection, at: 0)
            
        case (.none, .none):
            // no index and no count is essentially an error state;
            // can't remove drugs that we don't know of
            log(EditorError.noIndexNoCount)
            break
        }
    }
}
