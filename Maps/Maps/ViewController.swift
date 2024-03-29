//
//  ViewController.swift
//  Maps
//
//  Created by Will Watkins on 28/10/2019.
//  Copyright © 2019 Will Watkins. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import Alamofire
import SwiftyJSON

class ViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    
    var latitude = String()
    var longitude = String()
    
    //MARK: - structs
    struct PlacesData:Decodable {
        var response: Response
    }
    
    struct Response:Decodable {
        var places: [Places]
    }
    
    struct Places: Decodable {
        var name: String
        var location: Location
    }
    
    struct Location: Decodable {
        var lat: String
        var lng: String
    }
    
    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var scSegment: UISegmentedControl!
    @IBOutlet weak var trafficSwitch: UISwitch!
    @IBOutlet weak var trafficView: UIView!
    @IBOutlet weak var trafficTextLabel: UITextField!
    
    @IBAction func refreshButton(_ sender: UIButton) {
        let allAnnotations = self.mapView.annotations
        self.mapView.removeAnnotations(allAnnotations)
        self.mapView.removeOverlays(self.mapView.overlays)
    }
    
    @IBAction func removeRoute(_ sender: Any) {
        self.mapView.removeOverlays(self.mapView.overlays)
    }
    
    @IBAction func myLocation(_ sender: Any) {
        if let coor = mapView.userLocation.location?.coordinate {
            mapView.setCenter(coor, animated: true)
            mapView.showsUserLocation = true
        }
    }

    @IBAction func scSegmentTapped(_ sender: Any) {
        let getIndex = scSegment.selectedSegmentIndex
        print(getIndex)
        
        switch (getIndex) {
        case 0: self.mapView.mapType = .standard
        case 1: self.mapView.mapType = .hybrid
            
        default:
            print("No maptype currently selected")
        }
    }

    @IBAction func trafficSwitchChanges(_ sender: Any) {
        if trafficSwitch.isOn {
            mapView.showsTraffic = true
        } else {
            mapView.showsTraffic = false
        }
    }
    
       
    //MARK: - Getting user location
    var locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        searchTextField.delegate = self
        locationManager.requestWhenInUseAuthorization()
        //trafficView.backgroundColor = UIColor.white.withAlphaComponent(0.5)
        trafficView.layer.cornerRadius = 10
        trafficTextLabel.layer.borderWidth = 0
       
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.startUpdatingLocation()
        }
        
        mapView.delegate = self
        mapView.mapType = .standard
        mapView.showsCompass = true
        mapView.isZoomEnabled = true
        mapView.isScrollEnabled = true
        mapView.showsCompass = true
               
        if let coor = mapView.userLocation.location?.coordinate {
            mapView.setCenter(coor, animated: true)
            mapView.showsUserLocation = true
        }
    }
    
    //MARK: - Map
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location: CLLocationCoordinate2D = manager.location!.coordinate
        
        mapView.mapType = .standard
        let span = MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        let region = MKCoordinateRegion(center: location, span: span)
        mapView.setRegion(region, animated: true)
        
        locationManager.stopUpdatingLocation()
        //print("lng= \(location.longitude) & lat= \(location.latitude)")
        
        latitude = String(location.latitude)
        longitude = String(location.longitude)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error)
    }
    
    func mapView(_ mapView: MKMapView, didFailToLocateUserWithError error: Error) {
        print("Unable to determine location, error: \(error)")
    }
    
//MARK: - Directions to selected pin
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
       let sourceLocation = CLLocationCoordinate2D(latitude: Double(latitude)!, longitude: Double(longitude)!)
        
        let destinationLocation = view.annotation?.coordinate
        
        let sourcePlacemark = MKPlacemark(coordinate: sourceLocation)
        let destinationPlacemark = MKPlacemark(coordinate: destinationLocation!)
        
        let sourceMapItem = MKMapItem(placemark: sourcePlacemark)
        let destinationMapItem = MKMapItem(placemark: destinationPlacemark)
        
        let sourceAnnotation = MKPointAnnotation()
        if let location = sourcePlacemark.location {
            sourceAnnotation.coordinate = location.coordinate
        }
        
        let destinationAnnotation = MKPointAnnotation()
        if let location = destinationPlacemark.location {
            destinationAnnotation.coordinate = location.coordinate
        }
        
        self.mapView.showAnnotations([sourceAnnotation, destinationAnnotation], animated: true)
        
        let directionRequest = MKDirections.Request()
        directionRequest.source = sourceMapItem
        directionRequest.destination = destinationMapItem
        directionRequest.transportType = .walking
        
        let directions = MKDirections(request: directionRequest)
        
        directions.calculate { (response, error) in
            guard let response = response else {
                if error != nil {
                    print("Error \(error)")
                }
                return
            }
            let route = response.routes[0]
            
            self.mapView.addOverlay(route.polyline, level: .aboveRoads)
            
            let rect = route.polyline.boundingMapRect
            self.mapView.setRegion(MKCoordinateRegion(rect), animated: true)
        }
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay)
        
        renderer.strokeColor = .blue
        renderer.lineWidth = 5.0
        return renderer
    }

    //MARK: - JSON decoder
    func performRequest(url: String){
        print(url)
        guard let url = URL(string: url) else {return}
        
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard let data = data else {return
            }
            do{
                let decoder = JSONDecoder()
                let places = try decoder.decode(PlacesData.self, from: data)
                print(places.response.places[0].location)
                for each in places.response.places {
                    let mapAnnotation = MKPointAnnotation()
                    mapAnnotation.coordinate = CLLocationCoordinate2D(latitude: Double(each.location.lat)!, longitude: Double(each.location.lng)!)
                    mapAnnotation.title = each.name
                    
                    DispatchQueue.main.async {
                        self.mapView.addAnnotation(mapAnnotation)
                    }
                }
            } catch let error{
                print("error serialising json, the error is: ", error)
            }
            let dataString = String(data: data, encoding: .utf8)!
            print(dataString)
        }
        .resume()
    }
}

//MARK: - TextFieldDelegate
extension ViewController: UITextFieldDelegate {
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        searchTextField.endEditing(true)
        print(searchTextField.text!)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        print(searchTextField.text!)
        if let keyword = searchTextField.text {
            let finalURL = "https://mps.mxdata.co.uk/request/execute/?cid=rootle:1&rid=ksearch&p=what:\(keyword);lat:\(latitude);lng:\(longitude);maxresults:20;skipcount:0"
            //getLocalMapData(url: finalURL)
            performRequest(url: finalURL)
            searchTextField.endEditing(true)
        }
        
        return true
    }
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        if searchTextField.text != "" {
            return true
        } else {
            textField.placeholder = "Search pizza?"
            return false
        }
    }
    func textFieldDidEndEditing(_ textField: UITextField, reason: UITextField.DidEndEditingReason) {
        searchTextField.text = ""
        textField.placeholder = "Search"
    }
}


