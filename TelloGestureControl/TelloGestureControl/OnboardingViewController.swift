//
//  OnboardingViewController.swift
//  TelloGestureControl
//
//  Created by Daniel Beech on 02/04/2020.
//  Copyright © 2020 Dan Beech. All rights reserved.
//

import Foundation
import UIKit
import paper_onboarding

class OnboardingViewController: UIViewController, PaperOnboardingDataSource, PaperOnboardingDelegate {
        
    @IBOutlet weak var onboardingView: OnboardingView!
    
    @IBOutlet weak var getStartedButton: UIButton!
    @IBAction func getStartedButtonAction(_ sender: Any) {
        //handled in storyboard.
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //Any additional setup after loading the view.
        setupUI()
        onboardingView.dataSource = self
        onboardingView.delegate = self
    }
    
    func setupUI() {
        //do UI placement and sizing for get started button, because storyboards aren't useful and it takes too much time.
        getStartedButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -150).isActive = true
        getStartedButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        getStartedButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: (view.frame.width)/6).isActive = true
        getStartedButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -(view.frame.width)/6).isActive = true
        getStartedButton.heightAnchor.constraint(equalToConstant: 50.0).isActive = true
        
        getStartedButton.layer.cornerRadius = 20
        
        getStartedButton.clipsToBounds = true
        getStartedButton.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(getStartedButton)
    }
    
    func onboardingItemsCount() -> Int {
            return 9
        }
        
        func onboardingItem(at index: Int) -> OnboardingItemInfo {
            let firstPageBgColor = UIColor.rgb(red: 106, green: 166, blue: 211, alpha: 1)
            let secondPageBgColor = UIColor.rgb(red: 168, green: 200, blue: 78, alpha: 1)
            
            let titleFont = UIFont(name: "HelveticaNeue-Bold", size: 24)
            let descriptionFont = UIFont(name: "HelveticaNeue-Medium", size: 18)
            
            let onboardingItemInfoArray = [OnboardingItemInfo(informationImage: #imageLiteral(resourceName: "droneIcon"), title: "Welcome!", description: "Welcome to Tello Gesture Control, follow these steps to get started controlling your drone using your Apple Watch!", pageIcon: #imageLiteral(resourceName: "whiteCircle"), color: firstPageBgColor, titleColor: UIColor.white, descriptionColor: UIColor.white, titleFont: titleFont ?? UIFont.systemFont(ofSize: 24), descriptionFont: descriptionFont ?? UIFont.systemFont(ofSize: 18), descriptionLabelPadding: 24.0),
                                           
                                           OnboardingItemInfo(informationImage: #imageLiteral(resourceName: "wifi"), title: "Connect to the drones Wi-Fi", description: "Ensure that you are connected to the drones Wi-Fi network before opening the app.", pageIcon: #imageLiteral(resourceName: "whiteCircle"), color: secondPageBgColor, titleColor: UIColor.white, descriptionColor: UIColor.white, titleFont: titleFont ?? UIFont.systemFont(ofSize: 24), descriptionFont: descriptionFont ?? UIFont.systemFont(ofSize: 18), descriptionLabelPadding: 24.0),
                                           
                                           OnboardingItemInfo(informationImage: #imageLiteral(resourceName: "phoneFirst"), title: "Open the iPhone app first", description: "Once you're connected to the Wi-Fi network, open the iPhone app, then the Watch app. You'll see a green light on the drone.", pageIcon: #imageLiteral(resourceName: "whiteCircle"), color: firstPageBgColor, titleColor: UIColor.white, descriptionColor: UIColor.white, titleFont: titleFont ?? UIFont.systemFont(ofSize: 24), descriptionFont: descriptionFont ?? UIFont.systemFont(ofSize: 18), descriptionLabelPadding: 24.0),
                                           
                                           OnboardingItemInfo(informationImage: #imageLiteral(resourceName: "hoverPose"), title: "Start Flying!", description: "Point the drone camera at you, hold your arm out perpendicular to the floor (let's call this the hover position), and twist your wrist left or right to fly in that direction. Return to hover position to stop.", pageIcon: #imageLiteral(resourceName: "whiteCircle"), color: secondPageBgColor, titleColor: UIColor.white, descriptionColor: UIColor.white, titleFont: titleFont ?? UIFont.systemFont(ofSize: 24), descriptionFont: descriptionFont ?? UIFont.systemFont(ofSize: 18), descriptionLabelPadding: 24.0),
                                           
                                           OnboardingItemInfo(informationImage: #imageLiteral(resourceName: "moreControls"), title: "More Controls", description: "While you're in hover position, raise your arm approx. 45 degrees to fly forwards, lower it 45 degrees to fly backwards. \nPoint to the sky to ascend, point to the floor to descend.", pageIcon: #imageLiteral(resourceName: "whiteCircle"), color: firstPageBgColor, titleColor: UIColor.white, descriptionColor: UIColor.white, titleFont: titleFont ?? UIFont.systemFont(ofSize: 24), descriptionFont: descriptionFont ?? UIFont.systemFont(ofSize: 18), descriptionLabelPadding: 24.0),
                                           
                                           OnboardingItemInfo(informationImage: #imageLiteral(resourceName: "tricks"), title: "The fun bit... Tricks!", description: "There are 4 tricks the drone can perform while flying. \nLeft/Right Roll, and Front/Back Flip.", pageIcon: #imageLiteral(resourceName: "whiteCircle"), color: secondPageBgColor, titleColor: UIColor.white, descriptionColor: UIColor.white, titleFont: titleFont ?? UIFont.systemFont(ofSize: 24), descriptionFont: descriptionFont ?? UIFont.systemFont(ofSize: 18), descriptionLabelPadding: 24.0),
                                           
                                           OnboardingItemInfo(informationImage: #imageLiteral(resourceName: "tricks"), title: "Performing the tricks", description: "Make a small circle around the X axis to do a roll. \nMake a circle around the Y axis with your whole arm to do a flip!", pageIcon: #imageLiteral(resourceName: "whiteCircle"), color: firstPageBgColor, titleColor: UIColor.white, descriptionColor: UIColor.white, titleFont: titleFont ?? UIFont.systemFont(ofSize: 24), descriptionFont: descriptionFont ?? UIFont.systemFont(ofSize: 18), descriptionLabelPadding: 24.0),
                                           
                                           OnboardingItemInfo(informationImage: #imageLiteral(resourceName: "safety"), title: "Tips and safety!", description: "Do the actions multiple times in a row to increase accuracy, and stay safe! \nKeep the phone in your other hand to use the emergency button easily, dont fly in windy conditions or you'll lose your drone (trust me), and respect others!", pageIcon: #imageLiteral(resourceName: "whiteCircle"), color: secondPageBgColor, titleColor: UIColor.white, descriptionColor: UIColor.white, titleFont: titleFont ?? UIFont.systemFont(ofSize: 24), descriptionFont: descriptionFont ?? UIFont.systemFont(ofSize: 18), descriptionLabelPadding: 24.0),
                                           
                                           OnboardingItemInfo(informationImage: #imageLiteral(resourceName: "droneIcon"), title: "Have fun!", description: "", pageIcon: #imageLiteral(resourceName: "whiteCircle"), color: firstPageBgColor, titleColor: UIColor.white, descriptionColor: UIColor.white, titleFont: titleFont ?? UIFont.systemFont(ofSize: 24), descriptionFont: descriptionFont ?? UIFont.systemFont(ofSize: 18), descriptionLabelPadding: 24.0)]
            
            return onboardingItemInfoArray[index]
        }
    
    //delegate protocols. They are used to animate the button in and out of view and disable it when its not the correct page to display it, and then enable it when its needed.
    func onboardingWillTransitonToIndex(_ index: Int) {
        if index == 7 {
            if self.getStartedButton.alpha == 1 {
                UIView.animate(withDuration: 0.2) {
                    self.getStartedButton.isHidden = true
                    self.getStartedButton.isEnabled = false
                    self.getStartedButton.alpha = 0
                }
            }
        }
    }
    func onboardingDidTransitonToIndex(_ index: Int) {
        if index == 8 {
            self.getStartedButton.isEnabled = true
            self.getStartedButton.isHidden = false
            UIView.animate(withDuration: 0.4) {
                self.getStartedButton.alpha = 1
            }
        }
    }
    
}


