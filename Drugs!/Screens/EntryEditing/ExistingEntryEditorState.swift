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
    
    private static func buildInitialEntry(_ entry: RLM_MedicineEntry) -> InProgressEntry {
        InProgressEntry(
            entry.drugsTaken.reduce(into: InProgressDrugCountMap()) { result, savedSelection in
                guard let drug = savedSelection.drug else { return }
                let selectableDrug = SelectableDrug(
                    drugName: drug.name,
                    drugId: drug.id,
                    updateCount: { newCount in
                        log("-- Intial entry auto update for \(drug.id)")
                        entry.autoUpdateCount(on: drug.id, newCount) }
                )
                result[selectableDrug] = savedSelection.count
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

            try thawedRealm.write(withoutNotifying: calculator.realmTokens) {
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

extension RLM_MedicineEntry {
    func autoUpdateCount(
        on target: Drug.ID,
        _ count: Double?,
        _ skip: [NotificationToken] = []
    ) {
        do {
            guard let thawedRealm = realm?.thaw() else {
                throw EditorError.realmNotAvailable
            }
            try thawedRealm.write(withoutNotifying: skip) {
                try _autoUpdateCountInternal(realm: thawedRealm, target, count)
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
