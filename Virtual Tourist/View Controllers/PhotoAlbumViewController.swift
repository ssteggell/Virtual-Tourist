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

class PhotoAlbumViewController: UIViewController, NSFetchedResultsControllerDelegate {
    
    enum Mode {
        case view
        case select
    }
    
    @IBOutlet weak var smallMapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var newCollectionBtn: UIButton!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var currentLatitude: Double?
    var currentLongitude: Double?
    var selectedPin: Pin!
    var savedPhotoObjects = [Photo]()
    var flickrPhotos: [FlickrPhoto] = []
    let numberOfColumns: CGFloat = 3
    var fetchedResultsController: NSFetchedResultsController<Photo>!

    
    fileprivate func reloadSavedData() -> [Photo]? {
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
            }
            return photoArray
            
        } catch {
            print("error performing fetch")
            return nil
        }
    }
    

    var mMode: Mode = .view {
        didSet {
            switch mMode {
            case .view:
                selectBtn.isEnabled = true
                navigationItem.leftBarButtonItems = nil
                if let selectedItems = collectionView.indexPathsForSelectedItems {
                    for selection in selectedItems {
                        let cell = collectionView.cellForItem(at: selection)
                        cell?.layer.borderColor = UIColor.clear.cgColor
                        cell?.layer.borderWidth = 3
                        collectionView.deselectItem(at: selection, animated: true)
                    }
                }
                collectionView.allowsMultipleSelection = false
            case .select:
                selectBtn.isEnabled = false
                navigationItem.leftBarButtonItems = [cancelBtn, deleteBtn]
                collectionView.allowsMultipleSelection = true
            }
        }
    }
    
    
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
    
    fileprivate func getFlickrPhotos() {
        _ = FlickrClient.sharedInstance.getPhotoUrl(lat: currentLatitude!, lon: currentLongitude!, page: 1) { (photos, error) in
            
            if let error = error {
                DispatchQueue.main.async {
                    self.activityIndicator.stopAnimating()
                    let alertVC = UIAlertController(title: "Error", message: "Error retrieving data", preferredStyle: .alert)
                    alertVC.addAction(UIAlertAction(title: "Okay", style: .default, handler: nil))
                    self.present(alertVC, animated: true)
                    print(error.localizedDescription)
                }
            } else {
                if let photos = photos {
                    
                    DispatchQueue.main.async {
                        self.flickrPhotos = photos
                        self.saveToCoreData(photos: photos)
                        self.activityIndicator.stopAnimating()
                        self.collectionView.reloadData()
                        self.savedPhotoObjects = self.reloadSavedData()!
                        self.showSavedResult()
                    }
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpBarButtonItems()
        smallMapView.delegate = self
        collectionView.delegate = self
        collectionView.dataSource = self
        
        //reload saved data
        let savedPhotos = reloadSavedData()
        if savedPhotos != nil && savedPhotos?.count != 0 {
            savedPhotoObjects = savedPhotos!
            showSavedResult()
        } else {
            showNewResult()
        }
        
        setCenter()
        activityIndicator.startAnimating()
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
       
    }
    
    
    @objc func selectBtnPressed(_ sender: UIBarButtonItem) {
        mMode = mMode == .view ? .select : .view
        newCollectionBtn.isEnabled = false
    }
    @objc func cancelBtnPressed(_ sender: UIBarButtonItem) {
        mMode = mMode == .select ? .view : .select
        newCollectionBtn.isEnabled = true
    }
    
    func saveToCoreData(photos: [FlickrPhoto]) {
        
                for flickrPhoto in photos {
                    let photo = Photo(context: DataController.shared.viewContext)
                    photo.urlString = flickrPhoto.imageURLString()
                    photo.pin = selectedPin
                    savedPhotoObjects.append(photo)
                    DataController.shared.save()
                }
            
        }
 
    
    func deleteExistingCoreDataPhoto() {
        
        for image in savedPhotoObjects {
            
            DataController.shared.viewContext.delete(image)
        }
    }
    
    func showSavedResult() {
        
        DispatchQueue.main.async {
            
            self.collectionView.reloadData()
        }
    }
    
    func showNewResult() {
        deleteExistingCoreDataPhoto()
        savedPhotoObjects.removeAll()
        
        getFlickrPhotos()
    }
    
    @objc func deleteBtnPressed(_ sender: UIBarButtonItem) {
        
        if let selectedIndexPaths = collectionView.indexPathsForSelectedItems {
            for indexPath in selectedIndexPaths {
                let savedPhoto = savedPhotoObjects[indexPath.row]
                for photo in savedPhotoObjects {
                    if photo.urlString == savedPhoto.urlString {
                        DataController.shared.viewContext.delete(photo)
                       try? DataController.shared.viewContext.save()
                    }
                }
            }
            savedPhotoObjects = reloadSavedData()!
            showSavedResult()
        }
    }
    
    fileprivate func getRandomFlickrImages() {
        let random = Int.random(in: 2...4)
        _ = FlickrClient.sharedInstance.getPhotoUrl(lat: currentLatitude!, lon: currentLongitude!, page: random, completion: { (photos, error) in
            
            if let error = error {
                DispatchQueue.main.async {
                    self.activityIndicator.stopAnimating()
                    let alertVC = UIAlertController(title: "Error", message: "Error retrieving data", preferredStyle: .alert)
                    alertVC.addAction(UIAlertAction(title: "Okay", style: .default, handler: nil))
                    self.present(alertVC, animated: true)
                    print(error.localizedDescription)
                }
            } else {
                if let photos = photos {
                    
                    DispatchQueue.main.async {
                        self.flickrPhotos = photos
                        self.saveToCoreData(photos: photos)
                        self.activityIndicator.stopAnimating()
                        self.savedPhotoObjects = self.reloadSavedData()!
                        self.showSavedResult()
                    }
                }
            }
        })
    }
    
    @IBAction func newCollectionBtnPressed(_ sender: Any) {
        
        
        activityIndicator.startAnimating()
        deleteExistingCoreDataPhoto()
        getRandomFlickrImages()
        activityIndicator.stopAnimating()
    }
}

extension PhotoAlbumViewController: MKMapViewDelegate {
    
    func setCenter() {
        if let latitude = currentLatitude,
            let longitude = currentLongitude {
        let center: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            smallMapView.setCenter(center, animated: true)
            let mySpan: MKCoordinateSpan = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
            let myRegion: MKCoordinateRegion = MKCoordinateRegion(center: center, span: mySpan)
            smallMapView.setRegion(myRegion, animated: true)
            let annotation: MKPointAnnotation = MKPointAnnotation()
            annotation.coordinate = center
            smallMapView.addAnnotation(annotation)
        }
    }
}

extension PhotoAlbumViewController : UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return savedPhotoObjects.count
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FlickrViewCell", for: indexPath) as! PhotoAlbumCollectionViewCell
        
        let photoObject = savedPhotoObjects[indexPath.row]
        activityIndicator.stopAnimating()
        cell.initWithPhoto(photoObject)
        
        if cell.isSelected {
            cell.layer.borderColor = UIColor.blue.cgColor
            cell.layer.borderWidth = 3
        } else {
            cell.layer.borderColor = UIColor.clear.cgColor
            cell.layer.borderWidth = 3
        }
    return cell
}

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
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if selectBtn.isEnabled == false {
            let cell = collectionView.cellForItem(at: indexPath)
            if cell?.isSelected == true {
                cell?.layer.borderColor = UIColor.blue.cgColor
                cell?.layer.borderWidth = 3
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        if selectBtn.isEnabled == false {
            let cell = collectionView.cellForItem(at: indexPath)
            cell?.layer.borderColor = UIColor.clear.cgColor
            cell?.layer.borderWidth = 3
            cell?.isSelected = false
        }
    }
    
}














//MARK: OLD CODE
/*
//private let reuseIdentifier = "PhotoAlbumCell"


class PhotoAlbumViewController: UIViewController, NSFetchedResultsControllerDelegate, MKMapViewDelegate, UICollectionViewDelegate, UICollectionViewDataSource {
    
    // MARK: Outlets
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var flickrCollectionView: UICollectionView!
    @IBOutlet weak var flowLayout: UICollectionView!
    @IBOutlet weak var newCollectionButton: UIButton!
    
 
    // MARK: Properties
    
    var selectedPin : Pin!
    var photoData : [Photo] = [Photo]()
    var savedPhotos = [Photo]()
    var flickrPhotos : [FlickrPhoto] = []
    var photoSelected = false
//    var currentPage = 0
     let numberOfColumns: CGFloat = 3
    var fetchedResultsController: NSFetchedResultsController<Photo>!
    
    var flickrClient = FlickrClient()
    
//    let delegate = UIApplication.shared.delegate as! AppDelegate

    
    
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
            return nil
        }
    }
    
    override func viewDidLoad() {
           super.viewDidLoad()
//           setUpBarButtonItems()
           mapView.delegate = self
           flickrCollectionView.delegate = self
           flickrCollectionView.dataSource = self
//           getFlickrPhotos()
//        fetchPhotos()
//           reload saved data
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
//
//           setCenter()
//           activityIndicator.startAnimating()
           
           
       }
    
      func getFlickrPhotos(){
               
        FlickrClient.sharedInstance.getPhotoUrl(lat: selectedPin.latitude, lon: selectedPin.longitude, page: 1) { (photos, error) in
                   
            if let error = error {
                print("Error pulling data from Flickr")
                print(error.localizedDescription)
                return
            } else {
                
                if let photos = photos {
                    DispatchQueue.main.async {
                        self.flickrPhotos = photos
                        self.saveToCoreData(photos : photos)
                         print("\(photos.count) fetched")
                        self.flickrCollectionView.reloadData()
                        self.savedPhotos = self.fetchPhotos()!
                        self.showSavedResult()
                        print("\(photos.count) fetched")
                        
                    }
                }
    //                   self.displayAlert(title: "Unable to get photos from Flickr", message: error?.localizedDescription
                   }
        }
    }
    
    func reloadSavedData() {
        DispatchQueue.main.async {
            self.flickrCollectionView.reloadData()
        }
    }
    
    func showSavedResult() {
        
        DispatchQueue.main.async {
            
            self.flickrCollectionView.reloadData()
        }
    }
    
    func showNewResult() {
//        deleteExistingCoreDataPhoto()
        savedPhotos.removeAll()
        
        getFlickrPhotos()
    }
    
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
    
    
    
    //MARK: UI VIEW CONTROLLER
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        print(flickrPhotos.count)
        return savedPhotos.count
        
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
           return 1
       }

        func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "flickrPhotoCell", for: indexPath) as! PhotoAlbumCollectionViewCell

            let photo = savedPhotos[indexPath.row]
            
            
//            flickrCell.flickrImage.image = UIImage(named: "placeholder")
            cell.initWithPhoto(photo)
            if cell.isSelected {
                       cell.layer.borderColor = UIColor.blue.cgColor
                       cell.layer.borderWidth = 3
                   } else {
                       cell.layer.borderColor = UIColor.clear.cgColor
                       cell.layer.borderWidth = 3
                   }
            return cell
    }
    
    
    */
    
    //MARK: OLD OLD OLD CODE
    
    
    
    
    
    
//            flickrCell.loadingIndicator.startAnimating()
            
//            if photoData.count != 0 {
////            fetchPhotos()
//            if photo.imageData != nil {
//                //let photo = self.fetchedResultsViewController.object(at: index Path) as Photo)
//                performUIUpdatesOnMain {
//                    flickrCell.loadingIndicator.stopAnimating()
//                }
//                flickrCell.flickrImage.image = UIImage(data: photo.imageData! as Data)
//
//                }
//            else {
//                FlickrClient.sharedInstance.getDataFromURL(photo.urlString!) { (results, error) in
//                    guard let imageData = results
//                        else {
//    //                        self.displayAlert
//                            print("No Photo Data")
//                            return
//                    }
//
//                    performUIUpdatesOnMain {
//                        photo.imageData = imageData as NSData
//                        flickrCell.loadingIndicator.stopAnimating()
//                        flickrCell.flickrImage.image = UIImage(data: photo.imageData! as Data)
//                        print(photo.imageData!)
//    //                    CoreDataStack.saveContext()
//                    }
//                }
//            }
    
    
    
    
    
    
//}

                   /* Add results to photoData and reload flickrCollectionView *
                       }
                   }
               }


}
 /*
//    fileprivate func setUpFetchedResultsController() {
//        let fetchRequest: NSFetchRequest<Photo> = Photo.fetchRequest()
//       fetchRequest.sortDescriptors = []
//        let predicate = NSPredicate(format: "pin = %@", selectedPin!)
//        fetchRequest.predicate = predicate
//        let context = CoreDataStack.getContext()
//
//        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
//        fetchedResultsController.delegate = self
//        do {
//            try fetchedResultsController.performFetch()
//            print("Photos successfully fetched")
//            print(photoData)
//        } catch {
//            fatalError("Fetch Request Failed: \(error.localizedDescription)")
//        }
//
//
//    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        flickrCollectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)
//        addAnnotation()
        fetchPhotos()
        getFlickrPhotos(page: currentPage)
        createMap()
        
//        setUpFetchedResultsController()
        
        let space: CGFloat = 3.0
               let viewWidth = self.view.frame.width
               let dimension: CGFloat = (viewWidth-(2*space))/3.0
               
               collectionViewLayout.minimumInteritemSpacing = space
               collectionViewLayout.minimumLineSpacing = space
               collectionViewLayout.itemSize = CGSize(width: dimension, height: dimension)
        
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.flickrCollectionView.reloadData()
        self.flickrCollectionView.collectionViewLayout.invalidateLayout()
    }
    
  func getFlickrPhotos(page: Int){
           
           FlickrClient.sharedInstance.getImagesFromFlickr(selectedPin, currentPage) { (results, error) in
               
               guard error == nil else {
//                   self.displayAlert(title: "Unable to get photos from Flickr", message: error?.localizedDescription)
                   return
               }
               /* Add results to photoData and reload flickrCollectionView */
               performUIUpdatesOnMain {
                   if results != nil {
                       self.photoData = results!
                       
                       print("\(self.photoData.count) photos from Flickr fetched")
                       self.flickrCollectionView.reloadData()
                   }
               }
           }
       }
                    
