//
//  ViewController.swift
//  Geohashing
//
//  Created by Andrew Napier on 16/4/19.
//  Copyright © 2019 Andrew Napier. All rights reserved.
//
import MapKit
import Foundation
import UIKit

class ViewController: UIViewController,
        MKMapViewDelegate,
        LocationFetcherDelegate {
    
    var datePrefix : String = ""
    var location : CLLocationCoordinate2D?
    var stockIndicator : String?
    var dataFetcher = StockMarketDataFetcher(year: 2019, month: 04, day: 21)
    var locationFetcher : LocationFetcher?
    private var offset : CLLocationCoordinate2D?
    private var here : CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0)
    
    
    @IBOutlet weak var mapView: MKMapView!
    
    
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        locationFetcher = LocationFetcher(self)
        locationFetcher?.addObserver(self, forKeyPath: "current", context: nil)
        locationFetcher?.doLocationStuff()
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
    }
    
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "stockIndicator" {
            guard let stockIndicator = (object as? StockMarketDataFetcher)?.stockIndicator else {
                return
            }
            self.stockIndicator = stockIndicator
            convertSeedToLatLonOffset()
            addLocationAnnotations()
        }
        
        if keyPath == "current" {
            guard let currentPos = (object as? LocationFetcher)?.current else {
                return
            }
            self.location = currentPos
            setMapRegion()
        }
        
        if self.location != nil && self.stockIndicator != nil {
            
        }
    }
    
    func addLocationAnnotations() {
        for lon in 148...156 { //-179...179 {
            for lat in -30 ... -24 { //-89...89 {
                let corner = CLLocationCoordinate2D(latitude: Double(lon), longitude: Double(lat))
                let pos = MKPlacemark(coordinate: merge(currentLocation: corner, withOffset: self.offset))
                
                mapView.addAnnotation(pos)
            }
        }
        DispatchQueue.main.async {
            self.mapView.setNeedsDisplay()
        }
    }


    fileprivate func convertSeedToLatLonOffset() {
        guard let si = self.stockIndicator else {
            return
        }
        let seed = "\(self.datePrefix)-\(si)"
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
    
    func setMapRegion() {
        guard let l = self.location else {
            return
        }
        let midPoint = merge(currentLocation: l, withOffset: CLLocationCoordinate2D(latitude: 0.5, longitude: 0.5) )
        
        mapView.region =
        MKCoordinateRegion(
            center: midPoint,
            span: MKCoordinateSpan(latitudeDelta: 1.0, longitudeDelta: 1.0))
    }
    
    func merge(currentLocation location : CLLocationCoordinate2D,
               withOffset offset : CLLocationCoordinate2D?) -> CLLocationCoordinate2D {
        guard var ofs = offset else  {
            return location
        }
        if location.latitude < 0 {
            ofs.latitude *= -1.0
        }
        if location.longitude < 0 {
            ofs.longitude *= -1.0
        }
        let merged = CLLocationCoordinate2D(
            latitude: trunc(location.latitude) + ofs.latitude,
            longitude: trunc(location.longitude) + ofs.longitude)
        
        return merged
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        return nil
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
