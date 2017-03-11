//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by Temirlan on 05.03.17.
//  Copyright © 2017 Temirlan. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class PhotoAlbumViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    @IBOutlet weak var toolItem: UIBarButtonItem!
    
    var pin: Pin!
    
    var photos = [Photo]()
    var photosToDelete = [Photo]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        getPhotos()
        setupMapView()
        setupFlowLayout()
    }
    
    @IBAction func getNewCollection(_ sender: Any) {
        if photosToDelete.count == 0 {
            for photo in photos {
                CoreDataStack.shared.context.delete(photo)
            }
            
            CoreDataStack.shared.save()
            photos = [Photo]()
            collectionView.reloadData()
            getPhotos()
        } else {
            for photo in photosToDelete {
                CoreDataStack.shared.context.delete(photo)
                photos.remove(at: photos.index(of: photo)!)
            }
            
            photosToDelete = [Photo]()
            CoreDataStack.shared.save()
            collectionView.reloadData()
        }
        
        updateToolbar()
    }
    
    func getPhotos() {
        if let fetchResult = fetchPhotos() {
            photos = fetchResult
        } else {
            RequestEngine.shared.getPhotos(with: pin.latitude, longitude: pin.longitude) { (photoUrls, error) in
                if let photoUrls = photoUrls {
                    for url in photoUrls {
                        let photo = Photo(context: CoreDataStack.shared.context)
                        photo.url = url
                        photo.pin = self.pin
                        
                        self.photos.append(photo)
                    }
                    
                    CoreDataStack.shared.save()
                    
                    DispatchQueue.main.async {
                        self.collectionView.reloadData()
                    }
                }
            }
        }
    }
    
    func fetchPhotos() -> [Photo]? {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Photo")
        let predicate = NSPredicate(format: "pin == %@", argumentArray: [pin])
        fetchRequest.predicate = predicate
        
        do {
            if let result = try CoreDataStack.shared.context.fetch(fetchRequest) as? [Photo] {
                return result.count > 0 ? result : nil
            }
        } catch {
            print("Error getting data")
        }
        
        return nil
    }
    
    func setupMapView() {
        let annotation = MKPointAnnotation()
        annotation.coordinate = CLLocationCoordinate2DMake(CLLocationDegrees(pin.latitude), CLLocationDegrees(pin.longitude))
        mapView.addAnnotation(annotation)
        
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(annotation.coordinate, 1000, 1000)
        mapView.setRegion(coordinateRegion, animated: true)
    }
    
}

extension PhotoAlbumViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photos.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! CollectionViewCell
        
        let photo = self.photos[indexPath.row]
        
        cell.imageView.image = nil
        cell.activityIndicator.isHidden = false
        cell.contentView.alpha = photosToDelete.contains(photo) ? 0.4 : 1.0
        
        if let imageData = photo.image {
            let image = UIImage(data: imageData as Data)
            cell.imageView.image = image
            cell.activityIndicator.isHidden = true
        } else {
            cell.activityIndicator.startAnimating()
            
            RequestEngine.shared.downloadImage(with: photo.url!) { (data, error) in
                if error == nil {
                    let downloadedImage = UIImage(data: data!)
                    photo.image = data as NSData?

                    DispatchQueue.main.async {
                        cell.imageView.image = downloadedImage
                        cell.activityIndicator.stopAnimating()
                        cell.activityIndicator.isHidden = true
                    }
                }
            }
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath)
        cell?.contentView.alpha = 0.4
        
        let photo = photos[indexPath.row]
        if !photosToDelete.contains(photo) {
            photosToDelete.append(photo)
        }
        
        updateToolbar()
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath)
        let photo = photos[indexPath.row]
        
        if photosToDelete.contains(photo) {
            cell?.contentView.alpha = 1.0
            photosToDelete.remove(at: photosToDelete.index(of: photo)!)
        }
        
        updateToolbar()
    }
    
    func updateToolbar() {
        toolItem.title = photosToDelete.count > 0 ? "Delete photos" : "New Collection"
        toolItem.tintColor = photosToDelete.count > 0 ? .red : view.tintColor
    }
    
    func setupFlowLayout() {
        collectionView.allowsMultipleSelection = true
        
        let space: CGFloat = 3.0
        let dimension = (view.frame.size.width - (2 * space)) / 3.0
        
        flowLayout.minimumInteritemSpacing = space
        flowLayout.minimumLineSpacing = space
        flowLayout.itemSize = CGSize(width: dimension, height: dimension)
    }
    
}
