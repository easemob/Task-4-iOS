//
//  AppDelegate.swift
//  mqtt
//
//  Created by jailbreak2020 on 2021/8/24.
//

import UIKit
import HyphenateChat
import CoreData

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var persistentContainer: NSPersistentContainer!
    var viewContext: NSManagedObjectContext!

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // loaddata
        persistentContainer = NSPersistentContainer(name: "mqtt")
        persistentContainer.loadPersistentStores { description, error in
            if let error = error {
                fatalError("failed to load core data stack: \(error)")
            }
            debugPrint(description)
        }
        viewContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        viewContext.persistentStoreCoordinator = persistentContainer.persistentStoreCoordinator
        
        // Override point for customization after application launch.
        let options = EMOptions(appkey: MqttOptions.appKey)
        options?.isAutoLogin = true
        EMClient.shared().initializeSDK(with: options)
        
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }    
}

