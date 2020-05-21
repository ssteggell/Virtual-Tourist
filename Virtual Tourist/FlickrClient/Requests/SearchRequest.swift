//
//  SearchRequest.swift
//  Virtual Tourist
//
//  Created by Spencer Steggell on 5/19/20.
//  Copyright © 2020 Spencer Steggell. All rights reserved.
//

import Foundation


struct SearchRequest: Codable {
    let apikey: String
    let lat: String
    let lon: String
    
    enum CodingKeys: String, CodingKey {
        case apikey = "api_key"
        case lat
        case lon
        
    }
    
}
