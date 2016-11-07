//
//  LoginViewController.swift
//  SevenPass
//
//  Created by Jan Votava on 05/01/16.
//  Copyright © 2016 CocoaPods. All rights reserved.
//

import UIKit
import SevenPassSDK

class LoginViewController: UIViewController, UITextFieldDelegate {
    @IBOutlet weak var login: UITextField!
    @IBOutlet weak var password: UITextField!

    let sso = SsoManager.sharedInstance.sso
    var mainView: ViewController?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.

        mainView = parent as? ViewController
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func webview(_ sender: AnyObject) {
        sso.authorize(
            scopes: ["openid", "profile", "email"],
            success: { tokenSet in
                self.updateTokenSet(tokenSet)
                self.request()
            },
            failure: errorHandler
        )
    }

    @IBAction func autologin(_ sender: AnyObject) {
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

    @IBAction func loginPasswordLogin(_ sender: AnyObject) {
        sso.authorize(login: login.text!, password: password.text!,
            scopes: ["openid", "profile", "email"],
            success: { tokenSet in
                self.updateTokenSet(tokenSet)
                self.request()
            },
            failure: { error in
                // Let autologin handle interaction_required errors
                if let errorMessage = error.userInfo["error"] as? String , errorMessage == "interaction_required" {
                    let autologinToken = error.userInfo["autologin_token"] as! String

                    self.sso.autologin(
                        autologinToken: autologinToken,
                        scopes: ["openid", "profile", "email"],
                        params: ["response_type": "id_token+token"],
                        success: { tokenSet in
                            self.updateTokenSet(tokenSet)
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

    @IBAction func request(_ sender: AnyObject? = nil) {
        if let accountClient = SsoManager.sharedInstance.accountClient {
            accountClient.get("me",
                success: { json, response in
                    let accessTokenString = SsoManager.sharedInstance.tokenSet?.accessToken?.token

                    showAlert(title: "GET /api/accounts/me", message: "Access Token: \(accessTokenString)\n\n\(json.description)")
                },
                failure: { error in
                    errorHandler(error)
                }
            )
        } else {
            showAlert(title: "AccountClient missing", message: "Not logged in")
        }
    }

    func updateTokenSet(_ tokenSet: SevenPassTokenSet) {
        SsoManager.sharedInstance.updateTokenSet(tokenSet)
        SsoManager.sharedInstance.setAccountClient()
        mainView?.updateStatusbar()
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        loginPasswordLogin(textField)

        return true
    }
}
