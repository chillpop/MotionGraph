//
//  ViewController.swift
//  MotionGraph
//
//  Created by Carl Hill-Popper on 3/30/16.
//
//

import UIKit
import CoreMotion

class ViewController: UIViewController {

    @IBOutlet private var topLabel: UILabel!
    @IBOutlet private var topGraph: GraphView!
    
    @IBOutlet private var bottomLabel: UILabel!
    @IBOutlet private var bottomGraph: GraphView!
    private let motionManager = CMMotionManager()

    private var updating = false
    private var useDeviceMotion = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.startUpdates()
        self.view.addGestureRecognizer(
            UITapGestureRecognizer(target: self, action: #selector(tap))
        )
        
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(swapGraphTypes))
        doubleTap.numberOfTapsRequired = 2
        doubleTap.numberOfTouchesRequired = 2
        self.view.addGestureRecognizer(doubleTap)
    }
    
    func startUpdates() {
        self.updating = true
        if self.useDeviceMotion {
            //attitude, user accel
            guard self.motionManager.deviceMotionAvailable else {
                return
            }
            self.topLabel.text = "User Acceleration (Gs)"
            self.bottomLabel.text = "Attitude (pitch, yaw, roll) radians"
            self.motionManager.startDeviceMotionUpdatesToQueue(NSOperationQueue.mainQueue()) { (deviceMotion, _) in
                guard let motion = deviceMotion else { return }
                let acceleration = motion.userAcceleration
                self.topGraph.add(x: acceleration.x, y: acceleration.y, z: acceleration.z)
                self.bottomGraph.add(x: motion.attitude.pitch, y: motion.attitude.yaw, z: motion.attitude.roll)
            }
            
        } else {
            //accelerometer
            guard self.motionManager.accelerometerAvailable else {
                return
            }
            self.topLabel.text = "Accelerometer (Gs)"
            self.motionManager.startAccelerometerUpdatesToQueue(NSOperationQueue.mainQueue()) { (acceleromterData, _) in
                guard let acceleration = acceleromterData?.acceleration else { return }
                self.topGraph.add(x: acceleration.x, y: acceleration.y, z: acceleration.z)
            }
            
            //gyro
            guard self.motionManager.gyroAvailable else {
                return
            }
            self.bottomLabel.text = "Gyroscope (radians/sec)"
            self.motionManager.startGyroUpdatesToQueue(NSOperationQueue.mainQueue()) { (gyroData, _) in
                guard let rotation = gyroData?.rotationRate else { return }
                self.bottomGraph.add(x: rotation.x, y: rotation.y, z: rotation.z)
            }
        }
    }

    func stopUpdates() {
        self.motionManager.stopAccelerometerUpdates()
        self.motionManager.stopGyroUpdates()
        self.motionManager.stopDeviceMotionUpdates()
        self.motionManager.stopMagnetometerUpdates()
        
        self.updating = false
    }
    
    @objc private func tap() {
        if self.updating {
            self.stopUpdates()
        } else {
            self.startUpdates()
        }        
    }
    
    @objc private func swapGraphTypes() {
        self.stopUpdates()
        self.useDeviceMotion = !self.useDeviceMotion
        self.topGraph.reset()
        self.bottomGraph.reset()
        self.startUpdates()
    }
}

