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


class mapViewController: UIViewController, MKMapViewDelegate, NSFetchedResultsControllerDelegate {

    
    // MARK: OUTLETS
    
    @IBOutlet weak var mapView: MKMapView!

    
    //MARK: PROPERTIES
    
    var annotations = [Pin]()
    var savedPins = [MKPointAnnotation]()
    var fetchedResultsController: NSFetchedResultsController<Pin>!
    var latitude: Double?
    var longitude: Double?
    
    //MARK: SET UP FETCH
    
    fileprivate func setUpFetchedResultsViewController() {
        let fetchRequest: NSFetchRequest<Pin> = Pin.fetchRequest()
        
        if let result = try? DataController.shared.viewContext.fetch(fetchRequest) {
            annotations = result
            for annotation in annotations {
                let savePin = MKPointAnnotation()
                if let lat = CLLocationDegrees(exactly: annotation.latitude), let lon = CLLocationDegrees(exactly: annotation.longitude) {
                    let coordinateLocation = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                    savePin.coordinate = coordinateLocation
                    savePin.title = "View Photos"
                    savedPins.append(savePin)
                }
            }
            mapView.addAnnotations(savedPins)
        }
    }
    
    //MARK: VIEW DID LOAD
    
     override func viewDidLoad() {
            super.viewDidLoad()
        setUpFetchedResultsViewController()
        mapView.delegate = self
    //        initialLocation.CLLocation = UserDefaults.standard.float(forKey: "initialLocation")
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(addAnnotationOnLongPress(_ :)))
            mapView.addGestureRecognizer(longPressGesture)
//            loadAnnotations()
    //         Do any additional setup after loading the view.
        }
    
    
    //MARK: LONG PRESS FUNCTION
    
        @objc func addAnnotationOnLongPress(_ sender: UILongPressGestureRecognizer) {

            guard sender.state == UIGestureRecognizer.State.began else { return }
                let point = sender.location(in: mapView)
                let coordinate = mapView.convert(point, toCoordinateFrom: mapView)
                print(coordinate)
                //Now use this coordinate to add annotation on map.
            let annotation: MKPointAnnotation = MKPointAnnotation()
                annotation.coordinate = coordinate
            annotation.title = "View Photos"
            mapView.addAnnotation(annotation)
            let pin = Pin(context: DataController.shared.viewContext)
            pin.latitude = Double(coordinate.latitude)
            pin.longitude = Double(coordinate.longitude)
            annotations.append(pin)
            DataController.shared.save()
                }
    
    //MARK: MAPVIEWS
    
    func mapViewPins(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseId = "pin"
        var pinView: MKPinAnnotationView
        
        if let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView {pinView = annotationView}
        else {
             pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
        }
            pinView.canShowCallout = true
            pinView.pinTintColor = .blue
            pinView.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        pinView.annotation = annotation
        return pinView
    }
        
        
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        let vc = storyboard?.instantiateViewController(withIdentifier: "PhotoAlbumViewController") as! PhotoAlbumViewController
        let lat = view.annotation?.coordinate.latitude
        let lon = view.annotation? .coordinate.longitude
        let coordinate = CLLocationCoordinate2D(latitude: lat!, longitude: lon!)
        let selectedPin = MKPointAnnotation(__coordinate: coordinate)
        
        for pin in annotations {
            if pin.latitude == selectedPin.coordinate.latitude && pin.longitude == selectedPin.coordinate.longitude {
                vc.selectedPin = pin
            }
        }
        navigationController?.pushViewController(vc, animated: true)
    }

}

    //                    performUIUpdatesOnMain {
    //                        CoreDataStack.saveContext()
    //                        self
            

//        }
//}

    /*
    
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
        loadAnnotations()
//         Do any additional setup after loading the view.
    }
    
    override func viewWillDisappear(_ animated: Bool) {

    }


    @objc func addAnnotationOnLongPress(gesture: UILongPressGestureRecognizer) {

        if gesture.state == .ended {
            let point = gesture.location(in: self.mapView)
            let coordinate = self.mapView.convert(point, toCoordinateFrom: self.mapView)
            print(coordinate)
            //Now use this coordinate to add annotation on map.
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate

            addedPinSaved(lat: coordinate.latitude, lon: coordinate.longitude)
            //Set title and subtitle if you want
            annotation.title = "'\(coordinate.latitude)' '\(coordinate.longitude)'"
//            annotation.subtitle = "subtitle"
            self.mapView.addAnnotation(annotation)

            performUIUpdatesOnMain {
                self.loadAnnotations()
            }
        }

    }
    
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowPhotoAlbumVC" {
            let controller = segue.destination as! PhotoAlbumViewController
            let selectedPin = sender as! Pin
            controller.selectedPin = selectedPin
        }
    }
    
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        mapView.deselectAnnotation(view.annotation, animated: true)
        let lat = view.annotation?.coordinate.latitude
        let lon = view.annotation? .coordinate.longitude
        let fetchRequest: NSFetchRequest<Pin> = Pin.fetchRequest()
        do {
            let searchResults = try CoreDataStack.getContext().fetch(fetchRequest)
            for pin in searchResults as [Pin] {
                if pin.latitude == lat!, pin.longitude == lon! {
                    let selectedPin = pin
                    print("Found info")
//                    performUIUpdatesOnMain {
//                        CoreDataStack.saveContext()
//                        self
                    performUIUpdatesOnMain {
                        self.performSegue(withIdentifier: "ShowPhotoAlbumVC", sender: selectedPin)
                    }
                }
            }
        } catch {
            print("Error: \(error)")
        }
        
        
    }
}

*/
