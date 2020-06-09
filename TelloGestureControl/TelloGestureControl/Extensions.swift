//
//  Extensions.swift
//  TelloGestureControl
//
//  Created by Daniel Beech on 02/04/2020.
//  Copyright © 2020 Dan Beech. All rights reserved.
//

import Foundation
import UIKit

extension UIColor {
    
    //A convenience method I like to use to make typing of rgb values easier throughout projects.
    //Saves you time when using RGB values regularly, I generally add this to any project before I do anything else.
    static func rgb(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) -> UIColor {
        return UIColor(red: red/255, green: green/255, blue: blue/255, alpha: alpha/1)
    }
}
