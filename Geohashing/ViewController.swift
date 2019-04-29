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
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationController?.navigationBar.isTranslucent = true
    }
    
    func disableMyLocationBasedFeatures() {
        print("Disabled")
    }
 
    func enableMyWhenInUseFeatures() {
        let dateToHash = Date()
        let components = Calendar.current.dateComponents([.day, .month, .year], from: dateToHash)
        
        let y = components.year ?? 0
        let m = components.month ?? 0
        var d = components.day ?? 0
        d -= 1
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
    }
    
    func addLocationAnnotations() {
        DispatchQueue.main.async {
            for lon in  -179...179 {
                for lat in -89...89 {
                    let corner = CLLocationCoordinate2D(latitude: Double(lat), longitude: Double(lon))
                    let hashLocation = self.merge(currentLocation: corner, withOffset: self.offset)
                    var title : String
                    if self.stockIndicator != nil {
                        title = "[\(lat),\(lon)]\n\(self.datePrefix)-\(self.stockIndicator!)"
                    } else {
                        title = "[\(lat),\(lon)]\nGeohash"
                    }
                    
                    let pos = GeohashMarker(title,
                                            location: hashLocation)
                    
                    self.mapView.addAnnotation(pos )
                }
            }
            self.mapView.setNeedsDisplay()
        }
    }


    fileprivate func convertSeedToLatLonOffset() {
        guard let si = self.stockIndicator else {
            return
        }
        let seed = "\(self.datePrefix)-\(si)"
        var latitudeHexOffset = seed.md5
        latitudeHexOffset.removeLast(16)
        var longitudeHexOffset = seed.md5
        longitudeHexOffset.removeFirst(16)
        
        let lat = latitudeHexOffset.asDecimalFraction(radix: 16)
        let lon = longitudeHexOffset.asDecimalFraction(radix: 16)
        self.offset = CLLocationCoordinate2D(latitude: lat,
                                             longitude: lon)
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
        guard let annotation = annotation as? GeohashMarker else {
            return nil
        }
        var view : MKMarkerAnnotationView
        if let dequeuedView = mapView.dequeueReusableAnnotationView(withIdentifier: "marker")
            as? MKMarkerAnnotationView {
            dequeuedView.annotation = annotation
            view = dequeuedView
        } else  {
            view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: "marker")
            view.canShowCallout = true
            view.calloutOffset = CGPoint(x: -5, y: -5)
            view.rightCalloutAccessoryView = UIButton(type:.detailDisclosure)
        }
        
        return view
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        guard let location = view.annotation as? GeohashMarker else {
            return
        }
        let launchOptions = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
        location.mapItem().openInMaps(launchOptions: launchOptions)
    }

}



extension String {
    // Attribution: https://stackoverflow.com/a/55356729
    var md5: String {
        let data = Data(self.utf8)
        let hash = data.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) -> [UInt8] in
            var hash = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
            CC_MD5(bytes.baseAddress, CC_LONG(data.count), &hash)
            return hash
        }
        return hash.map { String(format: "%02x", $0) }.joined()
    }
    
    func asDecimalFraction(radix r : Int) -> Double {
        let rDouble = Double(r)
        var offset = 0.0
        let count = self.unicodeScalars.count
        
        for i in 0..<count {
            let latChar = String(Array(self.unicodeScalars)[i])
            
            let exp = -1.0 * (Double(exactly: i+1) ?? 0.0)
            if let x = Int(latChar, radix: r) {
                offset += Double(x) * pow(rDouble, exp)
            }
        }
        return offset
    }
}
