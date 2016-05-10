//
//  GraphView.swift
//  MotionGraph
//
//  Created by Carl Hill-Popper on 3/30/16.
//
//

import UIKit
import QuartzCore
import CoreMotion

public class GraphView : UIView {
    
    func add(x x: Double, y: Double, z: Double) {
        // First, add the new value to the current segment.
        if (self.currentSegment.add(x: x, y: y, z: z)) {
            /*
             If after doing that we've filled up the current segment, then we need to determine the next current segment.
             */
            self.recycleSegment()
            // To keep the graph looking continuous, add the value to the new segment as well.
            self.currentSegment.add(x: x, y: y, z: z)
        }
        /*
         After adding a new data point, advance the x-position of all the segment layers by 1 to create the illusion that the graph is advancing.
         */
        for segment in self.segments {
            segment.layer.position.x += 1
        }
    }
    
    func reset() {
        for segment in self.segments {
            segment.clear()
        }
    }
 
    static var backgroundColor: CGColorRef = UIColor(white: 0.6, alpha: 1.0).CGColor
    static var gridlineColor: CGColorRef = UIColor(white: 0.5, alpha: 1.0).CGColor
    
    static var xColor: CGColorRef = UIColor.redColor().CGColor
    static var yColor: CGColorRef = UIColor.greenColor().CGColor
    static var zColor: CGColorRef = UIColor.blueColor().CGColor
 
    // A mutable array to store segments, which is required by -addSegment.
    private var segments = [GraphViewSegment]()
    private lazy var currentSegment: GraphViewSegment = {
        self.addSegment()
    }()
    
    private var labelView: GraphLabelView?
    
    /*
     The graph view itself exists only to draw the background and gridlines. All other content is drawn either into the GraphLabelView or into a layer managed by a GraphViewSegment.
     */

    override public func drawRect(rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        // Fill in the background.
        CGContextSetFillColorWithColor(context, GraphView.backgroundColor)
        CGContextFillRect(context, self.bounds)
    
        // Draw the grid lines.
        let height = self.bounds.height
        CGContextTranslateCTM(context, 0.0, 0.5 * height)
        GraphView.drawGridlines(atX: 0.0, width: self.bounds.width, height: height, inContext: context)
        
        if self.labelView == nil {
            let labelView = GraphLabelView(frame: CGRect(x: 0.0, y: 0.0, width: CGFloat(SegmentWidth), height: height))
            self.addSubview(labelView)
            self.labelView = labelView
        }
    }

    /*
     Creates a new segment, adds it to 'segments', and returns the new segment. Typically a graph will have around a dozen segments, but this depends on the width of the graph view and segments.
     */
    private func addSegment() -> GraphViewSegment {
        let height = self.bounds.height
        let bounds = CGRect(x: 0.0, y: -0.5 * height,
                            width: CGFloat(SegmentWidth), height: height)
        let segment = GraphViewSegment(bounds: bounds)
        /*
         Add the new segment at the front of the array because -recycleSegment expects the oldest segment to be at the end of the array. As long as we always insert the youngest segment at the front this will be true.
         */
        self.segments.insert(segment, atIndex: 0)

        /* Ensure that newly added segment layers are placed after the text view's layer so that the text view always renders above the segment layer.
         */
        self.layer.insertSublayer(segment.layer, below: self.labelView?.layer)
        
        return segment
    }
    
    // Recycles a segment from 'segments' into 'current'.
    private func recycleSegment() {
        /*
         Start with the last object in the segments array, because it should either be visible onscreen (which indicates that we need more segments) or pushed offscreen (which makes it eligible for recycling).
         */
        guard let lastSegment = self.segments.last else {
            return
        }
        
        if lastSegment.isVisible(inRect: self.layer.bounds) {
            // The last segment is still visible, so create a new segment, which is now the current segment.
            self.currentSegment = self.addSegment()
        } else {
            // The last segment is no longer visible, so reset it in preparation for being recycled.
            lastSegment.reset()
            /*
             Move the segment from the last position in the array to the first position in the array because it is now the youngest segment,
             */
            self.segments.insert(lastSegment, atIndex: 0)
            self.segments.removeLast()
            // and make it the current segment.
            self.currentSegment = lastSegment
        }
        
    }
    
    private static func drawGridlines(atX x: CGFloat, width: CGFloat, height: CGFloat, inContext context: CGContextRef?) {
        let unitHeight = self.unitHeightForGraphHeight(height)
        //lines will be drawn from -3*height to +3*height
        for unit in GraphLineRange {
            let y = CGFloat(unit) * unitHeight
            CGContextMoveToPoint(context, x, y)
            CGContextAddLineToPoint(context, x + width, y)
        }
        CGContextSetStrokeColorWithColor(context, self.gridlineColor)
        CGContextStrokePath(context)
    }
    
    private static func unitHeightForGraphHeight(height: CGFloat) -> CGFloat {
        //y scale is negative because the coordinates for CGContext and UIView are flipped in the y-axis
        //height in pixels of one vertical unit
        return 16.0//0.15 * height
    }
}

