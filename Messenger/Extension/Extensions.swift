//
//  Extensions.swift
//  Messenger
//
//  Created by Bruno Gomez on 2/22/22.
//

import Foundation
import UIKit

extension UIView {
    public var width: CGFloat {
        return self.frame.size.width
    }
    public var height: CGFloat {
        return self.frame.size.height
    }
    public var top: CGFloat {
        return self.frame.origin.y
    }
    public var bottom: CGFloat {
        return self.frame.size.height + self.frame.origin.y
    }
    public var left: CGFloat {
        return self.frame.origin.x
    }
    public var right: CGFloat {
        return self.frame.size.width + self.frame.origin.x
    }
}


//https://stackoverflow.com/questions/11598043/get-slightly-lighter-and-darker-color-from-uicolor
extension UIColor {
  class func darkerColorForColor(color: UIColor) -> UIColor {
    var r:CGFloat = 0, g:CGFloat = 0, b:CGFloat = 0, a:CGFloat = 0
    if color.getRed(&r, green: &g, blue: &b, alpha: &a){
      return UIColor(red: max(r - 0.2, 0.0), green: max(g - 0.2, 0.0), blue: max(b - 0.2, 0.0), alpha: a)
    }
    return UIColor()
  }

  class func lighterColorForColor(color: UIColor) -> UIColor {
    var r:CGFloat = 0, g:CGFloat = 0, b:CGFloat = 0, a:CGFloat = 0
    if color.getRed(&r, green: &g, blue: &b, alpha: &a){
      let tmpColor = UIColor(red: min(r + 0.2, 1.0), green: min(g + 0.2, 1.0), blue: min(b + 0.2, 1.0), alpha: a)
      return tmpColor
    }
    return UIColor()
  }
}

extension Notification.Name {
    static let didLogInNotification = Notification.Name("didLogInNotification")
}
