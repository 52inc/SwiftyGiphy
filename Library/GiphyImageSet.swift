//
//  GiphyImageSet.swift
//  Pods
//
//  Created by Brendan Lee on 3/9/17.
//
//

import Foundation
import ObjectMapper

public struct GiphyImageSet: Mappable {
    
    public fileprivate(set) var url: URL?
    
    public fileprivate(set) var width: Int = 0
    
    public fileprivate(set) var height: Int = 0
    
    public fileprivate(set) var size: UInt64 = 0
    
    public fileprivate(set) var mp4URL: URL?
    
    public fileprivate(set) var mp4Size: UInt64 = 0
    
    public fileprivate(set) var webpURL: URL?
    
    public fileprivate(set) var webpSize: UInt64 = 0
    
    fileprivate var widthString: String = "" {
        didSet {
            width = Int(widthString) ?? 0
        }
    }
    
    fileprivate var heightString: String = "" {
        didSet {
            height = Int(heightString) ?? 0
        }
    }
    
    fileprivate var sizeString: String = "" {
        didSet {
            size = UInt64(sizeString) ?? 0
        }
    }
    
    fileprivate var mp4SizeString: String = "" {
        didSet {
            mp4Size = UInt64(mp4SizeString) ?? 0
        }
    }
    
    fileprivate var webpSizeString: String = "" {
        didSet {
            webpSize = UInt64(webpSizeString) ?? 0
        }
    }
    
    public init?(map: Map)
    {
        
    }
    
    mutating public func mapping(map: Map) {
        
        url                 <- (map["url"], URLTransform())
        widthString         <- map["width"]
        heightString        <- map["height"]
        sizeString          <- map["size"]
        mp4URL              <- (map["mp4"], URLTransform())
        mp4SizeString       <- map["mp4_size"]
        webpURL             <- (map["webp"], URLTransform())
        webpSizeString      <- map["webp_size"]
    }
}
