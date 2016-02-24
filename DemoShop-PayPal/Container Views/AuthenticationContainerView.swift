//
//  AuthenticationContainerView.swift
//  DemoShop-PayPal
//
//  Copyright © 2016 Nissi Vieira Miranda. All rights reserved.
//

import UIKit

class AuthenticationContainerView: UIViewController, UIGestureRecognizerDelegate, UITextFieldDelegate
{
    @IBOutlet weak var tapView: UIView!
    @IBOutlet weak var nameTxtField: UITextField!
    @IBOutlet weak var passwordTxtField: UITextField!
    @IBOutlet weak var emailTxtField: UITextField!
    
    @IBOutlet weak var shopName: UILabel!
    @IBOutlet weak var headerHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var dividerOneTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var dividerTwoTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var dividerThreeTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var signUpButton: UIButton!
    @IBOutlet weak var signInButton: UIButton!
    
    @IBOutlet weak var containerTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var containerHeightConstraint: NSLayoutConstraint!
    
    var tappedTextField : UITextField?
    var multiplier: CGFloat = 1
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action:Selector("handleTap:"))
            tapRecognizer.delegate = self
        tapView.addGestureRecognizer(tapRecognizer)
        
        if Device.IS_IPHONE_4 || Device.IS_IPHONE_6 || Device.IS_IPHONE_6_PLUS
        {
            containerHeightConstraint.constant = self.view.frame.size.height
        }

        if Device.IS_IPHONE_6
        {
            multiplier = Constants.multiplier6
            adjustForBiggerScreen()
        }
        else if Device.IS_IPHONE_6_PLUS
        {
            multiplier = Constants.multiplier6plus
            adjustForBiggerScreen()
        }
    }
    
    //-------------------------------------------------------------------------//
    // MARK: Firebase Sign Up
    //-------------------------------------------------------------------------//
    
    var signingUp = false
    
    @IBAction func signUpButtonTapped(sender: UIButton)
    {
        removeKeyboard()
        
        guard Reachability.connectedToNetwork() else
        {
            Auxiliar.presentAlertControllerWithTitle("No Internet Connection",
                andMessage: "Make sure your device is connected to the internet.",
                forViewController: self)
            return
        }
        
        let name = nameTxtField.text!
        let email = emailTxtField.text!
        let password = passwordTxtField.text!
        
        if name.characters.count > 0 &&
            email.characters.count > 0 &&
            password.characters.count > 0
        {
            Auxiliar.showLoadingHUDWithText("Signing up...", forView: self.view)
            signUpWithFirebase(name, email: email, password: password)
        }
        else
        {
            Auxiliar.presentAlertControllerWithTitle("Error",
                andMessage: "Please fill in all fields", forViewController: self)
        }
    }
    
    func signUpWithFirebase(name: String, email: String, password: String)
    {
        // Create user account:
        
        let ref = Firebase(url: Constants.baseURL)
            ref.createUser(email, password: password,
                withValueCompletionBlock: {
                    
                    [unowned self](error, result) in
                
                    guard error == nil else
                    {
                        Auxiliar.hideLoadingHUDInView(self.view)
                        
                        print("Error creating user account in Firebase\n")
                        print("Error code: \(error!.code)\n")
                        print("Error code: \(error!.localizedDescription)")
                        
                        let errorInfo = self.getAuthenticationErrorInfo(error!.code)
                        
                        Auxiliar.presentAlertControllerWithTitle(errorInfo[0],
                            andMessage: errorInfo[1], forViewController: self)
                        
                        return
                    }
                    
                    self.signingUp = true
                    
                    self.signInWithFirebase(name, email: email, password: password) // Logging the user in
                })
    }
    
    //-------------------------------------------------------------------------//
    // MARK: Firebase Sign In
    //-------------------------------------------------------------------------//
    
    @IBAction func signInButtonTapped(sender: UIButton)
    {
        removeKeyboard()
        
        guard Reachability.connectedToNetwork() else
        {
            Auxiliar.presentAlertControllerWithTitle("No Internet Connection",
                andMessage: "Make sure your device is connected to the internet.",
                forViewController: self)
            return
        }
        
        let email = emailTxtField.text!
        let password = passwordTxtField.text!
        
        if email.characters.count > 0 &&
            password.characters.count > 0
        {
            Auxiliar.showLoadingHUDWithText("Signing in...", forView: self.view)
            signInWithFirebase("", email: email, password: password)
        }
        else
        {
            Auxiliar.presentAlertControllerWithTitle("Error",
                andMessage: "Please insert username and password", forViewController: self)
        }
    }
    
    func signInWithFirebase(name: String, email: String, password: String)
    {
        let ref = Firebase(url: Constants.baseURL)
            ref.authUser(email, password: password,
                withCompletionBlock: {
                    
                    [unowned self](error, authData) in
                
                    guard error == nil else
                    {
                        print("Error logging in the user in Firebase\n")
                        print("Error code: \(error!.code)\n")
                        print("Error code: \(error!.localizedDescription)")
                        
                        let errorInfo = self.getAuthenticationErrorInfo(error!.code)
                        
                        Auxiliar.presentAlertControllerWithTitle(errorInfo[0],
                            andMessage: errorInfo[1], forViewController: self)
                        
                        return
                    }
                    
                    if self.signingUp
                    {
                        self.signingUp = false
                        self.saveNewClient(name, email: email)
                        Auxiliar.hideLoadingHUDInView(self.view)
                    }
                    else
                    {
                        self.retrieveCurrentUser(email)
                    }
                    
                    self.nameTxtField.text = ""
                    self.passwordTxtField.text = ""
                    self.emailTxtField.text = ""
                    
                    NSNotificationCenter.defaultCenter().postNotificationName("SessionStarted", object: nil)
                })
    }
    
    //-------------------------------------------------------------------------//
    // MARK: Save new client
    //-------------------------------------------------------------------------//
    
    func saveNewClient(name: String, email: String)
    {
        let ref = Firebase(url: Constants.baseURL + "Clients")
        let newClientRef = ref.childByAutoId()
        
        var clientId = "\(newClientRef)"
            clientId = clientId.stringByReplacingOccurrencesOfString(Constants.baseURL + "Clients/", withString: "")
        
        let newClient = ["clientId": clientId, "clientName": name, "clientEmail": email]
        
            newClientRef.setValue(newClient)
        
        Auxiliar.currentUserId = newClient["clientId"]!
    }
    
    //-------------------------------------------------------------------------//
    // MARK: Retrieve current user
    //-------------------------------------------------------------------------//
    
    func retrieveCurrentUser(email: String)
    {
        let ref = Firebase(url: Constants.baseURL + "Clients")
        
        ref.observeEventType(.Value, withBlock:
            {
                (snapshot) in
                
                Auxiliar.hideLoadingHUDInView(self.view)
                
                if let response = snapshot.value as? [NSObject : AnyObject]
                {
                    let keys = response.keys
                    
                    for key in keys
                    {
                        let item = response[key] as! [String : String]
                        let responseItemEmail = item["clientEmail"]
                        
                        if responseItemEmail == email
                        {
                            let responseItemId = item["clientId"]!
                            Auxiliar.currentUserId = responseItemId
                            
                            break
                        }
                    }
                }
            })
    }
    
    //-------------------------------------------------------------------------//
    // MARK: Error Info
    //-------------------------------------------------------------------------//
    
    func getAuthenticationErrorInfo(errorCode: Int) -> [String]
    {
        var errorInfo = [String]()
        
        switch errorCode
        {
            case -5:
                errorInfo.append("INVALID EMAIL")
                errorInfo.append("The specified email address is invalid.")
            
            case -6:
                errorInfo.append("INCORRECT PASSWORD")
                errorInfo.append("The specified password is incorrect.")
            
            case -8:
                errorInfo.append("INVALID USER")
                errorInfo.append("The specified user does not exist.")
            
            case -9:
                errorInfo.append("EMAIL TAKEN")
                errorInfo.append("The specified email address is already in use.")
            
            default:
                errorInfo.append("UNKNOWN ERROR")
                errorInfo.append("An error occurred while authenticating, please check your authentication data and try again.")
        }
        
        return errorInfo
    }
    
    //-------------------------------------------------------------------------//
    // MARK: UITextFieldDelegate
    //-------------------------------------------------------------------------//
    
    func textFieldDidBeginEditing(textField: UITextField)
    {
        tappedTextField = textField
        
        let textFieldY = tappedTextField!.frame.origin.y
        let textFieldHeight = tappedTextField!.frame.size.height
        let total = textFieldY + textFieldHeight
        
        if total > (self.view.frame.size.height/2)
        {
            let difference = total - (self.view.frame.size.height/2)
            var newConstraint = containerTopConstraint.constant - difference
            
            if textField.tag == 13 // Email
            {
                newConstraint -= 30
            }
            
            animateConstraint(containerTopConstraint, toValue: newConstraint)
        }
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool
    {
        removeKeyboard()
        
        return true
    }
    
    //-------------------------------------------------------------------------//
    // MARK: Tap gesture recognizer
    //-------------------------------------------------------------------------//
    
    func handleTap(recognizer : UITapGestureRecognizer)
    {
        removeKeyboard()
    }
    
    //-------------------------------------------------------------------------//
    // MARK: Remove keyboard
    //-------------------------------------------------------------------------//
    
    func removeKeyboard()
    {
        if tappedTextField != nil
        {
            tappedTextField!.resignFirstResponder()
            tappedTextField = nil
            
            if containerTopConstraint.constant != 0
            {
                animateConstraint(containerTopConstraint, toValue: 0)
            }
        }
    }
    
    //-------------------------------------------------------------------------//
    // MARK: Animations
    //-------------------------------------------------------------------------//
    
    func animateConstraint(constraint : NSLayoutConstraint, toValue value : CGFloat)
    {
        UIView.animateWithDuration(0.5, delay: 0.0, options: .CurveEaseOut,
            animations:
            {
                constraint.constant = value
                
                self.view.layoutIfNeeded()
            },
            completion:
            {
                (finished: Bool) in
            })
    }
    
    //-------------------------------------------------------------------------//
    // MARK: Ajust for bigger screen
    //-------------------------------------------------------------------------//
    
    func adjustForBiggerScreen()
    {
        for constraint in shopName.constraints
        {
            constraint.constant *= multiplier
        }
        
        for constraint in nameTxtField.constraints
        {
            constraint.constant *= multiplier
        }
        
        for constraint in passwordTxtField.constraints
        {
            constraint.constant *= multiplier
        }
        
        for constraint in emailTxtField.constraints
        {
            constraint.constant *= multiplier
        }
        
        for constraint in signUpButton.constraints
        {
            constraint.constant *= multiplier
        }
        
        for constraint in signInButton.constraints
        {
            constraint.constant *= multiplier
        }
        
        headerHeightConstraint.constant *= multiplier
        dividerOneTopConstraint.constant *= multiplier
        dividerTwoTopConstraint.constant *= multiplier
        dividerThreeTopConstraint.constant *= multiplier
        
        var fontSize = 25.0 * multiplier
        shopName.font =  UIFont(name: "HelveticaNeue-Light", size: fontSize)
        
        fontSize = 17.0 * multiplier
        nameTxtField.font =  UIFont(name: "HelveticaNeue-Light", size: fontSize)
        passwordTxtField.font =  UIFont(name: "HelveticaNeue-Light", size: fontSize)
        emailTxtField.font =  UIFont(name: "HelveticaNeue-Light", size: fontSize)
        signUpButton.titleLabel!.font =  UIFont(name: "HelveticaNeue-Light", size: fontSize)
        signInButton.titleLabel!.font =  UIFont(name: "HelveticaNeue-Light", size: fontSize)
    }
    
    //-------------------------------------------------------------------------//
    // MARK: Memory Warning
    //-------------------------------------------------------------------------//

    override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
