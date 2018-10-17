//
//  GeofenceManager.swift
//  BeanbagApp
//
//  Created by Siddharth Paneri on 29/05/18.
//  Copyright © 2018 Secure Meters Limited. All rights reserved.
//

import UIKit
import CoreLocation

enum RadiusUnit : Int {
    case miles = 1
    case kilometers = 2
}


var radiusUnit : RadiusUnit = .kilometers

class GeofenceManager : NSObject {

    //MARK:- convert geofence radius
    
    class func radiusWithinRange(radius: Double?) -> Double{
        var reCalculatedRadius = DEFAULT_MIN_RADIUS
        if let rad = radius {
            reCalculatedRadius = rad
            if reCalculatedRadius > DEFAULT_MAX_RADIUS {
                reCalculatedRadius = DEFAULT_MAX_RADIUS
            } else if reCalculatedRadius < DEFAULT_MIN_RADIUS {
                reCalculatedRadius = DEFAULT_MIN_RADIUS
            }
        }
        return reCalculatedRadius
    }
    
    class func getString(fromRadius radius: Double) -> String {
        var string_Radius = ""
        /* recalculate radius according min/max range */
        let meterDistance = GeofenceManager.radiusWithinRange(radius: radius)
        switch radiusUnit {
        case .miles:
            /* convert meters to feet */
            let feetDistance = meterDistance*3.28
            /* 528 ft is equal to 0.1 mi */
            if feetDistance >= 528 {
                /* convert feet to mile */
                let yardDistance = feetDistance/3
                let mileDistance = yardDistance/1760
                string_Radius = String(format: "%0.2f mi", mileDistance)
            } else {
                let feet = GeofenceManager.getClosestRadius(radiusValue: feetDistance)
                string_Radius = String(format: "%d ft", Int(feet))
            }
            break
        case .kilometers:
            let meter = GeofenceManager.getClosestRadius(radiusValue: meterDistance)
            
            if meter > 999 {
                /* convert meter to kilometer */
                let kilometerDistance = meter/1000
                string_Radius = String(format: "%0.2f km", kilometerDistance)
            } else {
                string_Radius = String(format: "%d m", Int(meter))
            }
            
            
            
            break
        }
        
        return string_Radius
    }
    
    /** here radius may or may not be in meters */
    class func getClosestRadius(radiusValue: Double) -> Double {
        var distance = radiusValue
        let modValue = distance.truncatingRemainder(dividingBy: DEFAULT_STEP_RADIUS)
        if modValue > (DEFAULT_STEP_RADIUS/2) {
            /* sbtract mod value and add step value */
            distance = (distance-modValue) + DEFAULT_STEP_RADIUS
        } else {
            /* subtract mod value */
            distance = (distance-modValue)
        }
        return distance
    }
    

    

}

