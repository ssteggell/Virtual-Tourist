//
//  CoreDataStack.swift
//  Virtual Tourist
//
//  Created by Spencer Steggell on 5/20/20.
//  Copyright © 2020 Spencer Steggell. All rights reserved.
//

import Foundation
import CoreData


class DataController {
    
    static let shared = DataController(modelName: "VirtualTourist")
    let modelName: String
    
    init(modelName:String) {
        self.modelName = modelName
    }
    
    lazy var viewContext: NSManagedObjectContext = {
        return persistentContainer.viewContext
    }()
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "VirtualTourist")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
    
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    
    
    func save() {
          let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
               fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    

}
    /*
        private init(){}

        class func getContext() -> NSManagedObjectContext {
            return CoreDataStack.persistentContainer.viewContext
        }
    
    
        
        static var persistentContainer: NSPersistentContainer = {
            let container = NSPersistentContainer(name: "VirtualTourist")
            container.loadPersistentStores(completionHandler: { (storeDescription, error) in
                if let error = error as NSError? {
                    fatalError("Unresolved error \(error), \(error.userInfo)")
                }
            })
            return container
        }()
        
        // MARK: -- Core Data Saving support
        /***************************************************************/
        class func saveContext () {
            let context = persistentContainer.viewContext
            if context.hasChanges {
                do {
                    try context.save()
                } catch {
                    let nserror = error as NSError
                    fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
                }
            }
        }
    
    
    
    func autoSaveViewContext(interval:TimeInterval = 30) {
        print("autosaving...")
        guard interval > 0 else {
            print("Cannot set interval to a negative number")
            return
        }
        if CoreDataStack.getContext().hasChanges{
            try? CoreDataStack.getContext().save()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + interval) {
            self.autoSaveViewContext(interval: interval)
        }
    }
    }
*/
