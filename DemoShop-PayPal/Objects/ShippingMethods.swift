//
//  ShippingMethods.swift
//  DemoShop-PayPal
//
//  Copyright © 2016 Nissi Vieira Miranda. All rights reserved.
//

import Foundation

class ShippingMethods
{
    private var freeShipping: CGFloat = 0
    private var pac: CGFloat = 0
    private var sedex: CGFloat = 0
    
    private var shippingOptions = [[String : AnyObject]]()
    
    init()
    {
        freeShipping = 0.00
        pac = 20.00
        sedex = 45.00
        
        shippingOptions = [
            ["description": "Free Shipping", "detail": "10 to 15 business days",
                                             "amount": freeShipping, "identifier": "free"],
            ["description": "PAC", "detail": "5 to 10 business days",
                                   "amount": pac, "identifier": "pac"],
            ["description": "SEDEX", "detail": "2 to 5 business days",
                                     "amount": sedex, "identifier": "sedex"]
        ]
    }
    
    func availableShippingMethods() -> [ShippingMethod]
    {
        var methods = [ShippingMethod]()
        
        for option in shippingOptions
        {
            let shippingMethod = ShippingMethod()
                shippingMethod.description = option["description"] as! String
                shippingMethod.detail = option["detail"] as! String
                shippingMethod.amount = option["amount"] as! CGFloat
                shippingMethod.identifier = option["identifier"] as! String
            
            methods.append(shippingMethod)
        }
        
        return methods
    }
    
    // In a real app, there'd be functions for calculate shipping method's values
    // according to costumer's zip code, shopping cart items weight, possible packing 
    // measurements etc
}

class ShippingMethod
{
    var description = ""
    var detail = ""
    var amount: CGFloat = 0
    var identifier = ""
}