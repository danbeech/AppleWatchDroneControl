//
//  InterfaceController.swift
//  TelloGestureControl WatchKit Extension
//
//  Created by Daniel Beech on 05/03/2020.
//  Copyright © 2020 Dan Beech. All rights reserved.
//

//Log Findings ---------------------------------------------------
//
//  Set Null Zone before gravity affects movement to around 0.15? Further testing required.
//
//  Set gravityPrecision to 0.2? 0.15? Maybe use a convenience method (something called isNearTo) to check the values are within the precision bracket? - Seen on github, reference this code in dissertation!!!
//
//
//Hover:
//      Gravity X: 0 +/- precision
//      Gravity Y: 0 +/- precision
//      Gravity Z: -1 +/- precision
//
//Wrist Tilt Right:
//      Gravity X: 0 +/- precision
//      Gravity Y: -1 +/- precision
//      Gravity Z: 0 +/- precision
//
//Wrist Tilt Left:
//      Gravity X: 0 +/- precision
//      Gravity Y: 1 +/- precision
//      Gravity Z: 0 +/- precision
//
//Point To Sky:
//      Gravity X: -1 +/- precision
//      Gravity Y: 0 +/- precision
//      Gravity Z: 0 +/- precision
//
//Point To Floor:
//      Gravity X: 1 +/- precision
//      Gravity Y: 0 +/- precision
//      Gravity Z: -0.5 +/- precision
//
//Half Up:
//      Gravity X:-0.5 +/- precision
//      Gravity Y: 0 +/- precision
//      Gravity Z: -1 +/- precision
//
//Half Down:
//      Gravity X: 0.5 +/- precision
//      Gravity Y: 0 +/- precision
//      Gravity Z: -1 +/- precision
//

import WatchKit
import Foundation
import os //Needed for os_log to output the device data, to turn into a csv to make graphs.
import WatchConnectivity //Needed to send messages between the phone and Watch.
import CoreMotion //Needed to access the sensor data (device motion).
import CoreML //needed for the trained machine learning model to be used to recognise user acceleration for flips.

//This is needed to keep the screen awake past the regular time allotted and allow higher sample rates when the screen does turn off.
let extendedSession = WKExtendedRuntimeSession()

//The interface controller is the delegate for the Watch Connectivity session, and has the necessary protocols.
class InterfaceController: WKInterfaceController, WCSessionDelegate {
    
    //create the watch session singleton object, which is usable throughout the application.
    var session = WCSession.default
    //Create the instance of the Core Motion Motion Manager, needed to access sensor data.
    let motionManager = CMMotionManager()
    //Global variable for the gravity precision value. Easier to change when it is here.
    var gravityPrecision = 0.30
    
    //Variables used to count iterations
    //delayCounter: predictions are performed every second by the CoreML model, but this was triggering multiples of the same action, depending on the speed the user performed it at. If the predictions are made every second but are only sent every couple of seconds, then the accuracy and reliability is improved. - Yuxin Bai, CoreML Engineer recommended this in an email.
    var delayCounter = 0
    //These are values for using the CoreML Model. In a Struct for easy access should they need to be used multiple times throughtout the code.
    struct ModelConstants {
        //This is how many samples the model will need in the array before it makes a prediction. It is 50 as the model was created to make a prediction every 1.0 second and the values are added at 50Hz sample rate.
        static let predictionWindowSize = 50
        //Defines the amount of values that should be added to the array. 1.0 is one second, 50.0 is the amount of samples. So therefore 1.0/50.0 would be 50 samples per second, or a 50Hz sample rate.
        static let accelerometerMotionUpdateInterval = 1.0/50.0
        //The model takes in all values from the MLMultiArrays defined below. The size of stateIn is defined in the predefined class that exists when you add your CoreML model to the project.
        static let stateInLength = 400
        //This is the speed at which the device motion should update. It is set to the same value as the accelerometer updates as it is also used to make predictions for the CoreML model, so it must have the same sample rate.
        static let deviceMotionUpdateInterval = 1.0/50.0
    }

    //creting a variable to reference the machine learning model and it's pre-generated class.
    let activityClassificationModel = TelloGestureClassifier_8()
    //needed to track how many values have been added, so that predictions may be made using the correct amount of values in the following multiarrays.
    var currentIndexInPredictionWindow = 0
    
