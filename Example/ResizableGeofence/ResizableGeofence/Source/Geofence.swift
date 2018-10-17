//
//  Geofence.swift
//  ResizableGeofence
//
//  Created by Siddharth Paneri on 05/06/18.
//  Copyright © 2018 Siddharth Paneri. All rights reserved.
//

import UIKit
import MapKit

//1609.34 meters = 1 mile
//
//
let DEFAULT_RADIUS : CLLocationDistance = 2000 //meters
let DEFAULT_MIN_RADIUS : CLLocationDistance = 50 //meters
let DEFAULT_MAX_RADIUS : CLLocationDistance = 30000 //meters
let DEFAULT_STEP_RADIUS : CLLocationDistance = 10 //meters or feet or yard

struct GeofenceKey {
    static let latitude = "siddharthpaneri.geofence.latitude"
    static let longitude = "siddharthpaneri.geofence.longitude"
    static let radius = "siddharthpaneri.geofence.radius"
    static let identifier = "siddharthpaneri.geofence.identifier"
}

class Geofence: NSObject, NSCoding, MKAnnotation {
    
    var coordinate : CLLocationCoordinate2D
    var radius : CLLocationDistance
    var identifier : String
    init(coordinate : CLLocationCoordinate2D, radius : CLLocationDistance, identifier : String) {
        self.coordinate = coordinate
        self.radius = radius
        self.identifier = identifier
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(coordinate.latitude, forKey: GeofenceKey.latitude)
        aCoder.encode(coordinate.longitude, forKey: GeofenceKey.longitude)
        aCoder.encode(radius, forKey: GeofenceKey.radius)
        aCoder.encode(identifier, forKey: GeofenceKey.identifier)
    }
    
    required init?(coder aDecoder: NSCoder) {
        
        let lat = aDecoder.decodeDouble(forKey: GeofenceKey.latitude)
        let long = aDecoder.decodeDouble(forKey: GeofenceKey.longitude)
        coordinate = CLLocationCoordinate2D(latitude: CLLocationDegrees.init(lat), longitude: CLLocationDegrees.init(long))
        radius = aDecoder.decodeDouble(forKey: GeofenceKey.radius)
        if let id = aDecoder.decodeObject(forKey: GeofenceKey.identifier) as? String {
            identifier = id
        } else {
            identifier = ""
        }
    }
    
    func getDeepCopy() -> Geofence {
        return Geofence(coordinate: self.coordinate, radius: self.radius, identifier: self.identifier)
    }
}

/* making geofence comparable */
extension Geofence {
    static func == (lhs: Geofence, rhs: Geofence) -> Bool {
        var returnValue = false
        if (lhs.coordinate.latitude == rhs.coordinate.latitude) && (lhs.coordinate.longitude == rhs.coordinate.longitude) && (lhs.radius == rhs.radius) && (lhs.identifier == rhs.identifier)
        {
            returnValue = true
        }
        return returnValue
    }
    
    static func != (lhs: Geofence, rhs: Geofence) -> Bool {
        var returnValue = false
        if (lhs.coordinate.latitude != rhs.coordinate.latitude) || (lhs.coordinate.longitude != rhs.coordinate.longitude) || (lhs.radius != rhs.radius) || (lhs.identifier != rhs.identifier)
        {
            returnValue = true
        }
        return returnValue
    }
}

extension Array where Element == Geofence {
    func getDeepCopy() -> [Geofence] {
        var fences : [ Geofence] = []
        for fence in self {
            fences.append(fence.getDeepCopy())
        }
        return fences
    }
}
