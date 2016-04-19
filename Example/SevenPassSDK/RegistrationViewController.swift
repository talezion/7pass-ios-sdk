//
//  RegistrationViewController.swift
//  SevenPass
//
//  Created by Jan Votava on 08/01/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import UIKit
import SevenPassSDK

class RegistrationViewController: UIViewController {
    @IBOutlet weak var login: UITextField!
    @IBOutlet weak var password: UITextField!
    @IBOutlet weak var loginErrorLabel: UILabel!
    @IBOutlet weak var passwordErrorLabel: UILabel!

    let sso = SsoManager.sharedInstance.sso
    var client: SevenPassClient!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.

        sso.authorize(
            parameters: [
                "grant_type": "client_credentials",
            ],
            success: { tokenSet in
                self.client = self.sso.credentialsClient(tokenSet)
            },
            failure: errorHandler
        )

        login.addTarget(self, action: #selector(RegistrationViewController.loginFieldChanged(_:)), forControlEvents: .EditingChanged)
        password.addTarget(self, action: #selector(RegistrationViewController.passwordFieldChanged(_:)), forControlEvents: .EditingChanged)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func showAlert(title title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        let defaultAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
        alertController.addAction(defaultAction)

        presentViewController(alertController, animated: true, completion: nil)
    }

    private func errorHandler(error: NSError) {
        showAlert(title: "Error", message: error.localizedDescription)
    }

    // Simple login field debouncer
    var loginFieldDebounceTimer: NSTimer?

    @IBAction func loginFieldChanged(sender: AnyObject) {
        if let timer = loginFieldDebounceTimer {
            timer.invalidate()
        }
        loginFieldDebounceTimer = NSTimer(timeInterval: 0.5, target: self, selector: #selector(RegistrationViewController.checkMail), userInfo: nil, repeats: false)
        NSRunLoop.currentRunLoop().addTimer(loginFieldDebounceTimer!, forMode: "NSDefaultRunLoopMode")
    }

    // Simple password field debouncer
    var passwordFieldDebounceTimer: NSTimer?

    @IBAction func passwordFieldChanged(sender: AnyObject) {
        if let timer = passwordFieldDebounceTimer {
            timer.invalidate()
        }
        passwordFieldDebounceTimer = NSTimer(timeInterval: 0.5, target: self, selector: #selector(RegistrationViewController.checkPassword), userInfo: nil, repeats: false)
        NSRunLoop.currentRunLoop().addTimer(passwordFieldDebounceTimer!, forMode: "NSDefaultRunLoopMode")
    }

    func checkMail() {
        client.post("checkMail",
            parameters: [
                "email": self.login.text!,
                "flags": [
                    "client_id": self.sso.configuration.consumerKey
                ]
            ],
            success: { json, response in
                if let error = json["data"]?["error"] as? String {
                    self.loginErrorLabel.text = error
                    self.loginErrorLabel.hidden = false
                } else {
                    self.loginErrorLabel.text = nil
                    self.loginErrorLabel.hidden = true
                }

            },
            failure: self.errorHandler)
    }

    func checkPassword() {
        client.post("checkPassword",
            parameters: [
                "password": self.password.text!
            ],
            success: { json, response in
                if let errors = json["data"]?["errors"] as? [String] {
                    self.passwordErrorLabel.text = errors.joinWithSeparator(", ")
                    self.passwordErrorLabel.hidden = false
                } else {
                    self.passwordErrorLabel.text = nil
                    self.passwordErrorLabel.hidden = true
                }

            },
            failure: self.errorHandler)
    }

    @IBAction func signUp(sender: AnyObject) {
        client.post("registration",
            parameters: [
                "email": self.login.text!,
                "password": self.password.text!,
                "flags": [
                    "client": [
                        "id": self.sso.configuration.consumerKey
                    ]
                ]
            ],
            success: { json, response in
                self.showAlert(title: "Result", message: json.description)
            },
            failure: self.errorHandler)
    }
}
