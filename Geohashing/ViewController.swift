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
    var stockIndicator : String = ""
    var datePrefix : String = ""
    let dataUpdated = Notification.Name("dataUpdated")
    
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
    
    fileprivate func doStockMarketRequest(y year : Int, m month : Int, d day : Int) {
        let headers = ["cache-control": "no-cache"]
        
        let request = NSMutableURLRequest(url: NSURL(string: "http://geo.crox.net/djia/\(year)/\(month)/\(day)")! as URL,                                          cachePolicy: .useProtocolCachePolicy,
                                          timeoutInterval: 10.0)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = headers
        
        let session = URLSession.shared
        let dataTask = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) -> Void in
            if (error != nil) {
                print(error)
            } else {
                let httpResponse = response as? HTTPURLResponse
                if httpResponse?.statusCode == 200 {
                    self.stockIndicator = String(decoding: data!, as: UTF8.self)
                    NotificationCenter.default.post(name: self.dataUpdated, object: self)
                } else {
                    print(httpResponse ?? "no good")
                }
            }
        })
        
        dataTask.resume()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(dataUpdated(_:)),
            name: dataUpdated,
            object: nil)
    }

    func disableMyLocationBasedFeatures() {
        print("Disabled")
    }
 
    func enableMyWhenInUseFeatures() {
        print("Enabled")
        let y = 2005
        let m = 5
        let d = 26
        
        doStockMarketRequest(y: y, m: m, d: d)
        self.datePrefix =
            String(format:"%.4d-%.2d-%.2d",y,m,d)
    }

    @objc func dataUpdated(_ notification :  NSNotification) {
        DispatchQueue.main.async {
            let seed = "\(self.datePrefix)-\(self.stockIndicator)"
            print(seed)
            var latitudeHexOffset = seed.md5
            latitudeHexOffset.removeLast(16)
            var longitudeHexOffset = seed.md5
            longitudeHexOffset.removeFirst(16)
            print("\(latitudeHexOffset)-\(longitudeHexOffset)")
            
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
            print("\(latitudeOffset)-\(longitudeDecOffset)")
        }
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