    //multiarrays to hold the data that the machine learning model will analyse and make it's predictions upon.
    let motionUserAccelerationX = try! MLMultiArray(shape: [ModelConstants.predictionWindowSize] as [NSNumber], dataType: MLMultiArrayDataType.double)
    let motionUserAccelerationY = try! MLMultiArray(shape: [ModelConstants.predictionWindowSize] as [NSNumber], dataType: MLMultiArrayDataType.double)
    let motionUserAccelerationZ = try! MLMultiArray(shape: [ModelConstants.predictionWindowSize] as [NSNumber], dataType: MLMultiArrayDataType.double)
    
    let accelerometerAccelerationX = try! MLMultiArray(shape: [ModelConstants.predictionWindowSize] as [NSNumber], dataType: MLMultiArrayDataType.double)
    let accelerometerAccelerationY = try! MLMultiArray(shape: [ModelConstants.predictionWindowSize] as [NSNumber], dataType: MLMultiArrayDataType.double)
    let accelerometerAccelerationZ = try! MLMultiArray(shape: [ModelConstants.predictionWindowSize] as [NSNumber], dataType: MLMultiArrayDataType.double)
    
    let motionRotationRateX = try! MLMultiArray(shape: [ModelConstants.predictionWindowSize] as [NSNumber], dataType: MLMultiArrayDataType.double)
    let motionRotationRateY = try! MLMultiArray(shape: [ModelConstants.predictionWindowSize] as [NSNumber], dataType: MLMultiArrayDataType.double)
    let motionRotationRateZ = try! MLMultiArray(shape: [ModelConstants.predictionWindowSize] as [NSNumber], dataType: MLMultiArrayDataType.double)
    
    //this will be the values of all the arrays from the previous prediction window.
    var stateIn = try! MLMultiArray(shape:[ModelConstants.stateInLength as NSNumber], dataType: MLMultiArrayDataType.double)
    
    //START ENUMS
    //Enums allow code to be readable. Replacing strings in code with variable names makes it much easier to use and update moving forward.
    enum FlyCommands {
        static let hover = "rc 0 0 0 0"
        //Replace with these values to have a more normal flying speed, the slower values were used in my demonstration video as the drone was being flown in my bedroom.
//        static let ascend = "rc 0 0 50 0"
//        static let descend = "rc 0 0 -50 0"
//        static let flyRight = "rc -50 0 0 0"
//        static let flyLeft = "rc 50 0 0 0"
//        static let flyForward = "rc 0 50 0 0"
//        static let flyBackward = "rc 0 -50 0 0"
        static let ascend = "rc 0 0 20 0"
        static let descend = "rc 0 0 -20 0"
        static let flyRight = "rc -20 0 0 0"
        static let flyLeft = "rc 20 0 0 0"
        static let flyForward = "rc 0 20 0 0"
        static let flyBackward = "rc 0 -20 0 0"
        static let takeOff = "takeoff"
        static let emergencyLanding = "emergency"
    }
    
    enum Flip {
        static let right = "flip r"
        static let left = "flip l"
        static let front = "flip f"
        static let back = "flip b"
    }
    
    enum Action {
        static let leftRoll = "0"
        static let rightRoll = "1"
        static let frontFlip = "2"
        static let backFlip = "3"
        static let doNothing = "5"
    }
    //END ENUMS.
    
    //START UI
    @IBAction func takeOffButtonAction() {
        sendMessage(commandToSend: FlyCommands.takeOff)
        print("take off initiated")
    }
    
    @IBOutlet weak var accelerometerOnOutlet: WKInterfaceButton!
    @IBAction func accelerometerOn() {
        
        //start device motion updates and start the extended session, which allows background updates.
        //!!!!!!!!!! WARNING !!!!!!!!!! - WILL NOT WORK ON SIMULATOR AS YOU DONT HAVE DEVICE MOTION- isDeviceMotionActive will return Null, and never satisfy the conditions.
        //   -----  TEST ON A PHYSICAL DEVICE  -----
        if motionManager.isDeviceMotionActive == false {
            extendedSession.start()
            print("device motion ON")
            //        sendMessage(commandToSend: "speed 10")
            deviceMotionUpdates()
            self.accelerometerOnOutlet.setBackgroundColor(.green)
            accelerometerOnOutlet.setTitle("Pause Flying!")
        }
        else if motionManager.isDeviceMotionActive == true {
            motionManager.stopDeviceMotionUpdates()
            motionManager.stopAccelerometerUpdates()
            self.accelerometerOnOutlet.setBackgroundColor(.orange)
            accelerometerOnOutlet.setTitle("Restart Flying!")
        }
        
    }
    
