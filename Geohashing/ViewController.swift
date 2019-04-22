//
//  ViewController.swift
//  Geohashing
//
//  Created by Andrew Napier on 16/4/19.
//  Copyright © 2019 Andrew Napier. All rights reserved.
//
import CoreLocation
import MapKit
import Foundation
import UIKit

class ViewController: UIViewController,
        CLLocationManagerDelegate,
        MKMapViewDelegate {
    let locationManager = CLLocationManager()
    
    var datePrefix : String = ""
    var dataFetcher = StockMarketDataFetcher(year: 2019, month: 04, day: 21)
    private var offset : CLLocationCoordinate2D?
    
    @IBOutlet weak var mapView: MKMapView!
    
    
    fileprivate func doLocationStuff() {
        // Do any additional setup after loading the view, typically from a nib.
        
        locationManager.delegate = self
        
        switch CLLocationManager.authorizationStatus() {
        case .notDetermined:
            // Request when-in-use authorization initially
            locationManager.requestWhenInUseAuthorization()
            break
            
        case .restricted, .denied:
            // Disable location features
            disableMyLocationBasedFeatures()
            break
            
        case .authorizedWhenInUse, .authorizedAlways:
            // Enable location features
            enableMyWhenInUseFeatures()
            break
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        doLocationStuff()
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    func disableMyLocationBasedFeatures() {
        print("Disabled")
    }
 
    func enableMyWhenInUseFeatures() {
        let y = 2005
        let m = 5
        let d = 26
        dataFetcher = StockMarketDataFetcher(year: y, month: m, day: d)
        dataFetcher.addObserver(self, forKeyPath: "stockIndicator", context: nil)
        dataFetcher.doFetch()
        self.datePrefix =
            String(format:"%.4d-%.2d-%.2d",y,m,d)
        getCurrentLocation()
    }
    
    func getCurrentLocation() {
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        locationManager.distanceFilter = 1000.0  // In meters.
        locationManager.delegate = self
        locationManager.startUpdatingLocation()

    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "stockIndicator" {
            guard let stockIndicator = (object as? StockMarketDataFetcher)?.stockIndicator else {
                return
            }
            
            convertSeedToLatLonOffset(stockIndicator)
        }
    }

    fileprivate func convertSeedToLatLonOffset(_ stockIndicator : String) {
        let seed = "\(self.datePrefix)-\(stockIndicator)"
        print(seed)
        var latitudeHexOffset = seed.md5
        latitudeHexOffset.removeLast(16)
        var longitudeHexOffset = seed.md5
        longitudeHexOffset.removeFirst(16)
        
        var latitudeOffset = 0.0
        var longitudeDecOffset = 0.0
        for i in 0..<16 {
            let latChar = String(Array(latitudeHexOffset.unicodeScalars)[i])
            let lonChar = String(Array(longitudeHexOffset.unicodeScalars)[i])
            
            let exp = -1.0 * (Double(exactly: i+1) ?? 0.0)
            if let x = Int(latChar, radix:16) {
                latitudeOffset += Double(x) * pow(16.0, exp)
            }
            if let y = Int(lonChar, radix:16) {
                longitudeDecOffset += Double(y) * pow(16.0, exp)
            }
        }
        self.offset = CLLocationCoordinate2D(latitude: latitudeOffset,
                                             longitude: longitudeDecOffset)
        print("calculated offset: \(String(describing:offset))")
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("Number of locations: \(locations.count)")
        let l = locations[0]
        
        let cachePoint = merge(currentLocation: l, withOffset: self.offset)
        print(cachePoint)
        mapView.region =
        MKCoordinateRegion(
            center: cachePoint,
            latitudinalMeters: 200.0,
            longitudinalMeters: 200.0)
//        MKCoordinateRegion(center: <#T##CLLocationCoordinate2D#>, span: <#T##MKCoordinateSpan#>)
    }
    
    func merge(currentLocation location : CLLocation,
               withOffset offset : CLLocationCoordinate2D?) -> CLLocationCoordinate2D {
        guard let ofs = offset else  {
            return CLLocationCoordinate2D(latitude: location.coordinate.latitude,
                                          longitude: location.coordinate.longitude)
        }
        return CLLocationCoordinate2D(
            latitude: trunc(location.coordinate.latitude) + ofs.latitude,
            longitude: trunc(location.coordinate.longitude) + ofs.longitude)
    }
}


// Attribution: https://stackoverflow.com/a/55356729
extension String {
    var md5: String {
        let data = Data(self.utf8)
        let hash = data.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) -> [UInt8] in
            var hash = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
            CC_MD5(bytes.baseAddress, CC_LONG(data.count), &hash)
            return hash
        }
        return hash.map { String(format: "%02x", $0) }.joined()
    }
}
