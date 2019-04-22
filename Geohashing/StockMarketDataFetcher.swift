//
//  StockMarketDataFetcher.swift
//  Geohashing
//
//  Created by Andrew Napier on 21/4/19.
//  Copyright © 2019 Andrew Napier. All rights reserved.
//

import Foundation

class StockMarketDataFetcher : NSObject {
    private let day : Int
    private let month : Int
    private let year : Int
    @objc dynamic public var stockIndicator : String?

    init(year y : Int, month m : Int, day d : Int) {
        year = y
        month = m
        day = d
    }

    public func doFetch() {
        let headers = ["cache-control": "no-cache"]
        
        let request = NSMutableURLRequest(url: NSURL(string: "http://geo.crox.net/djia/\(year)/\(month)/\(day)")! as URL,                                          cachePolicy: .useProtocolCachePolicy,
                                          timeoutInterval: 10.0)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = headers
        
        let session = URLSession.shared
        let dataTask = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) -> Void in
            if (error != nil) {
                print(error ?? "No Error?")
                self.stockIndicator = "12345.67"
            } else {
                let httpResponse = response as? HTTPURLResponse
                if httpResponse?.statusCode == 200 {
                    self.stockIndicator = String(decoding: data!, as: UTF8.self)
                } else {
                    print(httpResponse ?? "no good")
                }
            }
        })
        
        dataTask.resume()
    }

    
}
