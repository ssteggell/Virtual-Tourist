//
//  AppDelegate.swift
//  Virtual Tourist
//
//  Created by Spencer Steggell on 5/14/20.
//  Copyright © 2020 Spencer Steggell. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {



    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
//    func checkIfFirstLaunch() {
//        if UserDefaults.standard.bool(forKey: "hasLaunchedBefore") {
//            print("App has launched before")
//        } else {
//            print("This is the first launch ever!")
//            UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
//            UserDefaults.standard.set(false, forKey: "kMapRegion")
//            UserDefaults.standard.synchronize()
//        }
//    }
    
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        saveViewContext()
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
    saveViewContext()
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    func saveViewContext () {
         CoreDataStack.saveContext()
    }


}