//             flickrClient.fetchImagesWithLatitudeAndLongitude(latitude: selectedPin.latitude, longitude: selectedPin.longitude) { (data: AnyObject?, error: NSError?) -> Void in
//
//                guard let data = data else {
//                                   print("No data was returned.")
//                                   return
//                               }
//                let photoURLs = self.flickrClient.extractAllPhotoURLStrings(fromJSONDictionary: data)
//                    if !photoURLs.isEmpty {
//                    print("There were \(photoURLs.count) photos returned.")
//                        for _ in photoURLs {
//                        let newFlickrPhoto:Photo = NSEntityDescription.insertNewObject(forEntityName: "Photo", into: CoreDataStack.getContext() ) as! Photo
//
////                        newFlickrPhoto.urlString = data as! String
////                        newFlickrPhoto.pin = self.selectedPin
////                        photoData.append(photoURLs)
//                        print("Created new photo: \(String(describing: newFlickrPhoto))")
//                    }
//                }
//        }
//    }
           
    
//    func addedPhoto(urlString: String, data: Data) {
//        let context = CoreDataStack.getContext()
//        let photo : Photo = NSEntityDescription.insertNewObject(forEntityName: "Photo", into: context) as! Photo
//
//        photo.urlString = urlString
//        photo.imageData = NSData
//
//        CoreDataStack.saveContext()
//
//    }
        func createMap() {
            
//            let mapRegionDict = ["latitude": selectedPin.latitude, "longitude": selectedPin.longitude, "latitudeDelta": 0.25, "longitudeDelta": 0.25]
            let center = CLLocationCoordinate2D(latitude: selectedPin.latitude, longitude: selectedPin.longitude)
            let span = MKCoordinateSpan(latitudeDelta: 0.25, longitudeDelta: 0.25)
            let mapRegion = MKCoordinateRegion(center: center, span: span)
            //let region = mapRegion.makeMapRegion(mapRegion)
            mapView.setRegion(mapRegion, animated: true)
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = center
            self.mapView.addAnnotation(annotation)
            
        }
