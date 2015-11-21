//
//  FirstViewController.swift
//  breadCrumbs
//
//  Created by Ben Fallon on 11/17/15.
//  Copyright © 2015 Ben Fallon, Jen Trudell, and Katelyn Dinkgrave. All rights reserved.
//

import UIKit
import MapKit
import SwiftyJSON
import Alamofire
import CoreLocation

var everySingleCrumb = [Crumb]()

class FirstViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    
    //let userSession = Main()
    
    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
    
    @IBOutlet weak var mapView: MKMapView!
    
    let locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.mapView.delegate = self
        mapView.showsUserLocation = true
        locationManager.requestAlwaysAuthorization()
    }
    
    override func viewDidAppear(animated: Bool) {
        stopMonitoringAll()
        everySingleCrumb = [Crumb]()
        pullCrumbs("crazy@email.com")
    }
    
    func pullCrumbs(email: String){
        var counter = 0
        let pseudocrumbUrl = "https://gentle-fortress-2146.herokuapp.com/retrieve.json"
        Alamofire.request(.GET, pseudocrumbUrl, parameters:["creatorEmail": email]).validate().responseJSON { response in
            switch response.result {
            case .Success:
                if let value = response.result.value {
                    let json = JSON(value)
                        for crumb in json{
                            let crumb: Dictionary<String,JSON> = json[counter].dictionaryValue
                            let lat : Double = crumb["lat"]!.doubleValue
                            let long : Double = crumb["long"]!.doubleValue
                            let identifier : String = crumb["identifier"]!.stringValue
                            let title : String = crumb["title"]!.stringValue
                            let subtitle : String = crumb["subtitle"]!.stringValue
                            let pseudocrumb = Crumb(lat: lat, long: long, identifier: identifier, title: title, subtitle: subtitle)
                            counter += 1
                            
                            self.addCrumbs(pseudocrumb)
                            everySingleCrumb.append(pseudocrumb)
                    }
                }
            case .Failure(let error):
                print(error)
            }
        }
    }
    
    func addCrumbs(crumb: Crumb){
        self.mapView.addAnnotation(crumb)
        addRadiusCircle(crumb)
        startMonitoringCrumb(crumb)
    }

    
    func regionWithCrumb(crumb: Crumb) -> CLCircularRegion {
        let region = CLCircularRegion(center: crumb.coordinate, radius: crumb.radius, identifier: crumb.identity!)
        region.notifyOnEntry = ( true )
        region.notifyOnExit = ( false )
        print("Region Identifier:")
        print(region.identifier)
        return region
    }
    
    func startMonitoringCrumb(crumb: Crumb) {
        if !CLLocationManager.isMonitoringAvailableForClass(CLCircularRegion) {
            showSimpleAlertWithTitle("Error", message: "Geofencing is not supported on this device!", viewController: self)
            return
        }
        // 2
        if CLLocationManager.authorizationStatus() != .AuthorizedAlways {
            showSimpleAlertWithTitle("Warning", message: "Your geotification is saved but will only be activated once you grant Geotify permission to access the device location.", viewController: self)
        }
        let region = regionWithCrumb(crumb)
        locationManager.startMonitoringForRegion(region)
        
    }
    
    func stopMonitoringGeolocation(crumb: Crumb){
        for region in locationManager.monitoredRegions{
            if let circularRegion = region as? CLCircularRegion {
                if circularRegion.identifier == crumb.identity{
                    locationManager.stopMonitoringForRegion(circularRegion)
                }
            }
        }
    }
    
    func addRadiusCircle(crumb: Crumb){
        //Draws circle on the map
        let circle = MKCircle(centerCoordinate: crumb.coordinate, radius: crumb.radius)
        self.mapView.addOverlay(circle)
    }
    
//    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView!, calloutAccessoryControlTapped control: UIControl!) {
//        var crumb = view.annotation as? Crumb
//        stopMonitoringGeolocation(crumb!)
//    }
    
    func mapView(mapView: MKMapView!, rendererForOverlay overlay: MKOverlay!) -> MKOverlayRenderer!{
        if overlay is MKCircle{
            var circle = MKCircleRenderer(overlay: overlay)
            circle.strokeColor = UIColor.purpleColor()
            circle.fillColor = UIColor(red: 0, green: 150, blue: 255, alpha: 0.1)
            circle.lineWidth = 1
            return circle
        }else{
            return nil
        }
    }
    
    func stopMonitoringAll(){
        for region in locationManager.monitoredRegions{
            locationManager.stopMonitoringForRegion(region)
        }
    }

    //BEN Zoom in functionality
    @IBAction func zoomIn(sender: AnyObject) {
        let userLocation = mapView.userLocation
        let region = MKCoordinateRegionMakeWithDistance(
            userLocation.location!.coordinate, 2000, 2000)
        
        mapView.setRegion(region, animated: true)
    }

    
    //Ben- Allow map to track location
    func mapView(mapView: MKMapView!, didUpdateUserLocation
        userLocation: MKUserLocation!){
            mapView.centerCoordinate = userLocation.location!.coordinate
    }


}

