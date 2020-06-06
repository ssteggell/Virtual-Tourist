//
//  FlickrViewCell.swift
//  Virtual Tourist
//
//  Created by Spencer Steggell on 6/3/20.
//  Copyright © 2020 Spencer Steggell. All rights reserved.
//

import Foundation
import UIKit

class FlickrViewCell: UICollectionViewCell {
    
    //MARK: OUTLETS
    @IBOutlet weak var flickrImage: UIImageView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    
    //PUT PHOTO DATA IN CELL OR DOWNLOAD IMAGE
    func initWithPhoto(_ photo: Photo) {
        if photo.imageData != nil {
            DispatchQueue.main.async {
                self.flickrImage.image = UIImage(data: photo.imageData! as Data)
            }
        } else {
            downloadImage(photo)
        }
    }
    
    //DOWNLOAD THE IMAGES
    func downloadImage(_ photo: Photo) {
        URLSession.shared.dataTask(with: URL(string: photo.urlString!)!) { (data, response, error) in
            if error == nil {
                DispatchQueue.main.async {
                    self.flickrImage.image = UIImage(data: data! as Data)
                    self.saveImageDataToCoreData(photo, imageData: data! as Data)
                }
            }
        }
        .resume()
    }
    
    //SAVE THE DOWNLOADED IMAGE DATA TO CORE DATA
    func saveImageDataToCoreData(_ photo: Photo, imageData: Data) {
        do {
            photo.imageData = imageData
            try DataController.shared.viewContext.save()
        } catch {
            print("saving photo image failed")
        }
    }
}
