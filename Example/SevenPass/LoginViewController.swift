//
//  LoginViewController.swift
//  SevenPass
//
//  Created by Jan Votava on 05/01/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import UIKit
import SevenPass

class LoginViewController: UIViewController, UITextFieldDelegate {
    @IBOutlet weak var login: UITextField!
    @IBOutlet weak var password: UITextField!

    let sso = SsoManager.sharedInstance.sso
    var mainView: ViewController?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.

        mainView = parentViewController as? ViewController
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func webview(sender: AnyObject) {
        sso.authorize(
            scopes: ["openid", "profile", "email"],
            success: { tokenSet in
                SsoManager.sharedInstance.updateTokenSet(tokenSet)
                self.mainView?.updateStatusbar()

                self.request()
            },
            failure: errorHandler
        )
    }

    @IBAction func autologin(sender: AnyObject) {
        if let tokenSet = SsoManager.sharedInstance.tokenSet {
            sso.autologin(tokenSet,
                scopes: ["openid", "profile", "email"],
                rememberMe: false,
                success: { token in
                    showAlert(title: "Autologin", message: "Successfully autologged in")
                },
                failure: errorHandler
            )
        } else {
            showAlert(title: "TokenSet missing", message: "Cannot autologin user without tokenSet")
        }
    }

    @IBAction func loginPasswordLogin(sender: AnyObject) {
        sso.authorize(login: login.text!, password: password.text!,
            scopes: ["openid", "profile", "email"],
            success: { tokenSet in
                SsoManager.sharedInstance.updateTokenSet(tokenSet)
                self.mainView?.updateStatusbar()

                self.request()
            },
            failure: { error in
                // Let autologin handle interaction_required errors
                if let errorMessage = error.userInfo["error"] as? String where errorMessage == "interaction_required" {
                    let autologinToken = error.userInfo["autologin_token"] as! String

                    self.sso.autologin(
                        autologinToken: autologinToken,
                        scopes: ["openid", "profile", "email"],
                        params: ["response_type": "id_token+token"],
                        success: { tokenSet in
                            SsoManager.sharedInstance.updateTokenSet(tokenSet)
                            self.mainView?.updateStatusbar()

                            self.request()
                        },
                        failure: errorHandler
                    )
                } else {
                    errorHandler(error)
                }
            }
        )
    }
    
    func request() {
        let client = self.sso.accountClient(SsoManager.sharedInstance.tokenSet!)

        client.get("me",
            success: { json, response in
                let accessTokenString = SsoManager.sharedInstance.tokenSet?.accessToken?.token

                showAlert(title: "GET /api/accounts/me", message: "Access Token: \(accessTokenString)\n\n\(json.description)")
            },
            failure: { error in
                errorHandler(error)
            }
        )
    }

    func textFieldShouldReturn(textField: UITextField) -> Bool {
        loginPasswordLogin(textField)

        return true
    }
}
