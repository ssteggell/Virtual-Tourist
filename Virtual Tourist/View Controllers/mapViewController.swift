//
//  ViewController.swift
//  Virtual Tourist
//
//  Created by Spencer Steggell on 5/14/20.
//  Copyright © 2020 Spencer Steggell. All rights reserved.
//

import UIKit
import MapKit
import CoreData


class mapViewController: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
//    var annotations = [MKPointAnnotation]()
//    private let kMapRegion = "region"
    
//    var fetchedResultsController: NSFetchedResultsController<Pin>!

    
 override func viewWillAppear(_ animated: Bool) {
//    if let savedRegion = UserDefaults.standard.value(forKey: kMapRegion) {
//        mapView.setVisibleMapRect(savedRegion as! MKMapRect, animated: true)
//      }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
//        initialLocation.CLLocation = UserDefaults.standard.float(forKey: "initialLocation")
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(addPin(gestureRecognizer:)))
        longPressGesture.minimumPressDuration = 1.0
        self.mapView.addGestureRecognizer(longPressGesture)
//         Do any additional setup after loading the view.
    }
    
    override func viewWillDisappear(_ animated: Bool) {

    }


//    @objc func addAnnotationOnLongPress(gesture: UILongPressGestureRecognizer) {
//
//        if gesture.state == .ended {
//            let point = gesture.location(in: self.mapView)
//            let coordinate = self.mapView.convert(point, toCoordinateFrom: self.mapView)
//            print(coordinate)
//            //Now use this coordinate to add annotation on map.
//            let annotation = MKPointAnnotation()
//            annotation.coordinate = coordinate
//
//            addedPinSaved(lat: coordinate.latitude, lon: coordinate.longitude)
//            //Set title and subtitle if you want
//            annotation.title = "'\(coordinate.latitude)' '\(coordinate.longitude)'"
////            annotation.subtitle = "subtitle"
//            self.mapView.addAnnotation(annotation)
//
//            performUIUpdatesOnMain {
//                self.loadAnnotations()
//            }
//        }
//
//    }
    
    @objc func addPin(gestureRecognizer: UILongPressGestureRecognizer) {
        /* Add Pin when the Long Press Gesture state has began */
        if gestureRecognizer.state == UIGestureRecognizer.State.began {
            
            let location = gestureRecognizer.location(in: mapView)
            let newCoordinates = mapView.convert(location, toCoordinateFrom: mapView)
            let annotation = MKPointAnnotation()
            annotation.coordinate = newCoordinates
            
            addedPinSaved(lat: newCoordinates.latitude, lon: newCoordinates.longitude)
            
            performUIUpdatesOnMain {
                self.loadAnnotations()
            }
        }
    }
    
    func addedPinSaved(lat: Double, lon: Double) {
        let context = CoreDataStack.getContext()
        let pin : Pin = NSEntityDescription.insertNewObject(forEntityName: "Pin", into: context) as! Pin

        pin.latitude = lat
        pin.longitude = lon

        CoreDataStack.saveContext()

    }
    
   
}


extension mapViewController: MKMapViewDelegate {
    
    func loadAnnotations() {
        let fetchRequest : NSFetchRequest<Pin> = Pin.fetchRequest()
        
        do {
            let searchResults = try CoreDataStack.getContext().fetch(fetchRequest)
            var annotations = [MKPointAnnotation]()
            for result in searchResults as [Pin] {
                let lat = CLLocationDegrees(result.latitude)
                let long = CLLocationDegrees(result.longitude)
                let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
                let annotation = MKPointAnnotation()
                annotation.coordinate = coordinate
                annotations.append(annotation)
            }
            
            performUIUpdatesOnMain {
                self.mapView.addAnnotations(annotations)
            }
        } catch {
            print("Error fetching annotations: \(error)")
        }
    }
    
    func mapViewPins(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
           
           let reuseId = "pin"
           
           var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
           
           if pinView == nil {
               pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
               pinView!.canShowCallout = true
               pinView!.pinTintColor = .red
               pinView!.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
           }
               
           else
           {
               pinView!.annotation = annotation
           }
           
           return pinView
       }
    
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        
    }
}


