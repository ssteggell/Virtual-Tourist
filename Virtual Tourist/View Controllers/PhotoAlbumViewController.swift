//
//  PhotoAlbumViewController.swift
//  Virtual Tourist
//
//  Created by Spencer Steggell on 5/21/20.
//  Copyright © 2020 Spencer Steggell. All rights reserved.
//



import Foundation
import UIKit
import MapKit
import CoreData


class PhotoAlbumViewController: UIViewController, NSFetchedResultsControllerDelegate, MKMapViewDelegate, UICollectionViewDelegate {
    
    // MARK: Outlets
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var flickrCollectionView: UICollectionView!
    @IBOutlet weak var flowLayout: UICollectionView!
    @IBOutlet weak var newCollectionButton: UIButton!
    
    
    // MARK: Properties
    
    var selectedPin : Pin!
    var savedPhotos = [Photo]()
    var flickrPhotos : [FlickrPhoto] = []
    var photoSelected = false
    let numberOfColumns: CGFloat = 3
    var fetchedResultsController: NSFetchedResultsController<Photo>!
    var currentPage = 0
    var flickrClient = FlickrClient()
    
    
    //MARK: SETTING BAR BUTTON ITEMS
    
    lazy var selectBtn: UIBarButtonItem = {
        let barBtnItem = UIBarButtonItem(title: "Select", style: .plain, target: self, action: #selector(selectBtnPressed(_:)))
        return barBtnItem
    }()
    
    lazy var cancelBtn: UIBarButtonItem = {
        let barBtnItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(cancelBtnPressed(_:)))
        return barBtnItem
    }()
    lazy var deleteBtn: UIBarButtonItem = {
        let barBtnItem = UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(deleteBtnPressed(_:)))
        return barBtnItem
    }()
    
    private func setUpBarButtonItems() {
        navigationItem.rightBarButtonItem = selectBtn
        
    }
    
    //MARK: SET UP FETCH
    fileprivate func fetchPhotos() -> [Photo]? {
        var photoArray: [Photo] = []
        let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
        let predicate = NSPredicate(format: "pin == %@", argumentArray: [selectedPin!])
        fetchRequest.predicate = predicate
        let sortDescriptor = NSSortDescriptor(key: "urlString", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: DataController.shared.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        
        do {
            try fetchedResultsController.performFetch()
            let photoCount = try fetchedResultsController.managedObjectContext.count(for: fetchedResultsController.fetchRequest)
            
            for index in 0..<photoCount {
                
                photoArray.append(fetchedResultsController.object(at: IndexPath(row: index, section: 0)))
                print("Photo Array: \(photoArray.count)")
            }
            return photoArray
        } catch {
            print("error performing fetch")
            let alertVC = UIAlertController(title: "Error", message: "Error retrieving data", preferredStyle: .alert)
            alertVC.addAction(UIAlertAction(title: "Okay", style: .default, handler: nil))
            self.present(alertVC, animated: true)
            return nil
        }
    }
    
    //MARK: VIEW DID LOAD
    
    override func viewDidLoad() {
        newCollectionButton.isEnabled = false
        super.viewDidLoad()
        setUpBarButtonItems()
        mapView.delegate = self
        centerMap()
        flickrCollectionView.delegate = self
        flickrCollectionView.dataSource = self
        print("view loaded")
        let savedPhoto = fetchPhotos()
        if savedPhoto != nil && savedPhoto?.count != 0 {
            savedPhotos = savedPhoto!
            showSavedResult()
            print("Showing saved results")
        } else {
            showNewResult()
            print("showing new results")
        }
    }
    
    
    //MARK: FUNCTIONS OF BUTTONS BEING PRESSED
    
    //PRESSING SELECT BUTTON, ALLOWS TO SELECT PHOTOS AND DELETE
    @objc func selectBtnPressed(_ sender: UIBarButtonItem) {
        selectBtn.isEnabled = false
        navigationItem.leftBarButtonItems = [cancelBtn, deleteBtn]
        flickrCollectionView.allowsMultipleSelection = true
        newCollectionButton.isEnabled = false
    }
    
    //CANCELS THE SELECTING OF PHOTOS
    @objc func cancelBtnPressed(_ sender: UIBarButtonItem) {
        selectBtn.isEnabled = true
        navigationItem.leftBarButtonItems = nil
        flickrCollectionView.allowsMultipleSelection = false
        newCollectionButton.isEnabled = true
        if let selectedItems = flickrCollectionView.indexPathsForSelectedItems {
            for selection in selectedItems {
                let cell = flickrCollectionView.cellForItem(at: selection)
                cell?.layer.borderColor = UIColor.clear.cgColor
                cell?.layer.borderWidth = 3
                flickrCollectionView.deselectItem(at: selection, animated: true)
            }
        }
    }
    
    //DELETING PHOTOS FROM CORE DATA
    @objc func deleteBtnPressed(_ sender: UIBarButtonItem) {
        
        if let selectedIndexPaths = flickrCollectionView.indexPathsForSelectedItems {
            for indexPath in selectedIndexPaths {
                let savedPhoto = savedPhotos[indexPath.row]
                for photo in savedPhotos {
                    if photo.urlString == savedPhoto.urlString {
                        DataController.shared.viewContext.delete(photo)
                        try? DataController.shared.viewContext.save()
                    }
                }
            }
            savedPhotos = fetchPhotos()!
            showSavedResult()
            selectBtn.isEnabled = true
        }
    }
    
    
    //MARK: INTERACTING WITH FLICKR API
    
    //FUNCTION TO PULL PHOTOS FROM FLICKR
    func getFlickrPhotos(page: Int){
        
        FlickrClient.sharedInstance.getPhotoUrl(lat: selectedPin.latitude, lon: selectedPin.longitude, page: currentPage) { (photos, error) in
            
            if let error = error {
                print("Error pulling data from Flickr")
                let alertVC = UIAlertController(title: "Error", message: "Error retrieving data", preferredStyle: .alert)
                alertVC.addAction(UIAlertAction(title: "Okay", style: .default, handler: nil))
                self.present(alertVC, animated: true)
                print(error.localizedDescription)
                return
            } else {
                if let photos = photos {
                    DispatchQueue.main.async {
                        self.flickrPhotos = photos
                        self.saveToCoreData(photos : photos)
                        if photos.count == 0 {
                            let alertVC = UIAlertController(title: "Error", message: "No Photos From Flickr Found", preferredStyle: .alert)
                            alertVC.addAction(UIAlertAction(title: "Okay", style: .default, handler: nil))
                            self.present(alertVC, animated: true)
                        } else {
                            print("\(photos.count) fetched")
                            self.flickrCollectionView.reloadData()
                            self.savedPhotos = self.fetchPhotos()!
                            self.showSavedResult()
                            print("\(photos.count) fetched")
                        }
                    }
                }
            }
        }
    }
    
    //NAVIGATE TO NEXT PAGE OF RESULTS
    @IBAction func newCollectionButton(_ sender: UIButton) {
        deleteFromCoreData()
        currentPage += 1
        getFlickrPhotos(page: currentPage)
        
    }
    
    //RELOAD TABLES
    func reloadSavedData() {
        DispatchQueue.main.async {
            self.flickrCollectionView.reloadData()
        }
    }
    
    //DELETE FROM CORE DATA
    func deleteFromCoreData() {
        
        for image in savedPhotos {
            DataController.shared.viewContext.delete(image)
        }
    }
    
    //RELOADING TABLES WITH SAVED RESULTS
    func showSavedResult() {
        
        DispatchQueue.main.async {
            
            self.flickrCollectionView.reloadData()
            self.newCollectionButton.isEnabled = true
        }
    }
    
    //RELOADING TABLE WITH NEW RESULTS
    func showNewResult() {
        savedPhotos.removeAll()
        getFlickrPhotos(page: currentPage)
        newCollectionButton.isEnabled = true
    }
    
    
    //SAVE TO CORE DATA
    func saveToCoreData(photos: [FlickrPhoto]) {
        for flickrPhoto in photos {
            let photo = Photo(context: DataController.shared.viewContext)
            photo.urlString = flickrPhoto.imageURLString()
            photo.pin = selectedPin
            savedPhotos.append(photo)
            DataController.shared.save()
            print("\(savedPhotos.count) saved")
        }
    }
    
    //CENTER THE MAP ON THE SELECTED PIN LOCATION
    func centerMap() {
        
        let center = CLLocationCoordinate2D(latitude: selectedPin.latitude, longitude: selectedPin.longitude)
        let span = MKCoordinateSpan(latitudeDelta: 0.25, longitudeDelta: 0.25)
        let mapRegion = MKCoordinateRegion(center: center, span: span)
        mapView.setRegion(mapRegion, animated: true)
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = center
        self.mapView.addAnnotation(annotation)
        
    }
    
    
}
//MARK: UI COLLECTION VIEW CONTROLLER FUNCTIONS

