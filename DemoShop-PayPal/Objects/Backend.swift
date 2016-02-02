//
//  Backend.swift
//  DemoShop-PayPal
//
//  Created by Nissi Vieira Miranda on 1/27/16.
//  Copyright © 2016 Nissi Vieira Miranda. All rights reserved.
//

import Foundation

class Backend
{
    static func verifyPayment(postDic: [String : AnyObject], completion:((status : String, message : String) -> Void))
    {
        let url = NSURL(string: "http://localhost/DemoShopPayPal-ServerSide/VerifyPayment.php")!
        
        let request = NSMutableURLRequest(URL: url)
            request.HTTPMethod = "POST"
        
        do
        {
            request.HTTPBody = try NSJSONSerialization.dataWithJSONObject(postDic, options: [])
        }
        catch
        {
            completion(status: "Failure", message: "Error while processing payment, please try again.")
            return
        }
        
        let configuration = NSURLSessionConfiguration.ephemeralSessionConfiguration()
        let session = NSURLSession(configuration: configuration)
        
        let task = session.dataTaskWithRequest(request) {
            
            (data, response, error) -> Void in
            
            let errorMessage = "Error while processing payment, please try again."
            
            guard error == nil else
            {
                print("Error: \(error)")
                completion(status: "Failure", message: errorMessage)
                return
            }
            
            guard data != nil else
            {
                completion(status: "Failure", message: errorMessage)
                return
            }
            
            guard let response = response as? NSHTTPURLResponse else
            {
                completion(status: "Failure", message: errorMessage)
                return
            }
            
            guard response.statusCode == 200 else
            {
                print("Not ok response = \(response.description)")
                completion(status: "Failure", message: errorMessage)
                return
            }
            
            //let backendResponse = NSString(data: data!, encoding: NSUTF8StringEncoding)
            //print("backendResponse = \(backendResponse)")
            
            do
            {
                let jSon = try NSJSONSerialization.JSONObjectWithData(data!, options: .AllowFragments) as! [String : AnyObject]
                
                let status = jSon["status"] as! String
                let message = jSon["message"] as! String
                
                completion(status: status, message: message)
            }
            catch let error as NSError
            {
                print("Error (try/catch): \(error)")
                completion(status: "Failure", message: errorMessage)
                return
            }
        }
        
        task.resume()
    }
}