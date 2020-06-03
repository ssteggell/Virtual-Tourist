//
//  SearchRequest.swift
//  Virtual Tourist
//
//  Created by Spencer Steggell on 5/19/20.
//  Copyright © 2020 Spencer Steggell. All rights reserved.
//

import Foundation


struct JsonFlickrApi: Codable {
    let photos: FlickrPhotoResponse
}

struct FlickrPhotoResponse: Codable {
    let page: Int
    let pages: Int
    let photo: [FlickrPhoto]
    
    
}

struct FlickrPhoto: Codable {
    let id: String
    let secret: String
    let server: String
    let farm: Int
    
    func imageURLString() -> String {
        
        return "https://farm\(farm).staticflickr.com/\(server)/\(id)_\(secret)_q.jpg"
    }
}



//        https://www.flickr.com/services/rest/?method=flickr.photos.search&api_key=b5625f901b99ec2378ab503d2cbde877&lat=32.7123&lon=-117.1521&format=json&nojsoncallback=1

