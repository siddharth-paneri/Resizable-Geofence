//
//  GeofenceMapViewController.swift
//  Geofence
//
//  Created by Siddharth Paneri on 21/05/18.
//  Copyright © 2018 Siddharth Paneri. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

protocol GeofenceMapDelegate {
    func updated(geofence: Geofence)
}

class GeofenceMapViewController: UIViewController {
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var view_top: UIView!
    @IBOutlet weak var label_Radius: UILabel!
    var geofence : Geofence? = nil
    var geofenceMapDelegate : GeofenceMapDelegate? = nil
    var mkCircle : MKCircle?
    var mkCircleRenderer : GeofenceMKCircleRenderer?
    var isGeofenceResizingAllowed : Bool = false {
        didSet {
            if isGeofenceResizingAllowed != oldValue {
//                self.mapView.isRotateEnabled = !isGeofenceResizingAllowed
//                self.mapView.isScrollEnabled = !isGeofenceResizingAllowed
            }
        }
    }
    fileprivate var lastMapPoint : MKMapPoint? = nil
    fileprivate var oldFenceRadius : Double = 0.0
    /// displayRadius in meters
    fileprivate var displayRadius : Double = DEFAULT_MIN_RADIUS {
        didSet {
            updateRadiusLabel()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Geofence"
        
        // London (51.507351, -0.127758)
        self.geofence = Geofence(coordinate: CLLocationCoordinate2DMake(CLLocationDegrees(exactly: 51.507351)!, CLLocationDegrees(exactly: -0.127758)!), radius: 500, identifier: "Geofence-id-1")
        
        self.configureView()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let fence = geofence {
            self.mapView.addAnnotation(fence)
            self.addRadiusOverlay(forGeofence: fence)
            self.mapView.showsUserLocation = false
        } else {
            self.mapView.showsUserLocation = true
        }
        
        if let fence = geofence {
            let coordinate = fence.coordinate
            let radius = fence.radius*4
            self.mapView.setRegion(MKCoordinateRegion(center: coordinate, latitudinalMeters: radius, longitudinalMeters: radius), animated: true)
        } else if self.mapView.showsUserLocation {
            let coordinate = mapView.userLocation.coordinate
            let region = MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: CLLocationDegrees.init(0.005), longitudeDelta: CLLocationDegrees.init(0.005)))
            mapView.setRegion(region, animated: true)
        }
        self.addGestureRecognizer()
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func configureView() {
        self.view_top.backgroundColor = UIColor.white
        label_Radius.textColor = UIColor.black
        self.mapView.isZoomEnabled = false
        self.mapView.isRotateEnabled = false
        self.mapView.isScrollEnabled = false
        
        if let fence = geofence {
            self.displayRadius = fence.radius
        }
    }
    
    func button_TopRight_Clicked (_ sender : AnyObject) {
        if let radius = self.mkCircleRenderer?.getRadius() {
            geofence?.radius = radius
            if let fence = geofence {
                self.geofenceMapDelegate?.updated(geofence: fence)
            }
        }
        
        self.navigationController?.popViewController(animated: true)
    }
    

    func addRadiusOverlay(forGeofence geofence: Geofence) {
        if mkCircle != nil {
            self.mapView.removeOverlay(mkCircle!)
        }
        
        mkCircle = MKCircle(center: geofence.coordinate, radius: DEFAULT_MAX_RADIUS*2) //geofence.radius)
        self.mapView.addOverlay(mkCircle!)
        mkCircleRenderer?.set(radius: geofence.radius)
    }
    
