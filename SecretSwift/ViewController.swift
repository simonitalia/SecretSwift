//
//  ViewController.swift
//  SecretSwift
//
//  Created by Simon Italia on 3/21/19.
//  Copyright © 2019 SDI Group Inc. All rights reserved.
//

import LocalAuthentication
import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var secretTextView: UITextView!
    @IBOutlet weak var authenticateButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Set VC title
        title = "Editor is Locked 🔒"
        
        //Subscribe to notifications
        let notificationCenter = NotificationCenter.default
        
        //KB Notification observer methods (x2) to advise when KB changes or hides
        //1
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name:
            UIResponder.keyboardWillHideNotification, object: nil)
        
        
        //2
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name:
            UIResponder.keyboardWillChangeFrameNotification, object: nil)

        //Trigger saving textView text when user hides or switches to multitask mode
        notificationCenter.addObserver(self, selector: #selector(lockSecretText), name: UIApplication.willResignActiveNotification, object: nil)
        
        
    }
    //AdjustForKeyboard() method
    @objc func adjustForKeyboard(notification: Notification) {
        let userInfo = notification.userInfo!
        
        let keyboardScreenEndFrame = (userInfo[UIResponder.keyboardFrameBeginUserInfoKey] as! NSValue).cgRectValue
        
        let keyboardViewEndFrame = view.convert(keyboardScreenEndFrame, from: view.window)
        
        if notification.name == UIResponder.keyboardWillHideNotification {
            secretTextView.contentInset = UIEdgeInsets.zero
            
        } else {
            
            secretTextView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardViewEndFrame.height, right: 0)
        }
        
        secretTextView.scrollIndicatorInsets = secretTextView.contentInset
        
        let selectedRange = secretTextView.selectedRange
        secretTextView.scrollRangeToVisible(selectedRange)
        
    } //End adjustForKeyboard() method

    //Method to securley save textView text to Keychain (triggered when user hides app or switches to multitask mode)
    @objc func lockSecretText() {
        if !secretTextView.isHidden {
            _ = KeychainWrapper.standard.set(secretTextView.text, forKey: "SecureText")
            secretTextView.resignFirstResponder()
                //Dismisses the Keyboard
            
            //Hide textView
            secretTextView.isHidden = true
            title = "Editor is Locked 🔒"
        }
    }
    
    
    //Method to load encrypted "String" from Keychain (if any saved) and display in textView text
    func unlockSecretText() {
        
        //Unhide textView
        secretTextView.isHidden = false
        title = "Editor Unlocked 🔓"
        
        //Set saved text with Key to textView text
        if let text = KeychainWrapper.standard.string(forKey: "SecureText") {
            secretTextView.text = text
        }
    }
    
    //Trigger loading and unlocking text from keychain when tapped, via LocalAuthenication
    @IBAction func authenticateButtonTapped(_ sender: Any) {
        
        //If physical device
        #if !targetEnvironment(simulator)
        
        //Check device supports biometric authentication
        let context = LAContext()
        var error: NSError?
        
        //If device supports biometric authentication
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let authReason = "Authenticate to unlock text editor"
            
            //Request biometric system to start check now, with message advising user why auth is being requested
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: authReason) {
                [unowned self] (success, authenticationError) in
                
                //If user authentication successful
                DispatchQueue.main.async {
                    if success {
                        self.unlockSecretText()
                    
                    //Handle if user authentication fails
                    } else {
                        let ac = UIAlertController(title: "Authentication failed", message: "You could not be verified. Please try again", preferredStyle: .alert)
                        
                        ac.addAction(UIAlertAction(title: "OK", style: .default))
                        self.present(ac, animated: true)
                    }
                }
            }
        
        //Password fallback if device doesn't support biometric authentication
        } else {
            
            //Call password manager
            passwordFallback()

        }
        
        //If simulator
        #else
        if true {
            DispatchQueue.main.async {
                if true {
                    self.unlockSecretText()
                }
            }
        }

        //End compiler directive
        #endif

    }//End authenticateButtonTapped() action method
    
    //If device does not support biometric authentication
    func passwordFallback() {
        
//        //Alert Controller properties
//        let alertTitle: String
//        let alertController: UIAlertController
//        let submitAction: UIAlertAction
        
        //Check if password already exists
        if let _ = KeychainWrapper.standard.string(forKey: "SecurePassword") {
    
            //If password exists
            let alertController = UIAlertController(title: "Enter app password", message: nil, preferredStyle: .alert)
            alertController.addTextField()
            
            let submitAction = UIAlertAction(title: "Submit", style: .default) {
                [unowned self, alertController] (action: UIAlertAction) in
                
                //Check password entered matches saved password
                let text = alertController.textFields![0]
                let password = KeychainWrapper.standard.string(forKey: "SecurePassword")
                
                //If text entered matches saved password, open app
                if text.text! == password {
                    self.unlockSecretText()
                    
                } else {
                    
                    //Exit process
                    return
                }
                
            }
            
            //Present Alert
            alertController.addAction(submitAction)
            present(alertController, animated: true)
            
 
        //If password doesn't exist, create alert to prompt user to create new password
        } else {
            let alertController = UIAlertController(title: "Create app password", message: nil, preferredStyle: .alert)
            alertController.addTextField()
            
            let submitAction = UIAlertAction(title: "Submit", style: .default) {
                [unowned self, alertController] (action: UIAlertAction) in
                let text = alertController.textFields![0]
                
                //Once password set, open app
                self.unlockSecretText()
                
                //Save password to Keychain
                _ = KeychainWrapper.standard.set(text.text!, forKey: "SecurePassword")
            }
            
            //Present Alert
            alertController.addAction(submitAction)
            present(alertController, animated: true)
            
        }

    } //End passswordFallback() method
    
}
