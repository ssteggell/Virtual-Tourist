//
//  PhotoAlbumViewControllerCell.swift
//  Virtual Tourist
//
//  Created by Spencer Steggell on 5/22/20.
//  Copyright © 2020 Spencer Steggell. All rights reserved.
//

import Foundation
import UIKit





class PhotoAlbumCollectionViewCell: UICollectionViewCell {
    

    @IBOutlet weak var flickrImage: UIImageView!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    
    func initWithPhoto(_ photo: Photo) {
        
        if photo.imageData != nil {
            DispatchQueue.main.async {
                self.flickrImage.image = UIImage(data: photo.imageData! as Data)
            }
            
        } else {
            downloadImage(photo)
        }
    }
    
    
    func downloadImage(_ photo: Photo) {
        URLSession.shared.dataTask(with: URL(string: photo.urlString!)!) { (data, response, error) in
            
            if error == nil {
                DispatchQueue.main.async {
                    self.flickrImage.image = UIImage(data: data! as Data)
//                    self.saveToCoreData(photo, imageData: data! as Data)
                    
                }
            }
        }
    .resume()
    }
    
    
//    func saveToCoreData(_ photo: Photo, imageData: Data) {
//
//        do {
//            photo.imageData = imageData
//            try DataController.shared.viewContext.save()
//        } catch {
//            print("Saving photo failed")
//        }
//
//    }
}