    func addGestureRecognizer() {
        let gestureRecognizer = GeofenceGestureRecognizer()
        self.mapView.addGestureRecognizer(gestureRecognizer)
        gestureRecognizer.touchesBeganCallback = { ( touches: Set<UITouch>, event : UIEvent) in
            if let touch = touches.first {
                let pointOnMapView = touch.location(in: self.mapView)
                let coordinateFromPoint = self.mapView.convert(pointOnMapView, toCoordinateFrom: self.mapView)
                let mapPoint = MKMapPoint(coordinateFromPoint)
                if let fenceRederer = self.mkCircleRenderer {
                    fenceRederer.showDistance(show: true)
                    if let thumbMapRect = fenceRederer.thumbBounds {
                        /* get rect of thumb */
                        if thumbMapRect.contains(mapPoint) {
                            /* touched on thumb */
                            self.isGeofenceResizingAllowed = true
                            self.oldFenceRadius = fenceRederer.getRadius()
                        }                    }
                }
                self.lastMapPoint = mapPoint
            }
        }
        gestureRecognizer.touchesMovedCallback = { ( touches: Set<UITouch>, event : UIEvent) in
            /* if resizing is allowed and only one touch is processed perform resizing */
            if self.isGeofenceResizingAllowed && touches.count == 1 {
                
                if let touch = touches.first {
                    let pointOnMapView = touch.location(in: self.mapView)
                    let coordinateFromPoint = self.mapView.convert(pointOnMapView, toCoordinateFrom: self.mapView)
                    let mapPoint = MKMapPoint(coordinateFromPoint)
                    
                    if let lastPoint = self.lastMapPoint {
                        var meterDistance = (mapPoint.x-lastPoint.x)/MKMapPointsPerMeterAtLatitude(coordinateFromPoint.latitude)+self.oldFenceRadius
                        if meterDistance > 0 {
//                            if abs(meterDistance-self.oldFenceRadius) >= DEFAULT_STEP_RADIUS {
                                self.mkCircleRenderer?.set(radius: meterDistance)
                                if let rad = self.mkCircleRenderer?.getRadius() {
                                    meterDistance = rad
                                }
//                            }
                        }
                    }
                }
            }
        }
        
        gestureRecognizer.touchesEndedCallback = { ( touches: Set<UITouch>, event : UIEvent) in
            
            if self.isGeofenceResizingAllowed && touches.count == 1 {
                if let _ = touches.first {
                    if let circleRenderer = self.mkCircleRenderer {
                        let radius = GeofenceManager.radiusWithinRange(radius: circleRenderer.getRadius())
                        let zoomCoordinate = circleRenderer.circle.coordinate
                        let zoomRadius = radius*4
                        self.mapView.setRegion(MKCoordinateRegion(center: zoomCoordinate, latitudinalMeters: zoomRadius, longitudinalMeters: zoomRadius), animated: false)
                        circleRenderer.set(radius: radius)
                        circleRenderer.showDistance(show: false)
                    }
                }
            }
            
            
            self.isGeofenceResizingAllowed = false
        }
        
        
    }
    
    func updateRadiusLabel() {
        /* recalculate radius according min/max range */
        let meterDistance = GeofenceManager.radiusWithinRange(radius: self.displayRadius)
        label_Radius.text = GeofenceManager.getString(fromRadius: meterDistance)
    }
}



extension GeofenceMapViewController : MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, didFailToLocateUserWithError error: Error) {
    }
    
    func mapViewWillStartLocatingUser(_ mapView: MKMapView) {
        
    }
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let identifier = "Geofence-id-1"
        if annotation is Geofence {
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            if annotationView ==  nil {
                annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = false
            } else {
                annotationView?.annotation = annotation
            }
            
            
            annotationView?.image = UIImage(named: "center")
            return annotationView
        }
        return nil
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKCircle {
            if let mkcircle = overlay as? MKCircle {
                mkCircleRenderer = GeofenceMKCircleRenderer(circle: mkcircle)
                mkCircleRenderer?.delegate = self
                if let renderer = mkCircleRenderer {
                    return renderer
                }
                
            }
            /*
            let circleRenderer = MKCircleRenderer(overlay: overlay)
            circleRenderer.lineWidth = 1.0
            circleRenderer.strokeColor = Theame_Color_TextGrey
            circleRenderer.fillColor = Theame_Color_TextGrey.withAlphaComponent(0.4)
            return circleRenderer
            */
        }
        return MKOverlayRenderer(overlay: overlay)
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        
    }
}

extension GeofenceMapViewController : GeofenceMKCircleRendererDelegate {
    func onRadiusChange(radius: Double) {
        self.displayRadius = radius
    }
}
