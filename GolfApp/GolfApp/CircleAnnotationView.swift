//
//  CircleAnnotationView.swift
//  GolfApp
//
//  Created by Oskar Hosken on 11/5/2024.
//

import UIKit
import MapKit

class CircleAnnotationView: MKAnnotationView {

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    
    override var annotation: MKAnnotation? {
        willSet {
            guard let customAnnotation = newValue as? CustomAnnotation else {
                return
            }
            canShowCallout = true
            calloutOffset = CGPoint(x: -5, y: 5)
            
            let circlePath = UIBezierPath(arcCenter: CGPoint(x: bounds.midX, y: bounds.midY), 
                                          radius: CGFloat(20),
                                          startAngle: CGFloat(0),
                                          endAngle: CGFloat(Double.pi * 2),
                                          clockwise: true)
            let circleLayer = CAShapeLayer()
            circleLayer.path = circlePath.cgPath
            circleLayer.fillColor = UIColor.clear.cgColor
            circleLayer.strokeColor = UIColor.white.cgColor
            circleLayer.lineWidth = 2

            frame = circlePath.bounds
            layer.addSublayer(circleLayer)

            let label = UILabel()
            label.frame = bounds
            label.text = customAnnotation.title
            label.textColor = UIColor.white
            label.textAlignment = .center
            addSubview(label)
        }
    }

}