extension PhotoAlbumViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    //CREATING NUMBER OF CELLS
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        print(savedPhotos.count)
        return savedPhotos.count
        
    }
    
    //CREATING ONE SECTION
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    //LOADING CELLS WITH PHOTOS
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "flickrPhotoCell", for: indexPath) as! FlickrViewCell
        
        let photo = savedPhotos[indexPath.row]
        cell.flickrImage.image = UIImage(named: "placeholder")
        cell.activityIndicator.startAnimating()
        
        cell.initWithPhoto(photo)
        cell.activityIndicator.stopAnimating()
        
        if cell.isSelected {
            cell.layer.borderColor = UIColor.blue.cgColor
            cell.layer.borderWidth = 3
        } else {
            cell.layer.borderColor = UIColor.clear.cgColor
            cell.layer.borderWidth = 3
        }
        return cell
    }
    
    
    //FOLLOWING FUNCTIONS ARE FORMATING THE CELLS AND FLOW LAYOUT
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.frame.width / numberOfColumns
        return CGSize(width: width, height: width)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return .zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    
    //FUNCTION FOR SELECTING CELLS
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if selectBtn.isEnabled == false {
            let cell = collectionView.cellForItem(at: indexPath)
            if cell?.isSelected == true {
                cell?.layer.borderColor = UIColor.blue.cgColor
                cell?.layer.borderWidth = 3
                print(indexPath)
            }
        }
    }
    
    //FUNCTION FOR DESELECTING CELLS
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        if selectBtn.isEnabled == false {
            let cell = collectionView.cellForItem(at: indexPath)
            cell?.layer.borderColor = UIColor.clear.cgColor
            cell?.layer.borderWidth = 3
            cell?.isSelected = false
        }
    }
    
    
}

