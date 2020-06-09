//
//  ViewController.swift
//  TelloGestureControl
//
//  Created by Daniel Beech on 05/03/2020.
//  Copyright © 2020 Dan Beech. All rights reserved.
//

import UIKit //user interface components.
import CocoaAsyncSocket //to use socket connections and send drone commands to specific udp port.
import WatchConnectivity //to create a two-way communication stream between iPhone and Watch.
import paper_onboarding //to add onboarding to the app to give users an explanation of how to use it the first time they open it.

//Global variables.
var socket = GCDAsyncUdpSocket()
let sendHost = "192.168.10.1"
let sendPort: UInt16 = 8889
let statePort: UInt16 = 8890
var lastMessage: CFAbsoluteTime = 0
var currentFlyingState = 0
let defaults = UserDefaults.standard //to store a boolean to display/hide onboarding on app launch.
 
class ViewController: UIViewController, GCDAsyncUdpSocketDelegate, WCSessionDelegate, PaperOnboardingDelegate {
    
    //START ENUMS
    //Enums allow code to be readable. Replacing strings in code with variable names makes it much easier to use and update moving forward.
    enum FlyCommands {
        static let movement = "rc"
        static let hover = "rc 0 0 0 0"
        static let takeOff = "takeoff"
        static let land = "land"
        static let emergencyLanding = "emergency"
        static let startUp = "command"
    }
    
    enum Flip {
        static let right = "flip r"
        static let left = "flip l"
        static let front = "flip f"
        static let back = "flip b"
        static let any = "flip"
    }
    //END ENUMS.
    
//---------------   START UI   ---------------\\
    //The UI components for the application. They are split into sections and have verbose names so that they are easy to identify, and you will know what they do.
    @IBOutlet var mainViewOutlet: UIView!
    
    @IBOutlet weak var takeOffButtonViewOutlet: UIView!
    @IBOutlet weak var takeOffButtonOutlet: UIButton!
    @IBAction func takeOffButtonAction(_ sender: Any) {
        //a simple check to see if the drone is flying, and if so, land - and vice versa.
        //this could have been done with the statePort of the drone, but with the amount of messages being sent there may be a delay before the command is received and that is dangerous so it is instead handled using a global variable to check state.
        if currentFlyingState == 0 {
            sendCommand(command: FlyCommands.takeOff)
            print("take off pressed")
            currentFlyingState+=1
            takeOffButtonOutlet.setTitle("Land", for: .normal)
            takeOffButtonOutlet.backgroundColor = UIColor.rgb(red: 255, green: 184, blue: 77, alpha: 1)
            let message = ["Message": FlyCommands.takeOff]
            WCSession.default.sendMessage(message, replyHandler: nil)
        }
        else {
            sendCommand(command: FlyCommands.land)
            print("land pressed")
            currentFlyingState = 0
            takeOffButtonOutlet.setTitle("Take Off", for: .normal)
            takeOffButtonOutlet.backgroundColor = UIColor.rgb(red: 168, green: 200, blue: 78, alpha: 1)
            OperationQueue.main.cancelAllOperations()
        }
    }
    
    @IBOutlet weak var emergencyLandingButtonViewOutlet: UIView!
    @IBOutlet weak var emergencyButtonOutlet: UIButton!
    @IBAction func emergencyButtonAction(_ sender: Any) {
        sendCommand(command: FlyCommands.emergencyLanding)
        let message = ["Message": "Emergency"]
        WCSession.default.sendMessage(message, replyHandler: nil)
    }
    
    @IBOutlet weak var currentPredictionViewOutlet: UIView!
    @IBOutlet weak var actionLabelOutlet: UILabel!
    @IBOutlet weak var currentTrickOutlet: UILabel!
    //END UI
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //call the function to setup the views programmatically.
        setupUI()
        //by setting this value to true the onboarding pages will be disabled on launch, but only if the user has completed them and gotten to the main app once.
        defaults.set(true, forKey: "IsFirstLaunch")
        
        //Check if watch connectivity is supported by the devices, if it is then set the delegate for the connectivity session and activate the session.
        if (WCSession.isSupported()) {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
        
        
    }
    
    //override the viewWillAppear function and call two necessary functions setupCommand, and setupListener.
    override func viewWillAppear(_ animated: Bool) {
        setupCommand()
        setupListener()
    }
    