    @IBAction func emergencyButton() {
        OperationQueue.main.cancelAllOperations()
        sendMessage(commandToSend: FlyCommands.emergencyLanding)
        //stop device motion updates and end the extended session.
        motionManager.stopDeviceMotionUpdates()
        motionManager.stopAccelerometerUpdates()
        extendedSession.invalidate()
        accelerometerOnOutlet.setBackgroundColor(.darkGray)
        accelerometerOnOutlet.setTitle("Start Flying!")
    }
    //END UI
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        // Configure interface objects here.
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
        
        //check if the watchconnectivity is supported with the current devices. If it is then create the session, assign the delegate to self and activate it.
        if (WCSession.isSupported()) {
            session.delegate = self
            session.activate()
        }
        //Set the update interval in seconds for the motion manager supplying the deviceMotionUpdates and accelerometerUpdates.
        motionManager.deviceMotionUpdateInterval = ModelConstants.deviceMotionUpdateInterval
        motionManager.accelerometerUpdateInterval = ModelConstants.accelerometerMotionUpdateInterval
        
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    //Watch Connectivity session.
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("Watch WCSession did complete with OK.")
    }
    
    //for receiving messages from the iphone app. The only messages it should care about are ones that affect the UI updates.
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        guard let messageToString = message["Message"] as? String else {return}
        if (messageToString.contains(FlyCommands.emergencyLanding)) {
            emergencyButton()
        }
    }
    
    //check to see if the iphone app is reachable for immediate messages sent from the watch.
    private func isReachable() -> Bool {
        return session.isReachable
    }
    
    //Function that uses os_log to print out the motion updates of the sensors included with the device motion updates. Commented out as it is very resource heavy and cannot be running while the app is running due to performance issues.
