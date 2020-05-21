//
//  FlickrClient.swift
//  Virtual Tourist
//
//  Created by Spencer Steggell on 5/18/20.
//  Copyright © 2020 Spencer Steggell. All rights reserved.
//

import Foundation
//import UIKit
import CoreData
//import CoreLocation


class FlickrClient {
    
    let apiKey = "b5625f901b99ec2378ab503d2cbde877"
    let baseUrl = "https://api.flickr.com/services"
    
    static let sharedInstance = FlickrClient()
    var session = URLSession.shared
    
    struct Constants {
        struct Flickr {
            static let APIScheme = "https"
            static let APIHost = "api.flickr.com"
            static let APIPath = "/services/rest"
        }
        
        struct FlickrParamaterKeys {
            
            static let Method = "method"
            static let APIKey = "api_key"
            static let Extras = "extras"
            static let Format = "format"
            static let NoJSONCallback = "nojsoncallback"
            static let Page = "page"
            static let PerPage = "per_page"
            static let Latitude = "lat"
            static let Longitude = "lon"
        }
        
        struct FlickrParameterValues {
            static let SearchMethod = "flickr.photos.search"
            static let APIKey = "b5625f901b99ec2378ab503d2cbde877"
            static let ResponseFormat = "json"
            static let DisableJSONCallback = "1"
            static let GalleryPhotosMethod = "flickr.galleries.getPhotos"
            static let MediumURL = "url_m"
            
        }
        
        struct FlickrResponseKeys {
            static let Status = "stat"
            static let Photos = "photos"
            static let Photo = "photo"
            static let Title = "title"
            static let MediumURL = "url_m"
            static let Pages = "pages"
            static let Total = "total"
            
        }
        
        struct FlickrResponseValues {
            static let OKStatus = "ok"
        }
    }
    

    
     func getImagesFromFlickr(_ selectedPin: Pin, _ page: Int, _ completionHandler: @escaping (_ result: [Photo]?, _ error: NSError?) -> Void) {
        
        let params: [String:String] = [
            Constants.FlickrParamaterKeys.Method: Constants.FlickrParameterValues.SearchMethod,
            Constants.FlickrParamaterKeys.APIKey: Constants.FlickrParameterValues.APIKey,
//            "bbox": createBoundingBoxString(latitdue, longitude: longitude),
            Constants.FlickrParamaterKeys.Extras: Constants.FlickrParameterValues.MediumURL,
            Constants.FlickrParamaterKeys.Format: Constants.FlickrParameterValues.ResponseFormat,
            Constants.FlickrParamaterKeys.Latitude: "\(selectedPin.latitude)",
            Constants.FlickrParamaterKeys.Longitude: "\(selectedPin.longitude)",
            Constants.FlickrParamaterKeys.NoJSONCallback: "1",
            Constants.FlickrParamaterKeys.PerPage: "30",
            Constants.FlickrParamaterKeys.Page: String(page),
        ]
        
        let request = URLRequest(url: flickrURLFromParameters(params))
        
        let task = taskForGETMethod(request: request) { (parsedResult, error) in
            
            func displayError(_ error: String) {
                let userInfo = [NSLocalizedDescriptionKey : error]
                completionHandler(nil, NSError(domain: "taskForGETMethod", code: 1, userInfo: userInfo))

            }
            
            guard let stat = parsedResult?[Constants.FlickrResponseKeys.Status] as? String, stat == Constants.FlickrResponseValues.OKStatus
                else {
                    displayError("Flickr API returned an error")
                    return
            }
            
            guard let photosDictionary = parsedResult?[Constants.FlickrResponseKeys.Photos] as? [String:AnyObject]
                else {
                    displayError("Cannot find key")
                    return
            }
            
            guard let photosArray = photosDictionary[Constants.FlickrResponseKeys.Photo] as? [[String: AnyObject]]
                else {
                    displayError("Cannot find key")
                    return
            }
            
            performUIUpdatesOnMain {
                
                let context = CoreDataStack.getContext()
                
                var imageUrlStrings = [Photo]()
                
                for url in photosArray {
                    guard let urlString = url[Constants.FlickrResponseKeys.MediumURL] as? String
                        else {
                            displayError("Cannot find key")
                            return
                    }
                    let photo:Photo = NSEntityDescription.insertNewObject(forEntityName: "Photo", into: context ) as! Photo
                    
                    photo.urlString = urlString
                    photo.pin = selectedPin
                    imageUrlStrings.append(photo)
                    CoreDataStack.saveContext()
                }
                completionHandler(imageUrlStrings, nil)
                
            }
        }
        
        task.resume()
    }
    
    
    private func taskForGETMethod(request: URLRequest, _ completionHandlerForGET: @escaping(_ result: AnyObject?, _ error: NSError?) -> Void) -> URLSessionDataTask {
        let task = session.dataTask(with: request) { (data, response, error) in
            
            func displayError(_ error: String) {
                let userInfo = [NSLocalizedDescriptionKey : error]
                completionHandlerForGET(nil, NSError(domain: "taskForGETMethod", code: 1, userInfo: userInfo))

            }
            
            guard let data = data else {
                displayError("No data was returned by the request")
                return
            }
            
            self.convertDataWithCompletionHandler(data, completionHandlerForConvertData: completionHandlerForGET)
            
        }
        task.resume()
        return task
    }
    
    func getDataFromURL(_ urlString: String, _ completionHandler: @escaping (_ imageData: Data?, _ error: String?) -> Void) {
        
        guard let url = URL(string: urlString) else { return }
        let request = URLRequest(url: url)
        let task = session.dataTask(with: request) { (data, response, error) in
            guard error == nil else {
                completionHandler(nil, error?.localizedDescription)
                return
                
            }
            completionHandler(data, nil)
            
        }
        task.resume()
    }
    
    func flickrURLFromParameters(_ parameters: [String: String]) -> URL {
        var components = URLComponents()
        components.scheme = Constants.Flickr.APIScheme
        components.host = Constants.Flickr.APIHost
        components.path = Constants.Flickr.APIPath
        components.queryItems = [URLQueryItem]()
        
        for (key, value) in parameters {
            let queryItem = URLQueryItem(name: key, value: "\(value)")
            components.queryItems!.append(queryItem)
        }
        return components.url!
    }
    
    func escapedParameters(_ parameters: [String: AnyObject]) -> String {
        
        if parameters.isEmpty {
            return ""
        } else {
            var keyValuePairs = [String]()
            
            for (key, value) in parameters {
                
                let stringValue = "\(value)"
                
                let escapedValue = stringValue.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
                
                keyValuePairs.append(key + "=" + "\(escapedValue!)")
            }
            
            return "?\(keyValuePairs.joined(separator: "&"))"
        }
    }
    
    private func convertDataWithCompletionHandler(_ data: Data, completionHandlerForConvertData: (_ result: AnyObject?, _ error: NSError?) -> Void) {
        
        var parsedResult: AnyObject! = nil
        do {
            parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as AnyObject
            
        } catch {
            let userInfo = [NSLocalizedDescriptionKey : "Could not parse the data as JSON: '\(data)'"]
            completionHandlerForConvertData(nil, NSError(domain: "convertDataWithCompletionHandler", code: 1, userInfo: userInfo))
        
        }
        
        completionHandlerForConvertData(parsedResult, nil)
    }
    
   

}

func performUIUpdatesOnMain(_ updates: @escaping () -> Void) {
       DispatchQueue.main.async {
           updates()
       }
   }