    //needed to send commands to the drone, and setup a delegate for sending communications via the sockets I set up in global variables. The socket is bound to the sendPort global variable.
    func setupCommand() {
        // Set the delegate, which is this view controller, and therefore the value is self. And set the dispatch queue to main.
        socket.setDelegate(self)
        socket.setDelegateQueue(DispatchQueue.main)
        
        // Send the "command" command to the socket.
        do {
            try socket.bind(toPort: sendPort)
            try socket.enableBroadcast(true)
            try socket.beginReceiving()
            //send the initial command to the drone to setup the socket and establish connection. Light will go green on the drone to indicate that this command has been received and the drone is ready to communicate over the deisgnated communication port.
            socket.send(FlyCommands.startUp.data(using: String.Encoding.utf8)!,
                        toHost: sendHost,
                        port: sendPort,
                        withTimeout: 0,
                        tag: 0)
        } catch {
            print("'command' command sent.")
        }
    }
    
    //needed to setup listening for commands from the drone, uses the statePort global variable. It is called statePort as it listens for the returned current state of the drone. The drone will indicate any potential connection issues here.
    func setupListener() {
        let receiveSocket = GCDAsyncUdpSocket(delegate: self, delegateQueue: DispatchQueue.main)
        do {
            try receiveSocket.bind(toPort: statePort)
        } catch {
            print("Bind Problem")
        }
        
        do {
            try receiveSocket.beginReceiving()
        } catch {
            print("Receiving Problem")
        }
    }
    
    //function that allows us to call it with a string as an argument, the string will then be sent to the drone as a command. Commands are case sensitive.
    func sendCommand(command: String) {
        let message = command.data(using: String.Encoding.utf8)
        socket.send(message!, toHost: sendHost, port: sendPort, withTimeout: 2, tag: 0)
    }
    
    //delegate method. Only deals with receiving data from the UDP port as then we dont need to complete the rest of the delegate methods for the socket framework as we don't need them.
    func udpSocket(_ sock: GCDAsyncUdpSocket, didReceive data: Data, fromAddress address: Data, withFilterContext filterContext: Any?) {
        guard let dataString = String(data: data, encoding: String.Encoding.utf8)
            else {
            print("Error converting dataString - func udpSocket - didReceive")
                return
        }
        if (sock.localPort() == sendPort) {
            print(dataString)
        }
        
        if (sock.localPort() == statePort) {
            print(dataString)
        }
    }
    
    //sending messages from iPhone to Watch, with rate limiting to avoid blocking.
    func sendWatchMessage() {
        let currentTime = CFAbsoluteTimeGetCurrent()

        // if less than half a second has passed, do not send another message.
        if lastMessage + 0.5 > currentTime {
            return
        }

        // send a message to the watch if it's reachable
        if (WCSession.default.isReachable) {
            // this is a meaningless message, but it's enough to ensure that the connectivity session has been setup correctly.
            let message = ["Message": "Reachable"]
            WCSession.default.sendMessage(message, replyHandler: nil)
        }

        // update our rate limiting property
        lastMessage = CFAbsoluteTimeGetCurrent()
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        
        guard let messageToString = message["request"] as? String else {return}
        print("MESSAGE TO STRING VALUE ---- \(messageToString) ----")
        if (messageToString.contains(FlyCommands.movement)) {
            sendCommand(command: messageToString)
            replyHandler(["received" : "RC command Received"])
            print("Flying with RC co-ords.")
        }
        else if (messageToString.contains(Flip.any)) {
                    sendCommand(command: messageToString)
            
            if messageToString == Flip.left {
                    DispatchQueue.main.async {
                        self.actionLabelOutlet.text = "Left Roll"
                    }
                }
            else if messageToString == Flip.right {
                    DispatchQueue.main.async {
                        self.actionLabelOutlet.text = "Right Roll"
                    }
                }
            else if messageToString == Flip.front {
                    DispatchQueue.main.async {
                        self.actionLabelOutlet.text = "Front Flip"
                    }
                }
            else if messageToString == Flip.back {
                    DispatchQueue.main.async {
                        self.actionLabelOutlet.text = "Back Flip"
                    }
                }
                else {
                    DispatchQueue.main.async {
                        self.actionLabelOutlet.text = "No Detected Action"
                    }
                }
                replyHandler(["received" : "FLIP command Received"])
                print("Performing flip")
                }
        else if message["request"] as? String == FlyCommands.takeOff {
            sendCommand(command: FlyCommands.takeOff)
            replyHandler(["received" : "Taking off"])
            print("Take Off initiated.")
            currentFlyingState+=1
            takeOffButtonOutlet.setTitle("Land", for: .normal)
            takeOffButtonOutlet.backgroundColor = UIColor.rgb(red: 255, green: 184, blue: 77, alpha: 1)
        }
        else if message["request"] as? String == FlyCommands.emergencyLanding {
            sendCommand(command: FlyCommands.emergencyLanding)
            replyHandler(["received" : "EMERGENCY: MOTORS OFF"])
            print("Emergency stop performed.")
            OperationQueue.main.cancelAllOperations()
        }
        else {
            //This is useful as the drone is designed to land if no commands have been issued for a set period of time (15 seconds I think). So if commands are sent, even if the instruction is to hover and do nothing then it will remain in action.
            sendCommand(command: FlyCommands.hover)
        }
    }
    
