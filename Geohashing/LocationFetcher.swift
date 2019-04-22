//
//  LocationFetcher.swift
//  Geohashing
//
//  Created by Andrew Napier on 22/4/19.
//  Copyright © 2019 Andrew Napier. All rights reserved.
//
import CoreLocation
import Foundation

protocol LocationFetcherDelegate {
    func disableMyLocationBasedFeatures()
    func enableMyWhenInUseFeatures()
}

class LocationFetcher : NSObject, CLLocationManagerDelegate {
    let locationManager = CLLocationManager()
    var delegate : LocationFetcherDelegate
    @objc dynamic public var current : CLLocationCoordinate2D

    
    init(_ delegate : LocationFetcherDelegate ) {
        self.delegate = delegate
        self.current = CLLocationCoordinate2D(latitude: 0, longitude: 0)
    }

    func doLocationStuff() {
        // Do any additional setup after loading the view, typically from a nib.
        
        locationManager.delegate = self
        
        switch CLLocationManager.authorizationStatus() {
        case .notDetermined:
            // Request when-in-use authorization initially
            locationManager.requestWhenInUseAuthorization()
            break
            
        case .restricted, .denied:
            // Disable location features
            self.delegate.disableMyLocationBasedFeatures()
            break
            
        case .authorizedWhenInUse, .authorizedAlways:
            // Enable location features
            self.delegate.enableMyWhenInUseFeatures()
            self.getCurrentLocation()
            break
        }
    }
    
    func getCurrentLocation() {
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        locationManager.distanceFilter = 1000.0  // In meters.
        locationManager.delegate = self
        locationManager.startUpdatingLocation()        
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let lastIndex = locations.count-1
        
        self.current = locations[lastIndex].coordinate
    }


}
