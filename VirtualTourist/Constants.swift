//
//  Constants.swift
//  VirtualTourist
//
//  Created by Temirlan on 09.03.17.
//  Copyright © 2017 Temirlan. All rights reserved.
//

struct Constants {
    static let key = "YOUR_API_KEY"
    
    static let flickrPhotos = "https://api.flickr.com/services/rest?method=flickr.photos.search&format=json&api_key=\(Constants.key)&bbox={bbox}&per_page=21&page={page}&extras=url_m&nojsoncallback=1"

}