    //Protocol stubs that were needed for Watch connectivity.
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("WC Session activated.")
    }
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("WC Session is now inactive.")
    }
    func sessionDidDeactivate(_ session: WCSession) {
        print("WC Session has deactivated.")
    }
}


//This was overcrowding the class, so it has been placed in this extension to make the code easier to read.
extension ViewController {
    //Setting up the views programmatically, as I've never actually used storyboards until this project and I don't want to use them ever again. This way of setting up views is much easier than using storyboards where everything is abstracted away or hidden in menus, that I have no idea how to use. With this technique code becomes easier to maintain, and if there are layout issues you know that it was you who messed up and not xcode which makes debugging much easier, as well as being able to move layouts on the fly without updating all constraints which has a track record of breaking things when using the recommended constraints. It's just logically a better option for UI.
    func setupUI(){
        //START ANCHOR VALUES.
        takeOffButtonViewOutlet.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        takeOffButtonViewOutlet.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.25).isActive = true
        takeOffButtonViewOutlet.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        takeOffButtonOutlet.widthAnchor.constraint(equalTo: takeOffButtonViewOutlet.widthAnchor).isActive = true
        takeOffButtonOutlet.heightAnchor.constraint(equalTo: takeOffButtonViewOutlet.heightAnchor).isActive = true
        
        emergencyLandingButtonViewOutlet.topAnchor.constraint(equalTo: takeOffButtonViewOutlet.bottomAnchor).isActive = true
        emergencyLandingButtonViewOutlet.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.25).isActive = true
        emergencyLandingButtonViewOutlet.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        emergencyButtonOutlet.widthAnchor.constraint(equalTo: emergencyLandingButtonViewOutlet.widthAnchor).isActive = true
        emergencyButtonOutlet.heightAnchor.constraint(equalTo: emergencyLandingButtonViewOutlet.heightAnchor).isActive = true
        
        let currentTrickOffset = currentPredictionViewOutlet.frame.height/4
        currentPredictionViewOutlet.topAnchor.constraint(equalTo: emergencyLandingButtonViewOutlet.bottomAnchor).isActive = true
        currentPredictionViewOutlet.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        currentPredictionViewOutlet.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true

        currentTrickOutlet.topAnchor.constraint(equalTo: currentPredictionViewOutlet.topAnchor,constant: currentTrickOffset-12).isActive = true
        currentTrickOutlet.centerXAnchor.constraint(equalTo: currentPredictionViewOutlet.centerXAnchor).isActive = true
        actionLabelOutlet.topAnchor.constraint(equalTo: currentTrickOutlet.bottomAnchor, constant: 24).isActive = true
        actionLabelOutlet.centerXAnchor.constraint(equalTo: currentPredictionViewOutlet.centerXAnchor).isActive = true
        //END ANCHOR VALUES.
        
        //START AUTO MASKING FALSE.
        takeOffButtonViewOutlet.translatesAutoresizingMaskIntoConstraints = false
        takeOffButtonOutlet.translatesAutoresizingMaskIntoConstraints = false
        emergencyLandingButtonViewOutlet.translatesAutoresizingMaskIntoConstraints = false
        emergencyButtonOutlet.translatesAutoresizingMaskIntoConstraints = false
        currentPredictionViewOutlet.translatesAutoresizingMaskIntoConstraints = false
        currentTrickOutlet.translatesAutoresizingMaskIntoConstraints = false
        actionLabelOutlet.translatesAutoresizingMaskIntoConstraints = false
        //END AUTO MASKING FALSE.
        
        //START ADD SUBVIEWS.
        view.addSubview(currentPredictionViewOutlet)
        view.addSubview(takeOffButtonViewOutlet)
        view.addSubview(emergencyLandingButtonViewOutlet)
        
        takeOffButtonViewOutlet.addSubview(takeOffButtonOutlet)
        emergencyLandingButtonViewOutlet.addSubview(emergencyButtonOutlet)
        currentPredictionViewOutlet.addSubview(currentTrickOutlet)
        currentPredictionViewOutlet.addSubview(actionLabelOutlet)
        //END ADD SUBVIEWS.
        
        
    }
}
