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

        login.addTarget(self, action: #selector(RegistrationViewController.loginFieldChanged(_:)), for: .editingChanged)
        password.addTarget(self, action: #selector(RegistrationViewController.passwordFieldChanged(_:)), for: .editingChanged)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func showAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let defaultAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(defaultAction)

        present(alertController, animated: true, completion: nil)
    }

    // Simple login field debouncer
    var loginFieldDebounceTimer: Timer?

    @IBAction func loginFieldChanged(_ sender: AnyObject) {
        if let timer = loginFieldDebounceTimer {
            timer.invalidate()
        }
        loginFieldDebounceTimer = Timer(timeInterval: 0.5, target: self, selector: #selector(RegistrationViewController.checkMail), userInfo: nil, repeats: false)
        RunLoop.current.add(loginFieldDebounceTimer!, forMode: RunLoopMode(rawValue: "NSDefaultRunLoopMode"))
    }

    // Simple password field debouncer
    var passwordFieldDebounceTimer: Timer?

    @IBAction func passwordFieldChanged(_ sender: AnyObject) {
        if let timer = passwordFieldDebounceTimer {
            timer.invalidate()
        }
        passwordFieldDebounceTimer = Timer(timeInterval: 0.5, target: self, selector: #selector(RegistrationViewController.checkPassword), userInfo: nil, repeats: false)
        RunLoop.current.add(passwordFieldDebounceTimer!, forMode: RunLoopMode(rawValue: "NSDefaultRunLoopMode"))
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
                    self.loginErrorLabel.isHidden = false
                } else {
                    self.loginErrorLabel.text = nil
                    self.loginErrorLabel.isHidden = true
                }

            },
            failure: errorHandler)
    }

    func checkPassword() {
        client.post("checkPassword",
            parameters: [
                "password": self.password.text!
            ],
            success: { json, response in
                if let errors = json["data"]?["errors"] as? [String] {
                    self.passwordErrorLabel.text = errors.joined(separator: ", ")
                    self.passwordErrorLabel.isHidden = false
                } else {
                    self.passwordErrorLabel.text = nil
                    self.passwordErrorLabel.isHidden = true
                }

            },
            failure: errorHandler)
    }

    @IBAction func signUp(_ sender: AnyObject) {
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
            failure: errorHandler)
    }
}
