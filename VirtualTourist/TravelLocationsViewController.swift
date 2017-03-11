//
//  TravelLocationsViewController.swift
//  VirtualTourist
//
//  Created by Temirlan on 05.03.17.
//  Copyright © 2017 Temirlan. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class TravelLocationsViewController: UIViewController, NSFetchedResultsControllerDelegate {

    let segue = "PhotoCollectionSegue"
    var shouldDelete = false
    
    @IBOutlet weak var barItem: UIBarButtonItem!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var deleteLabelConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Pin")
        
        do {
            if let result = try CoreDataStack.shared.context.fetch(fetchRequest) as? [Pin] {
                for pin in result {
                    let annotation = MKPointAnnotation()
                    annotation.coordinate = CLLocationCoordinate2D(latitude: CLLocationDegrees(pin.latitude),longitude: CLLocationDegrees(pin.longitude))
                    mapView.addAnnotation(annotation)
                }
            }
        } catch {
            print("Couldn't find any Pins")
        }
    }

    @IBAction func edit(_ sender: UIBarButtonItem) {
        deleteLabelConstraint.constant = deleteLabelConstraint.constant == 0 ? -64.0 : 0
        barItem.title = deleteLabelConstraint.constant == 0 ? "Edit" : "Done"
        shouldDelete = deleteLabelConstraint.constant == 0 ? false : true
        
        UIView.animate(withDuration: 0.2) { 
            self.view.layoutIfNeeded()
        }
    }
    
    @IBAction func addPin(_ sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
            let touchLocation = sender.location(in: mapView)
            let coordinate = mapView.convert(touchLocation, toCoordinateFrom: mapView)
            
            let pin = Pin(context: CoreDataStack.shared.context)
            pin.latitude = Double(coordinate.latitude)
            pin.longitude = Double(coordinate.longitude)
            CoreDataStack.shared.save()
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            mapView.addAnnotation(annotation)
        }
    }
}

extension TravelLocationsViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        var view: MKPinAnnotationView
        
        if let dequeuedView = mapView.dequeueReusableAnnotationView(withIdentifier: "pin")
            as? MKPinAnnotationView {
            dequeuedView.annotation = annotation
            view = dequeuedView
        } else {
            view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "pin")
            view.animatesDrop = true
        }
        
        return view
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        mapView.deselectAnnotation(view.annotation, animated: true)
        
        if let annotation = view.annotation {
            
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Pin")
            let predicate = NSPredicate(format: "latitude == %@ AND longitude == %@", argumentArray: [annotation.coordinate.latitude, annotation.coordinate.longitude])
            fetchRequest.predicate = predicate
            
            do {
                if let result = try CoreDataStack.shared.context.fetch(fetchRequest) as? [Pin], let pin = result.first {
                    if shouldDelete {
                        CoreDataStack.shared.context.delete(pin)
                        CoreDataStack.shared.save()
                        
                        mapView.removeAnnotation(annotation)
                    } else {
                        performSegue(withIdentifier: segue, sender: pin)
                    }
                }
            } catch {
                print("Couldn't find any Pins")
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == self.segue {
            let vc = segue.destination as! PhotoAlbumViewController
            vc.pin = sender as! Pin
        }
    }
    
}
