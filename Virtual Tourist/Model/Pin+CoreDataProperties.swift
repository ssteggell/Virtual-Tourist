//
//  Pin+CoreDataProperties.swift
//  Virtual Tourist
//
//  Created by Spencer Steggell on 5/29/20.
//  Copyright © 2020 Spencer Steggell. All rights reserved.
//
//

import Foundation
import CoreData


extension Pin {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Pin> {
        return NSFetchRequest<Pin>(entityName: "Pin")
    }

    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double
    @NSManaged public var photos: Photo?

}
