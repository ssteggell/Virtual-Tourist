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



//MARK: OLD CODE

class mapViewController: UIViewController, MKMapViewDelegate, NSFetchedResultsControllerDelegate {
    
    
    
    // MARK: OUTLETS
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var deletePinsBtn: UIBarButtonItem!
    @IBOutlet weak var cancelBtn: UIBarButtonItem!
    @IBOutlet weak var deletePinsLabel: UILabel!
    @IBOutlet weak var resetMapBtn: UIBarButtonItem!
    
    
    //MARK: PROPERTIES
    
    var annotations = [Pin]()
    var savedPins = [MKPointAnnotation]()
    var fetchedResultsController: NSFetchedResultsController<Pin>!
    var latitude: Double?
    var longitude: Double?
    
    fileprivate let locationManager: CLLocationManager = CLLocationManager()
    
    
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
        mapView.delegate = self
        setUpFetchedResultsViewController()
        findCurrentLocation()
        if UserDefaults.standard.value(forKey: "lat") != nil { loadFromDefaults() }
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(addAnnotationOnLongPress(_ :)))
        mapView.addGestureRecognizer(longPressGesture)
        
    }
    
    //MARK: VIEW WILL DISAPPEAR
    override func viewWillDisappear(_ animated: Bool) {
        
        saveToDefaults()
        
    }
    //MARK: SAVE AND LOAD DEFAULTS
    func loadFromDefaults() {
        let defaults = UserDefaults.standard
        let center = CLLocationCoordinate2DMake(defaults.double(forKey: "lat"), defaults.double(forKey: "lon"))
        let span = MKCoordinateSpan(latitudeDelta: (defaults.double(forKey: "latSpan")), longitudeDelta: (defaults.double(forKey: "lonSpan")))
        let savedRegion: MKCoordinateRegion = MKCoordinateRegion(center: center, span: span)
        mapView.setRegion(savedRegion, animated: true)
        
    }
    
    func saveToDefaults() {
        let defaults = UserDefaults.standard
        let region = mapView.region
        let coordinates = mapView.centerCoordinate
        defaults.set(coordinates.latitude, forKey: "lat")
        defaults.set(coordinates.longitude, forKey: "lon")
        defaults.set(region.span.latitudeDelta, forKey: "latSpan")
        defaults.set(region.span.longitudeDelta, forKey: "lonSpan")
        
    }
    
    
    //MARK: GET USER LOCATION
    
    fileprivate func findCurrentLocation() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.startUpdatingLocation()
        mapView.showsUserLocation = true
        
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
    
    //FUNCTION USED TO CREATE NEW ANNOTATIONS
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseID = "pin"
        var pinView: MKPinAnnotationView
        
        if let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseID) as? MKPinAnnotationView {
            pinView = annotationView
        } else {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseID)
        }
        
        pinView.canShowCallout = true
        pinView.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        pinView.annotation = annotation
        return pinView
    }
    
    //FUNCTION USED FOR SEGUE
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
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
    
    //FUNCTION USED TO DELETE PINS
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        if deletePinsBtn.isEnabled == false {
            let selectedAnnotation = view.annotation as? MKPointAnnotation
            
            for pin in annotations {
                if pin.latitude == selectedAnnotation?.coordinate.latitude &&
                    pin.longitude == selectedAnnotation?.coordinate.longitude {
                    mapView.removeAnnotation(selectedAnnotation!)
                    DataController.shared.viewContext.delete(pin)
                    DataController.shared.save()
                }
            }
        }
    }
    
    
    //MARK: BUTTONS
    //DELETING PINS
    @IBAction func deleteBtnPressed(_ sender: Any) {
        deletePinsBtn.isEnabled = false
        cancelBtn.isEnabled = true
        deletePinsLabel.isHidden = false
        
    }
    
    //CANCEL DELETE OPTION
    @IBAction func cancelBtnPressed(_ sender: Any) {
        deletePinsBtn.isEnabled = true
        cancelBtn.isEnabled = false
        deletePinsLabel.isHidden = true
    }
    
    //RESET MAP TO DEFAULT VIEW
    @IBAction func resetMapBtnPressed(_ sender: Any) {
        let center = CLLocationCoordinate2DMake(37.13283999999996, -95.78557999999998)
        let span = MKCoordinateSpan(latitudeDelta: 86.24809813365279, longitudeDelta: 61.276014999999916)
        let region = MKCoordinateRegion(center: center, span: span)
        mapView.setRegion(region, animated: true)
        
    }
    
}

