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
    var tokenSetCache: SevenPassTokenSetCache!
    var tokenSet: SevenPassTokenSet?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.

        tokenSetCache = SevenPassTokenSetCache(configuration: sso.configuration)
        tokenSet = tokenSetCache.load()

        updateStatusbar()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func refresh() {
        if let refreshTokenString = self.tokenSet?.refreshToken?.token {
            sso.authorize(refreshToken: refreshTokenString,
                success: { tokenSet in
                    self.updateTokenSet(tokenSet)
                    self.request()
                },
                failure: errorHandler
            )
        }
    }

    func logout() {
        updateTokenSet(nil)
        clearCookieStorage()
    }

    func clearCookieStorage() {
        let cookieStorage = NSHTTPCookieStorage.sharedHTTPCookieStorage()

        for cookie in cookieStorage.cookies! {
            cookieStorage.deleteCookie(cookie)
        }
    }

    func updateTokenSet(tokenSet: SevenPassTokenSet?) {
        self.tokenSet = tokenSet
        tokenSetCache.tokenSet = tokenSet

        if tokenSet == nil {
            tokenSetCache.delete()
        } else {
            tokenSetCache.save()
        }

        updateStatusbar()
    }

    func updateStatusbar() {
        let parentController = parentViewController as! ViewController
        let refresh = parentController.refreshButton
        let logout = parentController.logoutButton

        logout.target = self
        logout.action = Selector("logout")

        refresh.target = self
        refresh.action = Selector("refresh")

        let status = parentController.statusbar

        if let tokenSet = tokenSet {
            logout.enabled = true
            refresh.enabled = true
            status.title = tokenSet.email
        } else {
            logout.enabled = false
            refresh.enabled = false
            status.title = nil
        }
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
    
    @IBAction func webview(sender: AnyObject) {
        sso.authorize(
            scopes: ["openid", "profile", "email"],
            success: { tokenSet in
                self.updateTokenSet(tokenSet)
                self.request()
            },
            failure: errorHandler
        )
    }
    
    @IBAction func loginPasswordLogin(sender: AnyObject) {
        sso.authorize(login: login.text!, password: password.text!,
            scopes: ["openid", "profile", "email"],
            success: { tokenSet in
                self.updateTokenSet(tokenSet)
                self.request()
            },
            failure: errorHandler
        )
    }
    
    func request() {
        let client = self.sso.accountClient(tokenSet!)

        client.get("me",
            success: { json, response in
                let accessTokenString = self.tokenSet?.accessToken?.token

                self.showAlert(title: "GET /api/accounts/me", message: "Access Token: \(accessTokenString)\n\n\(json.description)")
            },
            failure: { error in
                self.logout()

                self.errorHandler(error)
            }
        )
    }

    func textFieldShouldReturn(textField: UITextField) -> Bool {
        loginPasswordLogin(textField)

        return true
    }
}