//    func processDeviceMotionLogs(deviceMotion: CMDeviceMotion){
//
//        //A Timestamp for the sensor log, in the log it will show the date, but when exported to csv for graphs it will be in milliseconds as advertised by the name.
//        let timestamp = Date().timeIntervalSince1970
//
//        //Log the device motion gravity, user acceleration, rotation rate, and pitch, roll, and yaw.
//        os_log("Motion: %@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@, %@",
//        String(timestamp),
//        String(deviceMotion.gravity.x),
//        String(deviceMotion.gravity.y),
//        String(deviceMotion.gravity.z),
//        String(deviceMotion.userAcceleration.x),
//        String(deviceMotion.userAcceleration.y),
//        String(deviceMotion.userAcceleration.z),
//        String(deviceMotion.rotationRate.x),
//        String(deviceMotion.rotationRate.y),
//        String(deviceMotion.rotationRate.z),
//        String(deviceMotion.attitude.roll),
//        String(deviceMotion.attitude.pitch),
//        String(deviceMotion.attitude.yaw))
//
//    }
    
    //This is the function for sending messages to the iPhone. The function takes a string parameter commandToSend, which will be the command you wish to be passed on to the drone. When the iPhone receives it, it will send the command and the drone should respond.
    func sendMessage(commandToSend: String) {
        if isReachable() {
            session.sendMessage(["request" : commandToSend], replyHandler: { (response) in
                //print("Reply: \(response)")
            }, errorHandler: { (error) in
                print("Error sending message: %@", error)
            })
        } else {
            print("iPhone is not reachable!!")
        }
    }
    
    //starting the device motion updates, which is where the user acceleration and device gravity values are taken from.
    func deviceMotionUpdates() {
        //although main is not recommended by apple, with (admittedly limited) trials of other options, i found nothing else that would work as effectively. The operation queue is prone to blocking, and main was the only option (again with limited testing) that worked.
        motionManager.startDeviceMotionUpdates(using: .xArbitraryZVertical, to: .main) { (deviceMotion, error) in
            if deviceMotion != nil {
                self.motionManager.startAccelerometerUpdates(to: .main) { (accelerometerData, error) in
                    if accelerometerData != nil {
                        self.addMovementSampleToDataArray(deviceMotionSample: deviceMotion!, accelerometerSample: accelerometerData!)
                    }
                }
                //only needed for os_log, uncomment if you want to os_log the values in the function.
                //This is very resource intensive and will likely cause the app to crash if used in conjunction with sending messages over Watch Connectivity due to CPU load.
                //os_log is how I gained the initial values for gravity to put into graphs to create the boundaries for movement detection.
//                self.processDeviceMotionLogs(deviceMotion: deviceMotion!)
                }
                self.movementToCommand()
        }
    }
    
    func movementToCommand() {
        
        //Decide the command to send based on the values of gravity for basic movement.
        guard let x = motionManager.deviceMotion?.gravity.x else {return}
        guard let y = motionManager.deviceMotion?.gravity.y else {return}
        guard let z = motionManager.deviceMotion?.gravity.z else {return}
        
        //rc left/right forward/backward up/down yaw - rc command order - for reference, former in negative values -100 - 0, latter 0 - 100.
        if currentIndexInPredictionWindow == 25 || currentIndexInPredictionWindow == 50 {
            if value(x, isNear: 0) && value(y, isNear: 0) && value(z, isNear: -1) {
                //hover
                DispatchQueue.main.async {
                    self.sendMessage(commandToSend: FlyCommands.hover)
                }
                print("--- Hover ---")
            }
            else if value(x, isNear: 1) && value(y, isNear: 0) && value(z, isNear: -0.2) {
                //point to floor
                DispatchQueue.main.async {
                    self.sendMessage(commandToSend: FlyCommands.descend)
                }
                print("--- Descend ---")
            }
            else if value(x, isNear: -1) && value(y, isNear: 0) && value(z, isNear: 0) {
                //point to sky
                DispatchQueue.main.async {
                    self.sendMessage(commandToSend: FlyCommands.ascend)
                }
                print("--- Ascend ---")
            }
            else if value(x, isNear: 0) && value(y, isNear: -1) && value(z, isNear: 0) {
                //wrist tilt right
                DispatchQueue.main.async {
                    self.sendMessage(commandToSend: FlyCommands.flyRight)
                }
                print("--- Fly Right (stage left) ---")
            }
            else if value(x, isNear: 0) && value(y, isNear: 1) && value(z, isNear: 0) {
                //wrist tilt left
                DispatchQueue.main.async {
                    self.sendMessage(commandToSend: FlyCommands.flyLeft)
                }
                print("--- Fly Left (stage right) ---")
            }
            else if value(x, isNear: -0.5) && value(y, isNear: 0) && value(z, isNear: -1) {
                //half up
                DispatchQueue.main.async {
                    self.sendMessage(commandToSend: FlyCommands.flyForward)
                }
                print("--- Fly Forwards ---")
            }
            else if value(x, isNear: 0.5) && value(y, isNear: 0) && value(z, isNear: -1) {
                //half down
                DispatchQueue.main.async {
                    self.sendMessage(commandToSend: FlyCommands.flyBackward)
                }
                print("--- Fly Backwards ---")
            }
            else {
                DispatchQueue.main.async {
                    self.sendMessage(commandToSend: FlyCommands.hover)
                }
                print("--- Else Hover ---")
            }
            //Not a great way to limit blocking on the main thread, but without clearing the main thread a backlog will begin to grow. Every operation added to the main queue adds up and over a longer period of time the queue may incur a massive delay and ruin the users experience. 
            if OperationQueue.main.operationCount > 5 {
                OperationQueue.main.cancelAllOperations()
            }
        }
        }
    
    //Function to check if two values are within gravity precision to one another. Gravity precision is set at 0.20, so if the desired number is 1, and the actual value is > 0.8, it will still be processed as correct. As long as it is +/-0.20 from its desired value it is processed as the desired value. This is to add some forgiveness to the movement commands for users as specific values will not be reliably attainable. The movement commands are distinguishable enough to allow for this type of leniency. If the drone needed to fly on more axes of movement (e.g including non-cardinal compass directionality) then these values would have to be checked and ammended to ensure there was no overlap causing confusion; however the human arm has it's own movement limitations, especially when controlling with single wrist movement in 3D space. This is likely why VR headsets, RC drone controllers, drone flying apps etc. all come with two joysticks as input.
    func value(_ value: Double, isNear nearValue: Double) -> Bool {
        return (value > (nearValue - gravityPrecision)) && (value < (nearValue + gravityPrecision))
    }
    
    func addMovementSampleToDataArray (deviceMotionSample: CMDeviceMotion, accelerometerSample: CMAccelerometerData) {
        // Add the current user acceleration reading to the data array
        
        motionUserAccelerationX[[currentIndexInPredictionWindow] as [NSNumber]] = deviceMotionSample.userAcceleration.x as NSNumber
        motionUserAccelerationY[[currentIndexInPredictionWindow] as [NSNumber]] = deviceMotionSample.userAcceleration.y as NSNumber
        motionUserAccelerationZ[[currentIndexInPredictionWindow] as [NSNumber]] = deviceMotionSample.userAcceleration.z as NSNumber
        
        motionRotationRateX[[currentIndexInPredictionWindow] as [NSNumber]] = deviceMotionSample.rotationRate.x as NSNumber
        motionRotationRateY[[currentIndexInPredictionWindow] as [NSNumber]] = deviceMotionSample.rotationRate.y as NSNumber
        motionRotationRateZ[[currentIndexInPredictionWindow] as [NSNumber]] = deviceMotionSample.rotationRate.z as NSNumber
        
        accelerometerAccelerationX[[currentIndexInPredictionWindow] as [NSNumber]] = accelerometerSample.acceleration.x as NSNumber
        accelerometerAccelerationY[[currentIndexInPredictionWindow] as [NSNumber]] = accelerometerSample.acceleration.y as NSNumber
        accelerometerAccelerationZ[[currentIndexInPredictionWindow] as [NSNumber]] = accelerometerSample.acceleration.z as NSNumber

        // Update the index in the prediction window data array
        currentIndexInPredictionWindow += 1

        // If the data array is full, call the prediction method to get a new model prediction.
        // We assume here for simplicity that the Gyro data was added to the data arrays as well.
        if (currentIndexInPredictionWindow == ModelConstants.predictionWindowSize) {
            if let predictedActivity = performModelPrediction() {
                
                // Use the predicted activity here
                // ...
                //else do nothing.
                if (delayCounter == 1) {
                    switch predictedActivity {
                    case Action.leftRoll:
                        self.sendMessage(commandToSend: Flip.right)
                        print("----- RIGHT ROLL -----")
                        delayCounter = 0
                        break
                    case Action.rightRoll:
                        self.sendMessage(commandToSend: Flip.left)
                        print("----- LEFT ROLL -----")
                        delayCounter = 0
                        break
                    case Action.frontFlip:
                        self.sendMessage(commandToSend: Flip.front)
                        print("----- FRONT FLIP -----")
                        delayCounter = 0
                        break
                    case Action.backFlip:
                        self.sendMessage(commandToSend: Flip.back)
                        print("----- BACKFLIP -----")
                        delayCounter = 0
                        break
                    case Action.doNothing:
                        self.sendMessage(commandToSend: FlyCommands.hover)
                        print("----- DOING NOTHING -----")
                        delayCounter = 0
                        break
                    default:
                        delayCounter = 0
                        break
                    }
                }
                else {
                    delayCounter+=1
                }

                // Start a new prediction window
                currentIndexInPredictionWindow = 0
            }
        }
    }
    
        // Perform model prediction using the MLMultiArrays that have been populated with the data from device motion.
        func performModelPrediction () -> String? {
            // Perform model prediction
            let modelPrediction = try! activityClassificationModel.prediction(accelerometerAccelerationX: accelerometerAccelerationX, accelerometerAccelerationY: accelerometerAccelerationY, accelerometerAccelerationZ: accelerometerAccelerationZ, motionRotationRateX: motionRotationRateX, motionRotationRateY: motionRotationRateY, motionRotationRateZ: motionRotationRateZ, motionUserAccelerationX: motionUserAccelerationX, motionUserAccelerationY: motionUserAccelerationY, motionUserAccelerationZ: motionUserAccelerationZ, stateIn: nil)

            // Update the state vector
            stateIn = modelPrediction.stateOut
            
            //Upon testing the models predictions, I added this code to catch false positives. This was another recommendation from Yuxin Bai, an Apple engineer working on CoreML.
            //With this the model must provide a probability over 60% for it to be considered a recognised action or it will return 5, which is "do nothing"
            if (modelPrediction.labelProbability[Action.leftRoll]?.isLess(than: 0.60))! && modelPrediction.label == Action.leftRoll {
                return Action.doNothing
            }
            else if (modelPrediction.labelProbability[Action.rightRoll]?.isLess(than: 0.60))! && modelPrediction.label == Action.rightRoll {
                return Action.doNothing
            }
            else if (modelPrediction.labelProbability[Action.frontFlip]?.isLess(than: 0.60))! && modelPrediction.label == Action.frontFlip {
                return Action.doNothing
            }
            else if (modelPrediction.labelProbability[Action.backFlip]?.isLess(than: 0.60))! && modelPrediction.label == Action.backFlip {
                return Action.doNothing
            }
            else {
                return modelPrediction.label
            }
        }
}
