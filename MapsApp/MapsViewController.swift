//
//  ViewController.swift
//  MapsApp
//
//  Created by Nalan Duman on 20.12.2021.
//

import UIKit
import MapKit
import CoreLocation
import CoreData

class MapsViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {

    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var noteTextField: UITextField!
    @IBOutlet weak var mapView: MKMapView!
    
    var locationManager = CLLocationManager()
    var selectedLatitude = Double()
    var selectedLongitude = Double()
    
    var selectedName = ""
    var selectedId : UUID?
    
    var annotationTitle = ""
    var annotationSubtitle = ""
    var annotationLongitude = Double()
    var annotationLatitude = Double()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        mapView.delegate = self
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(selectLocation(gestureRecognizer:)))
        gestureRecognizer.minimumPressDuration = 3
        mapView.addGestureRecognizer(gestureRecognizer)
        
        if selectedName != "" {
            if let uuidString = selectedId?.uuidString {
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                let context = appDelegate.persistentContainer.viewContext
                let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Location")
                fetchRequest.predicate = NSPredicate(format: "id = %@", uuidString)
                fetchRequest.returnsObjectsAsFaults = false
                
                do {
                    let results = try context.fetch(fetchRequest)
                    if results.count > 0 {
                        for result in results as! [NSManagedObject] {
                            if let name = result.value(forKey: "name") as? String {
                                annotationTitle = name
                                if let note = result.value(forKey: "note") as? String {
                                    annotationSubtitle = note
                                    if let latitude = result.value(forKey: "latitude") as? Double {
                                        annotationLatitude = latitude
                                        if let longitude = result.value(forKey: "longitude") as? Double {
                                            annotationLongitude = longitude
                                            
                                            let annotation = MKPointAnnotation()
                                            annotation.title = annotationTitle
                                            annotation.subtitle = annotationSubtitle
                                            let coordinate = CLLocationCoordinate2D(latitude: annotationLatitude, longitude: annotationLongitude)
                                            annotation.coordinate = coordinate
                                            
                                            mapView.addAnnotation(annotation)
                                            nameTextField.text = annotationTitle
                                            noteTextField.text = annotationSubtitle
                                            
                                            locationManager.stopUpdatingLocation()
                                            
                                            let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                                            let region = MKCoordinateRegion(center: coordinate, span: span)
                                            mapView.setRegion(region, animated: true)
                                        }
                                    }
                                }
                            }
                        }
                    }
                } catch {
                    print("hata")
                }
            }
        } else {
            
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        let reuseId = "myAnnotation"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId)
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView?.canShowCallout = true
            pinView?.tintColor = .purple
            
            let button = UIButton(type: .detailDisclosure)
            pinView?.rightCalloutAccessoryView = button
        } else {
            pinView?.annotation = annotation
        }
        
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if selectedName != "" {
            let requestLocation = CLLocation(latitude: annotationLatitude, longitude: annotationLongitude)
            
            CLGeocoder().reverseGeocodeLocation(requestLocation, completionHandler: { placemarkArray, hata in
                if let placemarks = placemarkArray {
                    if placemarks.count > 0 {
                        let newPlacemark = MKPlacemark(placemark: placemarks[0])
                        let item = MKMapItem(placemark: newPlacemark)
                        item.name = self.annotationTitle
                        
                        let launchOptions = [MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving]
                        item.openInMaps(launchOptions: launchOptions)
                    }
                }
            })
        }
    }
    
    @objc func selectLocation(gestureRecognizer : UILongPressGestureRecognizer) {
        if gestureRecognizer.state == .began {
            let selectedPoint = gestureRecognizer.location(in: mapView)
            let selectedCoordinate = mapView.convert(selectedPoint, toCoordinateFrom: mapView)
            
            selectedLatitude = selectedCoordinate.latitude
            selectedLongitude = selectedCoordinate.longitude
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = selectedCoordinate
            annotation.title = nameTextField.text
            annotation.subtitle = noteTextField.text
            mapView.addAnnotation(annotation)
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print(locations[0].coordinate.latitude)
        print(locations[0].coordinate.longitude)
        if selectedName == "" {
            let location = CLLocationCoordinate2D(latitude: locations[0].coordinate.latitude, longitude: locations[0].coordinate.longitude)
            let span = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
            let region = MKCoordinateRegion(center: location, span: span)
            mapView.setRegion(region, animated: true)
        }
    }
    
    @IBAction func saveButton(_ sender: Any) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let newLocation = NSEntityDescription.insertNewObject(forEntityName: "Location", into: context)
        newLocation.setValue(nameTextField.text, forKey: "name")
        newLocation.setValue(noteTextField.text, forKey: "note")
        newLocation.setValue(selectedLatitude, forKey: "latitude")
        newLocation.setValue(selectedLongitude, forKey: "longitude")
        newLocation.setValue(UUID(), forKey: "id")
        
        do {
            try context.save()
            print("kayıt edildi")
        } catch {
            print("hata")
        }
        
        NotificationCenter.default.post(name: NSNotification.Name("createdNewLocation"), object: nil)
        navigationController?.popViewController(animated: true)
        
    }
    
}

