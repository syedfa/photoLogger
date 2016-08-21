//
//  LoginView.swift
//  photoLogger
//
//  Created by Richard Martin on 2016-08-10.
//  Copyright © 2016 richard martin. All rights reserved.
//

import UIKit
import Firebase
import FBSDKLoginKit

class LoginView: UIViewController {

    @IBOutlet weak var emailAddressText: TextFieldView!
    @IBOutlet weak var passwordText: TextFieldView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        // check to see if user already signed in
        
        FIRAuth.auth()?.addStateDidChangeListener({ (auth, user) in
            if let user = user {
                // user already signed in
                print("RGM: the user, \(user), is already signed in.")
                self.performSegue(withIdentifier: "goToPostFeed", sender: nil)
            }
        })
    }

    
    // authenticate with Facebook
    
    @IBAction func facebookButtonTapped(_ sender: AnyObject) {
        
        let facebookLogin = FBSDKLoginManager()
        
        facebookLogin.logIn(withReadPermissions: ["email"], from: self) { (result, error) in
            if error != nil {
                // facebook authentication failed
                print("RGM: unable to authenticate with Facebook - \(error)")
            } else if result?.isCancelled == true {
                // user declines access via facebook oermissions
                print("RGM: user declined permission to access via Facebook")
            } else {
                // facebook successful authentication
                print("RGM: user successfully authenticated via Facebook")
                // get credential
                let credential = FIRFacebookAuthProvider.credential(withAccessToken: FBSDKAccessToken.current().tokenString)
                self.firebaseAuth(credential)
            }
        }
    }
    
    // authenticate with Firebase :: used by Facebook login
    
    func firebaseAuth(_ _credential: FIRAuthCredential) {
        
        FIRAuth.auth()?.signIn(with: _credential, completion: { (user, error) in
            if error != nil {
                // firebase authentication failed
                print("RGM: unable to authenticate with Firebase - \(error)")
            } else {
                // firebase authentication successful
                print("RGM: successfully authenticated with Firebase")
            }
        })
    }
    
    // authenticate user with email + password or create new user with email + password

    @IBAction func signinTapped(_ sender: AnyObject) {
        if let email = emailAddressText.text, let password = passwordText.text {
            FIRAuth.auth()?.signIn(withEmail: email, password: password, completion: { (user, error) in
                if error == nil {
                    // firebase authentication successful
                    print("RGM: Email user successfully authenticated with Firebase")
                } else {
                    // user does not exist in firebase :: create new user
                    FIRAuth.auth()?.createUser(withEmail: email, password: password, completion: { (user, error) in
                        if error != nil {
                            // problem creating user
                            print("RGM: problem creating new user from email and password")
                        } else {
                            // new user successfully created in firebase
                            print("RGM: new user from email and password successfully created")
                        }
                    })
                }
            })
        } else {
            // send alert to user (when we go to production
            print("RGM: email address and/or password fields empty")
        }
        
    }
}
