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
    
    //Cannot get past 'response'
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
    
    @IBAction func refreshButton(_ sender: UIButton) {
        let allAnnotations = self.mapView.annotations
        self.mapView.removeAnnotations(allAnnotations)
    }
    
    
    var locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        searchTextField.delegate = self
        locationManager.requestWhenInUseAuthorization()
        
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
    
    
    
    
    //MARK: - Location
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



