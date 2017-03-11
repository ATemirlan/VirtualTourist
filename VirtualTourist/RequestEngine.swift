//
//  RequestEngine.swift
//  VirtualTourist
//
//  Created by Temirlan on 09.03.17.
//  Copyright © 2017 Temirlan. All rights reserved.
//

import UIKit

class RequestEngine: NSObject {
    
    static let shared = RequestEngine()
    
    func downloadImage(with url: String, completion: @escaping(_ data: Data?, _ error: String?) -> Void) {
        dataTask(with: url, conertData: false) { (response, error) in
            completion(response as? Data, error)
        }
    }
    
    func getPhotos(with latitude: Double, longitude: Double, completion: @escaping(_ imageUrls: [String]?, _ error: String?) -> Void) {
        let rangeStr = buildBbox(lat: latitude, lon: longitude)
        
        var url = Constants.flickrPhotos.replacingOccurrences(of: "{bbox}", with: String(rangeStr))
        url = url.replacingOccurrences(of: "{page}", with: "\(arc4random_uniform(10) + 1)")
        
        dataTask(with: url, conertData: true) { (response, error) in
            if let _ = error {
                completion(nil, error)
            } else {
                var photoUrls = [String]()
                
                if let dict = response!["photos"] as? [String : AnyObject] {
                    if let photos = dict["photo"] as? [[String:AnyObject]] {
                        for photo in photos {
                            if let photoUrl = photo["url_m"] as? String {
                                photoUrls.append(photoUrl)
                            }
                        }
                    }
                }
                
                completion(photoUrls, nil)
            }
        }
    }
    
    private func buildBbox(lat: Double, lon: Double) -> String {
        let minLon = (lon - 1 > -180.0) ? lon - 1 : -180.0
        let maxLon = (lon + 1 < 180.0) ? lon + 1 : 180.0
        
        let minLat = (lat - 1 > -90) ? lat - 1 : -90
        let maxLat = (lat + 1 < 90) ? lat + 1 : 90
        
        return "\(minLon),\(minLat),\(maxLon),\(maxLat)"
    }
    
    private func dataTask(with url: String, conertData: Bool, completion: @escaping(_ response: AnyObject?, _ error: String?) -> Void) {
        
        let request = NSMutableURLRequest(url: URL(string: url)!)
        
        let task = URLSession.shared.dataTask(with: request as URLRequest) { (data, response, error) in
            
            guard (error == nil) else {
                completion(nil, "There was an error with your request")
                return
            }
            
            guard let data = data else {
                completion(nil, "No data was returned by the request!")
                return
            }
            
            guard let code = (response as? HTTPURLResponse)?.statusCode, (200...299).contains(code) else {
                completion(nil, "Not a successfull status code")
                return
            }
            
            if conertData {
                self.convertData(data, completion: completion)
            } else {
                completion(data as AnyObject?, nil)
            }
        }
        
        task.resume()
    }
    
    private func convertData(_ data: Data, completion: (_ response: AnyObject?, _ error: String?) -> Void) {
        var parsedResult: AnyObject! = nil
        
        do {
            parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as AnyObject
        } catch {
            completion(nil, "Error parsing json")
        }
        
        completion(parsedResult, nil)
    }
    
}
