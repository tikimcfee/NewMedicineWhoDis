//
//  SceneDelegate.swift
//  Drugs!
//
//  Created by Ivan Lugo on 8/31/19.
//  Copyright © 2019 Ivan Lugo. All rights reserved.
//

import UIKit
import SwiftUI

public extension Result where Success == ApplicationData, Failure == Error {
    var applicationData: ApplicationData {
        if case .success(let appData) = self {
            return appData
        } else {
            return ApplicationData()
        }
    }
}

public enum AppTestArguments: String {
    case enableTestConfiguration
    case clearEntriesOnLaunch
    case disableAnimations

    var isSet: Bool { CommandLine.arguments.contains(rawValue) }
}

public class MasterEnvironmentContainer: ObservableObject {
    let fileStore: MedicineLogFileStore
    let dataManager: MedicineLogDataManager

    let notificationState: NotificationInfoViewState
    let notificationScheduler: NotificationScheduler

    let rootScreenState: AddEntryViewState

    init() {
        self.fileStore = MedicineLogFileStore()
        let appData = fileStore.load().applicationData
        self.dataManager = MedicineLogDataManager(
            persistenceManager: FilePersistenceManager(store: fileStore),
            appData: appData
        )
        self.notificationState = NotificationInfoViewState(dataManager)
        self.notificationScheduler = NotificationScheduler(notificationState: notificationState)
        self.rootScreenState = AddEntryViewState(dataManager, notificationScheduler)
    }

    public func makeNewDrugEditorState() -> DrugListEditorViewState {
        return DrugListEditorViewState(dataManager)
    }
}

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {

        AppLaunchThemingUtil.setGlobalThemes()

        if let windowScene = scene as? UIWindowScene {
            window = UIWindow(windowScene: windowScene)
            window!.overrideUserInterfaceStyle = .light
        }

        // Loads app data on init. Bad idea?
		let environmentContainer = MasterEnvironmentContainer()
        configureForTests(environmentContainer)

        let contentView = RootAppStartupView()
            .environmentObject(environmentContainer)
            .environmentObject(environmentContainer.dataManager)
            .environmentObject(environmentContainer.rootScreenState)
            .environmentObject(environmentContainer.notificationState)
            .onAppear {
                environmentContainer.notificationState.requestPermissions()
            }

        self.window?.rootViewController = UIHostingController(rootView: contentView)
        self.window?.makeKeyAndVisible()
    }

    private func configureForTests(_ container: MasterEnvironmentContainer) {
        guard AppTestArguments.enableTestConfiguration.isSet else { return }
        log { Event("Enabling test configuration. Ye have been warned.", .warning) }

        if AppTestArguments.clearEntriesOnLaunch.isSet {
//            TODO: fix tests!
//            container.dataManager.TEST_clearAllEntries()
        }

        if AppTestArguments.disableAnimations.isSet {
            UIView.setAnimationsEnabled(false)
        }
    }
}

extension SceneDelegate {
    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not neccessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }
}
