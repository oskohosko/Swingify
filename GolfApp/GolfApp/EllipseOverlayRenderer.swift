//
//  EllipseOverlayRenderer.swift
//  Swingify
//
//  Created by Oskar Hosken on 14/5/2024.
//

import UIKit
import MapKit

class EllipseOverlayRenderer: MKCircleRenderer {
    // Variables for our ellipse
    var horizontalMetres: Double
    var verticalMetres: Double
    
    // Initialiser
    init(circle: MKCircle, horizontalMetres: Double, verticalMetres: Double) {
        self.horizontalMetres = horizontalMetres
        self.verticalMetres = verticalMetres
        super.init(circle: circle)
    }
    
    // Now we have to override the drawing to make it an ellipse
    override func draw(_ mapRect: MKMapRect, zoomScale: MKZoomScale, in context: CGContext) {
//        // Getting centre of circle as our ellipse point
//        let mapPoint = MKMapPoint(circle.coordinate)
//        print("\(circle.coordinate)")
//        
//        // We have to bound the ellipse in a rectangle (will update later)
//        let mapRect = MKMapRect(x: mapPoint.x, y: mapPoint.y, width: 0, height: 0)
//        // Scaling the horizontal and vertical size to fit the map.
//        let horizontalSize = horizontalMetres * MKMapPointsPerMeterAtLatitude(circle.coordinate.latitude) / zoomScale
//        let verticalSize = verticalMetres * MKMapPointsPerMeterAtLatitude(circle.coordinate.latitude) / zoomScale
//        
//        let rect = CGRect(x: mapRect.origin.x - horizontalSize / 2,
//                          y: mapRect.origin.y - verticalSize / 2,
//                          width: horizontalSize,
//                          height: verticalSize)
//        
//        let normalizedRect = rect.applying(context.ctm)
//        // Clear fill
//        context.setFillColor(UIColor.blue.cgColor)
//        context.setStrokeColor(UIColor.blue.cgColor)
//        context.setLineWidth(5.0 / zoomScale)
//        context.addEllipse(in: normalizedRect)
//        context.drawPath(using: .fillStroke)
        
        let rectCenter = MKMapPoint(circle.coordinate)
        let rectOrigin = MKMapPoint(x: rectCenter.x, y: rectCenter.y)
        
        let rect = CGRect(x: rectOrigin.x, y: rectOrigin.y, width: horizontalMetres, height: verticalMetres)
        
        context.setFillColor(UIColor.blue.withAlphaComponent(0.3).cgColor)
        context.setStrokeColor(UIColor.blue.cgColor)
        context.setLineWidth(1.0 / zoomScale) // Line width that scales with zoom
        context.addEllipse(in: rect)
        
    }
}
