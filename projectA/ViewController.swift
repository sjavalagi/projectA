//
//  ViewController.swift
//  projectA
//
//  Created by Shivachandra Javalagi on 04/01/18.
//  Copyright © 2018 Shivachandra Javalagi. All rights reserved.
//

import UIKit
import MapKit

class ViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {

    @IBOutlet weak var myMapView: MKMapView!
    
    var locationManager = CLLocationManager()
    var myAnnotation : MKPointAnnotation = MKPointAnnotation()
    var userLocation = CLLocation()
    var objectLocation = CLLocation()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        myMapView.delegate = self
        locationManager.delegate = self
        self.getCurrentLocation()
        
        //add single tapgesture to select object placement location
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.singleTapped(_:)))
        tapGesture.numberOfTapsRequired = 1
        myMapView.addGestureRecognizer(tapGesture)
    }

    //handle tapped gesture
    @objc func singleTapped(_ gestureRecognizer: UITapGestureRecognizer ) {
        
        let touchPoint = gestureRecognizer.location(in: self.myMapView)
        
        let tapLocation : CLLocationCoordinate2D = self.myMapView.convert(touchPoint, toCoordinateFrom: self.myMapView)
        print("Location found on Map: %f %f",tapLocation.latitude,tapLocation.longitude);

        self.myMapView.removeAnnotations(myMapView.annotations)
        self.myMapView.addAnnotation(myAnnotation)
        
        let newAnnotation: MKPointAnnotation = MKPointAnnotation()
        newAnnotation.coordinate = CLLocationCoordinate2DMake(tapLocation.latitude, tapLocation.longitude)
        newAnnotation.title = "Object Location!"
        myMapView.addAnnotation(newAnnotation)
        
        objectLocation =  CLLocation(latitude: tapLocation.latitude, longitude: tapLocation.longitude)
    }
    
    /*
    func removeAllAnnotations()
    {
        self.myMapView.removeAnnotations(myMapView.annotations)
        self.myMapView.addAnnotation(myAnnotation)
    }*/
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func getCurrentLocation()
    {
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.requestWhenInUseAuthorization()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        //Get Current Location
        userLocation = locations[0] as CLLocation
        //set objectLocation same as userLocation first time
        //case : user pressed arview without object selection
        objectLocation = locations[0] as CLLocation
        
        myAnnotation.coordinate = CLLocationCoordinate2DMake(userLocation.coordinate.latitude, userLocation.coordinate.longitude)
        myAnnotation.title = "User Location!"
        myMapView.addAnnotation(myAnnotation)
        //stop updating location once object location is selected
        //save battery
        manager.stopUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Error \(error)")
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
            
        case .authorizedWhenInUse:
            print("Location services authorised when in use by user")
            DispatchQueue.main.async(execute: {
                manager.startUpdatingLocation()
            })
            
        case .authorizedAlways:
             print("Location services authorised always by user")
             DispatchQueue.main.async(execute: {
                manager.startUpdatingLocation()
             })
            
        case .denied:
            print("Location services denied by user")
            self.alertLocationIssue()
            
        case .notDetermined:
            print("Location services could not be determined")
            manager.requestWhenInUseAuthorization()
            
        case .restricted:
            print("Location services restricted by user")
            self.alertLocationIssue()
        }
    }
    
    func alertLocationIssue(){
        let alert = UIAlertController(title: "Error getting  Location!", message:"Please turn on Privacy -> Location Services -> ProjectA", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default) { _ in })
        self.present(alert, animated: true){}
    }
    
    @IBAction func cancelSegue(segue:UIStoryboardSegue) {
        self.presentingViewController?.dismiss(animated: true, completion: {
        })
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        if segue.identifier == "arViewIdentifier" {
            let arVC : ARViewController = segue.destination as! ARViewController
            arVC.userLocation = self.userLocation
            arVC.objectLocation = self.objectLocation
        }
    }
}
