//
//  Auxiliar.swift
//  DemoShop-PayPal
//
//  Copyright © 2016 Nissi Vieira Miranda. All rights reserved.
//

import Foundation

class Auxiliar
{
    
    //-------------------------------------------------------------------------//
    // MARK: MBProgressHUD
    //-------------------------------------------------------------------------//
    
    static func showLoadingHUDWithText(labelText : String, forView view : UIView)
    {
        dispatch_async(dispatch_get_main_queue())
        {
            let progressHud = MBProgressHUD.showHUDAddedTo(view, animated: true)
                progressHud.labelText = labelText
        }
    }
    
    static func hideLoadingHUDInView(view : UIView)
    {
        dispatch_async(dispatch_get_main_queue())
        {
            MBProgressHUD.hideAllHUDsForView(view, animated: true)
        }
    }
    
    //-------------------------------------------------------------------------//
    // MARK: "Ok" Alert Controller
    //-------------------------------------------------------------------------//
    
    static func presentAlertControllerWithTitle(title : String,
                            andMessage message : String,
                          forViewController vc : UIViewController)
    {
        let alert = UIAlertController(title: title,
                                    message: message,
                             preferredStyle: UIAlertControllerStyle.Alert)
        
        let alertAction = UIAlertAction(title: "Ok",
                                        style: UIAlertActionStyle.Default,
                                      handler: nil)
        
        alert.addAction(alertAction)
        
        dispatch_async(dispatch_get_main_queue())
        {
            vc.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    //-------------------------------------------------------------------------//
    // MARK: Format price for Pay Pal
    //-------------------------------------------------------------------------//
    
    static func formatPrice(price: CGFloat) -> NSDecimalNumber
    {
        let roundingBehavior = NSDecimalNumberHandler(roundingMode: NSRoundingMode.RoundUp,
            scale: 2,
            raiseOnExactness: false, raiseOnOverflow: false, raiseOnUnderflow: false,
            raiseOnDivideByZero: false)
        
        var decimal = NSDecimalNumber(float: Float(price))
            decimal = decimal.decimalNumberByRoundingAccordingToBehavior(roundingBehavior)
        
        return decimal
    }
}