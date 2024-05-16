//
//  EllipseOverlayRenderer.swift
//  Swingify
//
//  Created by Oskar Hosken on 14/5/2024.
//

import UIKit
import MapKit

class EllipseOverlayRenderer: MKCircleRenderer {
    override func draw(_ mapRect: MKMapRect, zoomScale: MKZoomScale, in context: CGContext) {
        // Ensuring overlay is our EllipseOverlay
        guard let ellipseOverlay = self.overlay as? EllipseOverlay else {
            return
        }
        
        // Bounding the ellipse inside a rect
        let rect = self.rect(for: ellipseOverlay.boundingMapRect)
        context.addEllipse(in: rect)
        context.setFillColor(UIColor.red.cgColor)
        context.fillPath()
    }
}