//    }
        
//        @IBAction func newCollectionTapped(_ sender: UIButton) {
//            if photosSelected {
//                removePhotos()
//                self.flickrCollectionView.reloadData()
//                photosSelected = false
//                newCollectionButton.setTitle("New Collection", for: .normal)
//            } else {
//                for photo in photoData {
//                    CoreDataStack.getContext().delete(photo)
//                }
//                CoreDataStack.saveContext()
//                currentPage += 1
//                getFlickrPhotos(page: currentPage)
//
//            }
//        }
        
        


//extension PhotoAlbumViewController: NSFetchedResultsControllerDelegate {
    
//    func fetchPhotos() {
//        let fetchRequest:NSFetchRequest<Photo> = Photo.fetchRequest()
//        fetchRequest.sortDescriptors = []
//        fetchRequest.predicate = NSPredicate(format: "pin = %@", selectedPin!)
//        let context = CoreDataStack.getContext()
//        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
//
//        do{
//            try fetchedResultsController.performFetch()
//
//        } catch {
//            let fetchError = error as NSError
//            print("Unable to fetch results")
//            print("\(fetchError), \(fetchError.localizedDescription)")
//
//        }
//
//        if let data = fetchedResultsController.fetchedObjects, data.count > 0 {
//            print("\(data.count) photos fetched")
//            photoData = data
//            self.flickrCollectionView.reloadData()
////            CoreDataStack.saveContext()
//        } else {
//            getFlickrPhotos(page: currentPage)
//        }
////
////
//    }
    
}


