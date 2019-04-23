//
//  GeohashMarker.swift
//  Geohashing
//
//  Created by Andrew Napier on 23/4/19.
//  Copyright © 2019 Andrew Napier. All rights reserved.
//

import Foundation
import MapKit


@objc class GeohashMarker : NSObject, MKAnnotation {
    var title : String?
    var coordinate : CLLocationCoordinate2D
    
    init(_ title : String, location coord : CLLocationCoordinate2D) {
        self.title = title
        self.coordinate = coord
    }
    
    
}