private class GraphLabelView: UIView {
    override func drawRect(rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        
        // Fill in the background.
        CGContextSetFillColorWithColor(context, GraphView.backgroundColor)
        CGContextFillRect(context, self.bounds)
        
        // Draw the grid lines.
        let height = self.bounds.height
        CGContextTranslateCTM(context, 0.0, 0.5 * height)
        
        let textWidth: CGFloat = 26.0
        let lineWidth = self.bounds.width - textWidth
        
        // Draw the grid lines.
        GraphView.drawGridlines(atX: textWidth, width: lineWidth, height: height, inContext: context)
        
        // Draw the text.
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .Right
        let textAttributes = [
            NSFontAttributeName: UIFont.systemFontOfSize(12.0),
            NSForegroundColorAttributeName: UIColor.whiteColor(),
            NSParagraphStyleAttributeName: paragraphStyle,
        ]
        
        let unitHeight = GraphView.unitHeightForGraphHeight(height)
        var rect = CGRect(x: 0.0, y: 0.0, width: textWidth, height: unitHeight)
        
        for unit in GraphLineRange {
            rect.origin.y = (CGFloat(-unit) - 0.5) * unitHeight
            
            var label: NSString
            if unit < 0 {
                label = "\(unit).0"
            } else if unit == 0 {
                label = "\(unit).0"
            } else {
                label = "+\(unit).0"
            }
            label.drawInRect(rect, withAttributes: textAttributes)
        }
    }
}

private let GraphMax = 8
private let GraphLineRange = -GraphMax...GraphMax
private let SegmentWidth = 32

private class GraphViewSegment {
    
    private var xPath = CGPathCreateMutable()
    private var yPath = CGPathCreateMutable()
    private var zPath = CGPathCreateMutable()
    private var count = 0
    
    private let layer = CALayer()
    private let yScale: CGFloat
    
    var isFull: Bool {
        return self.count >= SegmentWidth
    }

    init(bounds: CGRect) {
        self.yScale = -GraphView.unitHeightForGraphHeight(bounds.height)
        
        self.layer.bounds = bounds
        self.layer.delegate = self
        self.layer.opaque = true
        self.layer.position = self.initialPosition
    }
    
    /*
     SegmentInitialPosition defines the initial position of a segment that is meant to be displayed on the left side of the graph.
     This positioning is meant so that a few entries must be added to the segment's history before it becomes visible to the user. This value could be tweaked a little bit with varying results, but the X coordinate should never be larger than 16 (the center of the text view) or the zero values in the segment's history will be exposed to the user.
     */
    private var initialPosition: CGPoint {
        return CGPoint(x: 0.5 * self.layer.bounds.width - 1.0,
                       y: 0.5 * self.layer.bounds.height)
    }
    
    func isVisible(inRect rect: CGRect) -> Bool {
        // Check if there is an intersection between the layer's frame and the given rect.
        return rect.intersects(self.layer.frame)
    }
    
    func add(x x: Double, y: Double, z: Double) -> Bool {
        // If this segment is not full, add a new value to the history.
        if !self.isFull {
            //we want the values to fill in from the right side, so x decreases from count as we add more values
            let xValue = CGFloat(SegmentWidth - self.count)
            let yScale = self.yScale
            
            if self.count == 0 {
                CGPathMoveToPoint(self.xPath, nil, xValue, CGFloat(x) * yScale)
                CGPathMoveToPoint(self.yPath, nil, xValue, CGFloat(y) * yScale)
                CGPathMoveToPoint(self.zPath, nil, xValue, CGFloat(z) * yScale)
            }
            CGPathAddLineToPoint(self.xPath, nil, xValue, CGFloat(x) * yScale)
            CGPathAddLineToPoint(self.yPath, nil, xValue, CGFloat(y) * yScale)
            CGPathAddLineToPoint(self.zPath, nil, xValue, CGFloat(z) * yScale)

            // And inform Core Animation to redraw the layer.
            self.layer.setNeedsDisplay()
            self.count += 1
        }
        // And return if we are now full or not.
        return self.isFull
    }
    
    func clear() {
        self.xPath = CGPathCreateMutable()
        self.yPath = CGPathCreateMutable()
        self.zPath = CGPathCreateMutable()
        
        self.count = 0
        self.layer.setNeedsDisplay()
    }
    
    func reset() {
        self.clear()
        
        // Position the segment properly (see the comment for SegmentInitialPosition).
        self.layer.position = self.initialPosition
    }
    
    @objc func drawLayer(layer: CALayer, inContext context: CGContextRef) {
        // Fill in the background.
        CGContextSetFillColorWithColor(context, GraphView.backgroundColor)
        let bounds = self.layer.bounds
        CGContextFillRect(context, bounds)

        // Draw the gridlines.
        GraphView.drawGridlines(atX: 0.0, width: bounds.width, height: bounds.height, inContext: context)

        // X
        CGContextSetStrokeColorWithColor(context, GraphView.xColor)
        CGContextAddPath(context, self.xPath)
        CGContextStrokePath(context)

        // Y
        CGContextSetStrokeColorWithColor(context, GraphView.yColor)
        CGContextAddPath(context, self.yPath)
        CGContextStrokePath(context)
        
        // Z
        CGContextSetStrokeColorWithColor(context, GraphView.zColor)
        CGContextAddPath(context, self.zPath)
        CGContextStrokePath(context)
    }
    
    @objc func actionForLayer(layer: CALayer, forKey event: String) -> CAAction? {
        // We disable all actions for the layer, so no content cross fades, no implicit animation on moves, etc.
        return NSNull()
    }
}
