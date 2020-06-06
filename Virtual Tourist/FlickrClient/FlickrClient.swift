//
//  FlickrClient.swift
//  Virtual Tourist
//
//  Created by Spencer Steggell on 5/18/20.
//  Copyright © 2020 Spencer Steggell. All rights reserved.
//

import Foundation
//import UIKit
//import CoreData
//import CoreLocation



class FlickrClient {
    
    //API INFORMATION
    static let sharedInstance = FlickrClient()
    let apiKey = "b5625f901b99ec2378ab503d2cbde877"
    let secret = "327f4503ee9d92bd"
    
    //BASE URL AND SEARCH URL
    let baseUrl = "https://api.flickr.com/services/rest"
    let searchUrl = "flickr.photos.search"
    
    var session = URLSession.shared
    
    //FUNCTION USED TO PLUG IN PARAMETERS AND GET PHOTO DATA
    func getPhotoUrl(lat: Double, lon: Double, page: Int, completion: @escaping ([FlickrPhoto]?, Error?) -> Void) {
        guard var components = URLComponents(string: baseUrl) else {
            print("error with get photo URL")
            return }
        
        //SEARCH PARAMTERS AND THEIR VALUES ON FLICKR SITE
        let api = URLQueryItem(name: "api_key", value: apiKey)
        let method = URLQueryItem(name: "method", value: searchUrl)
        let format = URLQueryItem(name: "format", value: "json")
        let queryLat = URLQueryItem(name: "lat", value: String(lat))
        let queryLon = URLQueryItem(name: "lon", value: String(lon))
        let jsonCallback = URLQueryItem(name: "nojsoncallback", value: "1")
        let perPage = URLQueryItem(name: "per_page", value: "100")
        let page = URLQueryItem(name: "page", value: String(page))
        
        //PUTTING TOGETHER THE QUERY URL WITH SEARCH PARAMTERS
        components.queryItems = [api, method, format, queryLat, queryLon, jsonCallback, perPage, page]
        guard let url = components.url else {
            print("could not build url")
            return
        }
        let task = session.dataTask(with: url) { (data, response, error) in
            if let error = error {
                completion(nil, error)
                print("failed to connect")
                
            }
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode == 200 else {
                print("Error Status code 200")
                return
            }
            guard let data = data else {
                print("no data")
                return
            }
            let decoder = JSONDecoder()
            do {
                let responseObject = try decoder.decode(JsonFlickrApi.self, from: data)
                print(responseObject)
                let photos = Array(responseObject.photos.photo.prefix(100))
                completion(photos, nil)
            } catch {
                completion(nil, error)
            }
        }
        task.resume()
    }
}
