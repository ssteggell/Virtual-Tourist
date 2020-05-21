//
//  CoreDataStack.swift
//  Virtual Tourist
//
//  Created by Spencer Steggell on 5/20/20.
//  Copyright © 2020 Spencer Steggell. All rights reserved.
//

import Foundation
import CoreData


class CoreDataStack {
    
        private init(){}
        
        class func getContext() -> NSManagedObjectContext {
            return CoreDataStack.persistentContainer.viewContext
        }
        
        static var persistentContainer: NSPersistentContainer = {
            let container = NSPersistentContainer(name: "Virtual-Tourist")
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
    }
