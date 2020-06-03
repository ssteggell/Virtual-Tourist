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
    
    static let sharedInstance = FlickrClient()
    let apiKey = "b5625f901b99ec2378ab503d2cbde877"
    let secret = "327f4503ee9d92bd"
    
    
    let baseUrl = "https://api.flickr.com/services/rest"
    let searchUrl = "flickr.photos.search"
    
    var session = URLSession.shared
    
    
    func getPhotoUrl(lat: Double, lon: Double, page: Int, completion: @escaping ([FlickrPhoto]?, Error?) -> Void) {
        guard var components = URLComponents(string: baseUrl) else {
            print("error with get photo URL")
            return }
        
        let api = URLQueryItem(name: "api_key", value: apiKey)
        let method = URLQueryItem(name: "method", value: searchUrl)
        let format = URLQueryItem(name: "format", value: "json")
        let queryLat = URLQueryItem(name: "lat", value: String(lat))
        let queryLon = URLQueryItem(name: "lon", value: String(lon))
        let jsonCallback = URLQueryItem(name: "nojsoncallback", value: "1")
        let perPage = URLQueryItem(name: "per_page", value: "21")
        let page = URLQueryItem(name: "page", value: String(page))
        
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
   /*
        
    }
    
    struct Constants {
        struct Flickr {
            static let APIScheme = "https"
            static let APIHost = "api.flickr.com"
            static let APIPath = "/services/rest"
            
            static let SearchBBoxHalfWidth = 1.0
                   static let SearchBBoxHalfHeight = 1.0
                   static let SearchLatRange = (-90.0, 90.0)
                   static let SearchLonRange = (-180.0, 180.0)
        }
        
        struct FlickrParamaterKeys {
            
            static let Method = "method"
            static let APIKey = "api_key"
            static let Extras = "extras"
            static let Format = "format"
            static let NoJSONCallback = "nojsoncallback"
            static let Text = "text"
            static let BoundingBox = "bbox"
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
            Constants.FlickrParamaterKeys.BoundingBox: bboxString(longitude:selectedPin.longitude , latitude: selectedPin.latitude),
            Constants.FlickrParamaterKeys.Extras: Constants.FlickrParameterValues.MediumURL,
            Constants.FlickrParamaterKeys.Format: Constants.FlickrParameterValues.ResponseFormat,
            Constants.FlickrParamaterKeys.Latitude: "\(selectedPin.latitude)",
            Constants.FlickrParamaterKeys.Longitude: "\(selectedPin.longitude)",
            Constants.FlickrParamaterKeys.NoJSONCallback: Constants.FlickrParameterValues.DisableJSONCallback,
            Constants.FlickrParamaterKeys.PerPage: "21",
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
                    try? CoreDataStack.persistentContainer.viewContext.save()
                }
                completionHandler(imageUrlStrings, nil)
        
            
        }
        }
        
        task.resume()
    }
    
    func fetchImage(for Photo: Photo, completionHandler: @escaping (_ data: Data?) -> Void) {
           
           /* Build the URL */
        let photoURLString = Photo.urlString
           let photoURL = URL(string: photoURLString!)
           
           /* Configure the request */
           let request = URLRequest(url: photoURL!)
           
           // create network request
           let task = session.dataTask(with: request) { (data, response, error) in
               
               /* GUARD: Was there an error? */
               guard (error == nil) else {
                   print("There was an error with your request: \(String(describing: error))")
                   return
               }
               
               /* GUARD: Did we get a successful 2XX response? */
               guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                   print("Your request returned a status code other than 2xx!")
                   return
               }
               
               /* GUARD: Was there any data returned? */
               guard let data = data else {
                   print("No data was returned by the request!")
                   return
               }
               
               OperationQueue.main.addOperation {
                   Photo.imageData = data as NSData
                   completionHandler(data)
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
    
//    func fetchImagesWithLatitudeAndLongitude(latitude: Double, longitude: Double, completionHandler: @escaping (_ result: AnyObject?, _ error: NSError?) -> Void) {
//
////           pageRequested += 1
//
//           /* Set the Parameters */
//           var methodParameters: [String: Any] = [
//               Constants.FlickrParamaterKeys.Latitude: latitude,
//               Constants.FlickrParamaterKeys.Longitude: longitude,
//               Constants.FlickrParamaterKeys.Page: 1]
//
//           /* Build the URL */
//        var getRequestURL = flickrURLFromParameters(methodParameters)
//
//           /* Configure the request */
//           let request = URLRequest(url: getRequestURL)
//
//           // create network request
//           let task = session.dataTask(with: request) { (data, response, error) in
//
//               func sendError(_ error: String) {
//                   print(error)
//                   let userInfo = [NSLocalizedDescriptionKey : error]
//                   completionHandler(nil, NSError(domain: "getImagesWithLatitudeAndLongitude", code: 1, userInfo: userInfo))
//               }
//
//               /* GUARD: Was there an error? */
//               guard (error == nil) else {
//                   sendError("There was an error with your request: \(String(describing: error))")
//                   return
//               }
//
//               /* GUARD: Did we get a successful 2XX response? */
//               guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
//                   sendError("Your request returned a status code other than 2xx!")
//                   return
//               }
//
//               /* GUARD: Was there any data returned? */
//               guard let data = data else {
//                   sendError("No data was returned by the request!")
//                   return
//               }
//
//               /* Parse the Parse data and use the data (happens in completion handler) */
//            self.convertDataWithCompletionHandler(data, completionHandlerForConvertData: completionHandler)
//           }
//           task.resume()
//       }
//
//    func extractAllPhotoURLStrings(fromJSONDictionary jsonDictionary: AnyObject) -> [String] {
//        var allPhotoStrings = [String]()
//
//        guard let photos = jsonDictionary[Constants.FlickrResponseKeys.Photos] as? [String: Any],
//            let photosArray = photos[Constants.FlickrResponseKeys.Photo] as? [[String: Any]] else {
//                print("The proper keys are not in the provided JSON array.")
//                return []
//        }
//
//        for photoDict in photosArray {
//            if let photoURLString = photoDict["url_m"] as? String {
//                allPhotoStrings.append(photoURLString)
//            }
//        }
//        return allPhotoStrings
//    }
    
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
    
    func bboxString(longitude:Double, latitude:Double) -> String {
              let minimumLon = max(longitude - Constants.Flickr.SearchBBoxHalfWidth, Constants.Flickr.SearchLonRange.0)
              let minimumLat = max(latitude - Constants.Flickr.SearchBBoxHalfHeight, Constants.Flickr.SearchLatRange.0)
              let maximumLon = min(longitude + Constants.Flickr.SearchBBoxHalfWidth, Constants.Flickr.SearchLonRange.1)
              let maximumLat = min(latitude + Constants.Flickr.SearchBBoxHalfHeight, Constants.Flickr.SearchLatRange.1)
              return "\(minimumLon),\(minimumLat),\(maximumLon),\(maximumLat)"
          }
   

}

func performUIUpdatesOnMain(_ updates: @escaping () -> Void) {
       DispatchQueue.main.async {
           updates()
       }
    
   
   }
*/
