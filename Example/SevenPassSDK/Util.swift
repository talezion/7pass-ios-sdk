//
//  Util.swift
//  SevenPass
//
//  Created by Jan Votava on 26/01/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import UIKit

func showAlert(title title: String, message: String) {
    if let topController = UIApplication.sharedApplication().keyWindow?.rootViewController {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        let defaultAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
        alertController.addAction(defaultAction)

        // Delay alert by 0.5s, so it doesn't collide with a WebView presentation
        let dispatchTime = dispatch_time(DISPATCH_TIME_NOW, 500000000)

        dispatch_after(dispatchTime, dispatch_get_main_queue(), {
            topController.presentViewController(alertController, animated: true, completion: nil)
        })
    }
}

func errorHandler(error: NSError) {
    showAlert(title: "Error", message: error.localizedDescription)
}