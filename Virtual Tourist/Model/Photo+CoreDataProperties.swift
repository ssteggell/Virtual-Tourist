//
//  Photo+CoreDataProperties.swift
//  Virtual Tourist
//
//  Created by Spencer Steggell on 5/29/20.
//  Copyright © 2020 Spencer Steggell. All rights reserved.
//
//

import Foundation
import CoreData


extension Photo {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Photo> {
        return NSFetchRequest<Photo>(entityName: "Photo")
    }

    @NSManaged public var imageData: Data?
    @NSManaged public var urlString: String?
    @NSManaged public var pin: Pin?

}
