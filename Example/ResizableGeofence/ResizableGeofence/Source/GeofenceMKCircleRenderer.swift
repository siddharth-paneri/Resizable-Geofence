//
//  GeofenceMKCircleRenderer.swift
//  ResizableGeofence
//
//  Created by Siddharth Paneri on 05/06/18.
//  Copyright © 2018 Siddharth Paneri. All rights reserved.
//

import UIKit
import MapKit


fileprivate let MIN_RADIUS : CLLocationDistance = DEFAULT_MIN_RADIUS
fileprivate let MAX_RADIUS : CLLocationDistance = DEFAULT_MAX_RADIUS
fileprivate let DEFAULT_ALPHA : Double = 0.4 // meters
fileprivate let DEFAULT_BORDER : Double = 5.0
fileprivate let DEFAULT_THUMB_RADIUS : Double = 15.0
fileprivate let DEFAULT_RADIUS_LINE_WIDTH : Double = 2.5

protocol GeofenceMKCircleRendererDelegate {
    func onRadiusChange(radius : Double)
}

class GeofenceMKCircleRenderer: MKCircleRenderer {
    
    var circleBounds : MKMapRect?
    var thumbBounds : MKMapRect?
    var zoomScale : MKZoomScale?
    var alphaComponent : Double = DEFAULT_ALPHA
    var border : Double = DEFAULT_BORDER
    var thumbRadius : Double = DEFAULT_THUMB_RADIUS
    var radiusLineWidth : Double = DEFAULT_RADIUS_LINE_WIDTH
    fileprivate var minRadius = MIN_RADIUS
    fileprivate var maxRadius = MAX_RADIUS
    fileprivate var radius = MIN_RADIUS
    fileprivate var mapRadius = MIN_RADIUS
    fileprivate var showDistance : Bool = false
    var fenceBackgroundColor : UIColor = UIColor.lightGray
    var fenceBorderColor : UIColor = UIColor.darkGray
    var fenceThumbColor : UIColor = UIColor(hexString: "267BFE")
    
    var delegate : GeofenceMKCircleRendererDelegate?
    
    override init(circle: MKCircle) {
        super.init(circle: circle)
        commonInit()
        
    }
    init(circle: MKCircle, radius: Double, min : Double, max: Double) {
        super.init(circle: circle)
        self.radius = radius
        self.minRadius = min
        self.maxRadius = max
        commonInit()
    }
    
    init(circle: MKCircle, radius: Double) {
        super.init(circle: circle)
        self.radius = radius
        commonInit()
    }
    
    
    func commonInit(){
        alphaComponent = DEFAULT_ALPHA
        border = DEFAULT_BORDER
    }
    
    
    /** radius in meters */
    func set(radius : Double){
        mapRadius = radius
        invalidatePath()
    }
    
    /** radius in meters */
    func getRadius()-> Double{
        return mapRadius
    }
    
    func showDistance(show : Bool) {
        showDistance = show
        invalidatePath()
    }
    
    override func draw(_ mapRect: MKMapRect, zoomScale: MKZoomScale, in context: CGContext) {
        let mapPoint = MKMapPoint(overlay.coordinate)
        let radiusAtLatitude = mapRadius * MKMapPointsPerMeterAtLatitude(overlay.coordinate.latitude)
        
        self.zoomScale = zoomScale
        circleBounds = MKMapRect(x: mapPoint.x, y: mapPoint.y, width: radiusAtLatitude*2, height: radiusAtLatitude*2)
        if let rect = circleBounds {
            let overlayRect = self.rect(for: rect)
            context.setStrokeColor(self.fenceBorderColor.cgColor)
            context.setFillColor(self.fenceBackgroundColor.withAlphaComponent(CGFloat(alphaComponent)).cgColor)
//            context.setLineWidth(CGFloat(self.border)/zoomScale)
            context.setLineWidth(CGFloat(self.border)/zoomScale)
            context.setShouldAntialias(true)
            context.addArc(center: overlayRect.origin, radius: CGFloat(radiusAtLatitude), startAngle: 0, endAngle: CGFloat(2*Double.pi), clockwise: true)
            context.drawPath(using: .fillStroke)
            
            /* create a circle thumb on right */
            let xPos = overlayRect.origin.x + CGFloat(radiusAtLatitude)
            let yPos = overlayRect.origin.y
            let thumbPoint = CGPoint(x: xPos, y: yPos)
            //UIColor(hexString: "267BFE")
            context.setStrokeColor(self.fenceThumbColor.cgColor)
            context.setFillColor(self.fenceThumbColor.cgColor)
            let rad = self.thumbRadius / Double(zoomScale)
            let radLineWidth = self.radiusLineWidth / Double(zoomScale)
            let paternWidth = 7 / zoomScale
            context.setShouldAntialias(true)
            context.addArc(center: CGPoint(x: xPos, y: yPos), radius: CGFloat(rad) , startAngle: 0, endAngle: CGFloat(2*Double.pi), clockwise: true)
            context.drawPath(using: CGPathDrawingMode.fill)
            
            let thumbRect = CGRect(x: xPos-CGFloat(rad*2), y: yPos-CGFloat(rad*2), width: CGFloat(rad)*4, height: CGFloat(rad)*4)
            self.thumbBounds = self.mapRect(for: thumbRect)
            
            /* create radius dashed line */
            context.setLineWidth(CGFloat(radLineWidth))
            context.setStrokeColor(self.fenceThumbColor.cgColor)
            context.move(to: thumbPoint)
            context.setShouldAntialias(true)
            context.addLine(to: overlayRect.origin)
//            context.setLineDash(phase: 100, lengths: [CGFloat(radLineWidth), CGFloat(radLineWidth)])
            context.setLineDash(phase: 0, lengths: [paternWidth, paternWidth])
            context.setLineCap(CGLineCap.square)
            context.drawPath(using: CGPathDrawingMode.stroke)
            
            
            // do not remove this commented code which draws the text on the radius line, not used for now.
            /*
            if showDistance {
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.alignment = .center
                paragraphStyle.lineBreakMode = .byTruncatingTail
                
                let attrs = [NSFontAttributeName: UIFont(name: "SFUIText-Regular", size: 25/zoomScale)!, NSForegroundColorAttributeName : self.fenceThumbColor, NSParagraphStyleAttributeName: paragraphStyle] as [String : Any]
                
                let string = NSString(format: "%d m", Int(mapRadius))
                
                UIGraphicsPushContext(context)
                let rect = CGRect(x: overlayRect.origin.x, y: overlayRect.origin.y-CGFloat(30/zoomScale), width: CGFloat(radiusAtLatitude), height: CGFloat(30/zoomScale))
                string.draw(in: rect, withAttributes: attrs)
            }
            */
            
            DispatchQueue.main.async {
                self.delegate?.onRadiusChange(radius: self.mapRadius)
            }
            UIGraphicsPopContext()
            
            
        }
        
    }
}