extension PhotoAlbumViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    
  

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photoData.count
    }
   


    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let flickrCell = collectionView.dequeueReusableCell(withReuseIdentifier: "flickrPhotoCell", for: indexPath) as! PhotoAlbumCollectionViewCell

        let photo = photoData[indexPath.row]
        
        
        flickrCell.flickrImage.image = UIImage(named: "placeholder")
        flickrCell.loadingIndicator.startAnimating()
        
        if photoData.count != 0 {
        fetchPhotos()
        if photo.imageData != nil {
            //let photo = self.fetchedResultsViewController.object(at: index Path) as Photo)
            performUIUpdatesOnMain {
                flickrCell.loadingIndicator.stopAnimating()
            }
            flickrCell.flickrImage.image = UIImage(data: photo.imageData! as Data)
        
            }
        else {
            FlickrClient.sharedInstance.getDataFromURL(photo.urlString!) { (results, error) in
                guard let imageData = results
                    else {
//                        self.displayAlert
                        print("No Photo Data")
                        return
                }
                
                performUIUpdatesOnMain {
                    photo.imageData = imageData as NSData
                    flickrCell.loadingIndicator.stopAnimating()
                    flickrCell.flickrImage.image = UIImage(data: photo.imageData! as Data)
                    print(photo.imageData!)
//                    CoreDataStack.saveContext()
                }
            }
        }
        if selectedIndexPaths.firstIndex(of: indexPath as NSIndexPath) != nil {
            flickrCell.flickrImage.alpha = 0.25

        } else {
            flickrCell.flickrImage.alpha = 1.0
        }
        }
        return flickrCell

    }
    
    
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {

        let cell = collectionView.cellForItem(at: indexPath) as! PhotoAlbumCollectionViewCell

        let index = selectedIndexPaths.firstIndex(of: indexPath as NSIndexPath)

        if let index = index {
            selectedIndexPaths.remove(at: index)
            cell.flickrImage.alpha = 1.0
        } else {
            selectedIndexPaths.append(indexPath as NSIndexPath)
            print(selectedIndexPaths)
            selectedIndexPaths.sort{$1.row < $0.row}
            cell.flickrImage.alpha = 0.25
        }
//        if selectedIndexPaths.count > 0 {
//
//        }




    }
    
    func addFlickrPhotoToDatabase(urlString: String, pin: Pin, fetchedResultsController: NSFetchedResultsController<Photo>) {
        let newFlickrPhoto:Photo = NSEntityDescription.insertNewObject(forEntityName: "Photo", into: CoreDataStack.getContext() ) as! Photo
        
        newFlickrPhoto.urlString = urlString
        newFlickrPhoto.pin = selectedPin
        print("Created new photo: \(String(describing: newFlickrPhoto))")
    }
        
    
    

}*/
 */
