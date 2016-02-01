//
//  ShoppingCart_VC.swift
//  DemoShop-PayPal
//
//  Copyright © 2016 Nissi Vieira Miranda. All rights reserved.
//

import UIKit

protocol ShoppingCart_VC_Delegate: class
{
    func shoppingCartItemsListChanged(cartItems: [ShoppingCartItem])
}

class ShoppingCart_VC: UIViewController, UITableViewDataSource, UITableViewDelegate, ShoppingCartItemCellDelegate, PayPalPaymentDelegate
{
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var valueToPayLabel: UILabel!
    @IBOutlet weak var freeShippingBlueRect: UIView!
    @IBOutlet weak var pacBlueRect: UIView!
    @IBOutlet weak var sedexBlueRect: UIView!
    
    @IBOutlet weak var shopName: UILabel!
    @IBOutlet weak var shoppingCartImage: UIImageView!
    @IBOutlet weak var headerHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var tableViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var optionsSatckViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var valueToPayViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var buttonsSatckViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var shippingOptionsStackView: UIStackView!
    @IBOutlet weak var checkoutButton: UIButton!
    @IBOutlet weak var keepShoppingButton: UIButton!
    
    weak var delegate: ShoppingCart_VC_Delegate?
    
    let auxiliar = Auxiliar()
    let backend = Backend()
    let shippingMethods = ShippingMethods()
    var multiplier: CGFloat = 1
    
    var payPalConfiguration: PayPalConfiguration!
    
    // Received from Products_VC:
    var shoppingCartItems: [ShoppingCartItem]!
    
    var valueToPay: CGFloat = 0
    var shippingValue: CGFloat = 0
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        payPalConfiguration = PayPalConfiguration()
        payPalConfiguration.acceptCreditCards = false
        payPalConfiguration.payPalShippingAddressOption = .PayPal

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
        else
        {
            calculateTableViewHeightConstraint()
        }
        
        valueToPay = totalPurchaseItemsValue()
        let value: NSString = NSString(format: "%.02f", valueToPay)
        valueToPayLabel.text = "Total:  $\(value)"
    }
    
    override func viewWillAppear(animated: Bool)
    {
        super.viewWillAppear(true)
        
        PayPalMobile.preconnectWithEnvironment(PayPalEnvironmentSandbox)
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle
    {
        return UIStatusBarStyle.LightContent
    }
    
    //-------------------------------------------------------------------------//
    // MARK: IBActions
    //-------------------------------------------------------------------------//
    
    @IBAction func shippingMethodButtonTapped(sender: UIButton)
    {
        let idx = sender.tag - 10
        resetShippingMethod(idx)
    }
    
    @IBAction func checkoutButtonTapped(sender: UIButton)
    {
        let payment = PayPalPayment()
            payment.items = createPayPalItems()
            payment.paymentDetails = getPaymentDetails()
            payment.amount = Auxiliar.formatPrice(valueToPay)
            payment.currencyCode = "BRL"
            payment.shortDescription = "Purchase of fashion items"
            payment.intent = .Sale
            payment.shippingAddress = nil
        
        if let paymentViewController = PayPalPaymentViewController(payment: payment,
            configuration: payPalConfiguration, delegate: self)
        {
            presentViewController(paymentViewController, animated: true, completion: nil)
        }
    }
    
    @IBAction func keepShoppingButtonTapped(sender: UIButton)
    {
        navigationController!.popViewControllerAnimated(true)
    }
    
    //-------------------------------------------------------------------------//
    // MARK: PayPal payment components
    //-------------------------------------------------------------------------//
    
    func createPayPalItems() -> [PayPalItem]
    {
        var payPalItems = [PayPalItem]()
        
        for cartItem in shoppingCartItems
        {
            let payPalItem = PayPalItem(name: cartItem.itemForSale.itemName,
                withQuantity: UInt(cartItem.amount),
                withPrice: Auxiliar.formatPrice(cartItem.itemForSale.itemPrice),
                withCurrency: "BRL",
                withSku: cartItem.itemForSale.itemId)
            
            payPalItems.append(payPalItem)
        }
        
        return payPalItems
    }
    
    func getPaymentDetails() -> PayPalPaymentDetails
    {
        let subTotal = totalPurchaseItemsValue()
        
        return PayPalPaymentDetails(subtotal: Auxiliar.formatPrice(subTotal),
            withShipping: Auxiliar.formatPrice(shippingValue),
            withTax: Auxiliar.formatPrice(0))
    }
    
    //-------------------------------------------------------------------------//
    // MARK: UITableViewDataSource
    //-------------------------------------------------------------------------//
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return shoppingCartItems.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCellWithIdentifier("ShoppingCartItemCell",
                                forIndexPath: indexPath) as! ShoppingCartItemCell
        
        cell.delegate = self
        cell.setupCellWithItem(shoppingCartItems[indexPath.row])
        
        return cell
    }
    
    //-------------------------------------------------------------------------//
    // MARK: UITableViewDelegate
    //-------------------------------------------------------------------------//
    
    func tableView(tableView: UITableView,
        heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat
    {
        var starterCellHeight: CGFloat = 110
        
        if Device.IS_IPHONE_6
        {
            starterCellHeight = 100
        }
        
        if Device.IS_IPHONE_6_PLUS
        {
            starterCellHeight = 90
        }
        
        return starterCellHeight * multiplier
    }
    
    //-------------------------------------------------------------------------//
    // MARK: ShoppingCartItemCellDelegate
    //-------------------------------------------------------------------------//
    
    func amountForItemChanged(clickedItemId: String, newAmount: Int)
    {
        var totalPurchase = totalPurchaseItemsValue()
        let shippingValue = valueToPay - totalPurchase
        
        let idx = findOutCartItemIndex(clickedItemId)
        
        let item = shoppingCartItems[idx]
            item.amount = newAmount
        
        shoppingCartItems[idx] = item
        
        totalPurchase = totalPurchaseItemsValue()
        valueToPay = totalPurchase + shippingValue
        let value: NSString = NSString(format: "%.02f", valueToPay)
        valueToPayLabel.text = "Total:  $\(value)"
        
        delegate!.shoppingCartItemsListChanged(shoppingCartItems)
    }
    
    func removeItem(clickedItemId: String)
    {
        var totalPurchase = totalPurchaseItemsValue()
        let shippingValue = valueToPay - totalPurchase
        
        let idx = findOutCartItemIndex(clickedItemId)
        
        shoppingCartItems.removeAtIndex(idx)
        
        delegate!.shoppingCartItemsListChanged(shoppingCartItems)
        
        if shoppingCartItems.count == 0
        {
            navigationController!.popViewControllerAnimated(true)
        }
        else
        {
            tableView.beginUpdates()
            let indexPaths = [NSIndexPath(forRow: idx, inSection: 0)]
            tableView.deleteRowsAtIndexPaths(indexPaths, withRowAnimation: .Left)
            tableView.endUpdates()
            
            totalPurchase = totalPurchaseItemsValue()
            valueToPay = totalPurchase + shippingValue
            let value: NSString = NSString(format: "%.02f", valueToPay)
            valueToPayLabel.text = "Total:  $\(value)"
            
            calculateTableViewHeightConstraint()
        }
    }
    
    //-------------------------------------------------------------------------//
    // MARK: PayPalPaymentDelegate
    //-------------------------------------------------------------------------//
    
    func payPalPaymentViewController(paymentViewController: PayPalPaymentViewController,
        didCompletePayment completedPayment: PayPalPayment)
    {
        dismissViewControllerAnimated(true, completion: nil)
        verifyPayment(completedPayment)
    }
    
    func payPalPaymentDidCancel(paymentViewController: PayPalPaymentViewController)
    {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    //-------------------------------------------------------------------------//
    // MARK: Verify payment in backend
    //-------------------------------------------------------------------------//
    
    func verifyPayment(completedPayment: PayPalPayment)
    {
        let response = completedPayment.confirmation["response"] as! [String : String]
        let state = response["state"]
        
        if state == "approved"
        {
            let paymentId = response["id"]
            let purchaseAmount = CGFloat(completedPayment.amount)
            let purchaseCurrency = completedPayment.currencyCode
            
            let postDic: [String : AnyObject] = ["paymentId" : paymentId!,
                                            "purchaseAmount" : purchaseAmount,
                                          "purchaseCurrency" : purchaseCurrency]
            
            Backend.verifyPayment(postDic, completion: {
                
                [unowned self](status, message) -> Void in
                
                if status == "Success"
                {
                    self.promptUserForSuccessfulPayment(status, message: message)
                }
                else
                {
                    Auxiliar.presentAlertControllerWithTitle("Error",
                        andMessage: "An error occurred with the payment.",
                        forViewController: self)
                }
            })
        }
        else
        {
            Auxiliar.presentAlertControllerWithTitle("Error",
                andMessage: "Your payment was not approved.",
                forViewController: self)
        }
    }
    
    //-------------------------------------------------------------------------//
    // MARK: Prompt user for successful payment
    //-------------------------------------------------------------------------//
    
    func promptUserForSuccessfulPayment(title: String, message: String)
    {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        
        let saveAction = UIAlertAction(title: "Ok", style: .Default)
        {
            [unowned self](action: UIAlertAction!) -> Void in
            
            self.shoppingCartItems.removeAll()
            self.delegate!.shoppingCartItemsListChanged(self.shoppingCartItems)
            self.navigationController!.popToRootViewControllerAnimated(true)
        }
        
        alert.addAction(saveAction)
        
        dispatch_async(dispatch_get_main_queue())
        {
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    //-------------------------------------------------------------------------//
    // MARK: Auxiliar functions
    //-------------------------------------------------------------------------//
    
    func findOutCartItemIndex(clickedItemId: String) -> Int
    {
        var idx = 0
        
        for (index, item) in shoppingCartItems.enumerate()
        {
            if item.itemForSale.itemId == clickedItemId
            {
                idx = index
                break
            }
        }
        
        return idx
    }
    
    func resetShippingMethod(idx: Int)
    {
        let totalPurchase = totalPurchaseItemsValue()
        let methods = shippingMethods.availableShippingMethods()
        let method = methods[idx]
        
        shippingValue = method.amount
        valueToPay = totalPurchase + shippingValue
        let value: NSString = NSString(format: "%.02f", valueToPay)
        valueToPayLabel.text = "Total:  $\(value)"
        
        // Adjust UI:
        
        freeShippingBlueRect.alpha = 0.4
        pacBlueRect.alpha = 0.4
        sedexBlueRect.alpha = 0.4
        
        switch idx
        {
            case 0:
                freeShippingBlueRect.alpha = 1
            case 1:
                pacBlueRect.alpha = 1
            case 2:
                sedexBlueRect.alpha = 1
            default:
                print("Unknown")
        }
    }
    
    func totalPurchaseItemsValue() -> CGFloat
    {
        var totalValue: CGFloat = 0
        
        for item in shoppingCartItems
        {
            let unityPrice = item.itemForSale.itemPrice
            let total = unityPrice * CGFloat(item.amount)
            totalValue += total
        }
        
        return totalValue
    }
    
    func getChoosenShippingMethod() -> ShippingMethod
    {
        let methods = shippingMethods.availableShippingMethods()
        var idx = 0
        
        if pacBlueRect.alpha == 1
        {
            idx = 1
        }
        else if sedexBlueRect.alpha == 1
        {
            idx = 2
        }
        
        return methods[idx]
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
        
        for constraint in shoppingCartImage.constraints
        {
            constraint.constant *= multiplier
        }
        
        for subview in shippingOptionsStackView.subviews
        {
            for (index, subV) in subview.subviews.enumerate()
            {
                if index > 0
                {
                    for constraint in subV.constraints
                    {
                        constraint.constant *= multiplier
                    }
                    
                    if index == 1
                    {
                        let fontSize = 14 * multiplier
                        let label = subV as! UILabel
                            label.font =  UIFont(name: "HelveticaNeue", size: fontSize)
                    }
                    
                    if index == 2
                    {
                        let fontSize = 12 * multiplier
                        let label = subV as! UILabel
                            label.font =  UIFont(name: "HelveticaNeue", size: fontSize)
                    }
                    
                    if index == 3
                    {
                        let fontSize = 15 * multiplier
                        let label = subV as! UILabel
                            label.font =  UIFont(name: "HelveticaNeue", size: fontSize)
                    }
                }
            }
        }
        
        for constraint in valueToPayLabel.constraints
        {
            constraint.constant *= multiplier
        }
        
        headerHeightConstraint.constant *= multiplier
        optionsSatckViewHeightConstraint.constant *= multiplier
        valueToPayViewHeightConstraint.constant *= multiplier
        buttonsSatckViewHeightConstraint.constant *= multiplier
        
        calculateTableViewHeightConstraint()
        
        var fontSize = 25.0 * multiplier
        shopName.font =  UIFont(name: "HelveticaNeue-Light", size: fontSize)
        
        fontSize = 17.0 * multiplier
        checkoutButton.titleLabel!.font =  UIFont(name: "HelveticaNeue-Light", size: fontSize)
        keepShoppingButton.titleLabel!.font =  UIFont(name: "HelveticaNeue-Light", size: fontSize)
        
        fontSize = 15.0 * multiplier
        valueToPayLabel.font =  UIFont(name: "HelveticaNeue", size: fontSize)
    }
    
    //-------------------------------------------------------------------------//
    // MARK: Calculate TableView Height Constraint
    //-------------------------------------------------------------------------//
    
    func calculateTableViewHeightConstraint()
    {
        let space = self.view.frame.size.height - (headerHeightConstraint.constant +
                                         optionsSatckViewHeightConstraint.constant +
                                           valueToPayViewHeightConstraint.constant +
                                         buttonsSatckViewHeightConstraint.constant)
        
        var starterCellHeight: CGFloat = 110
        
        if Device.IS_IPHONE_6
        {
            starterCellHeight = 100
        }
        
        if Device.IS_IPHONE_6_PLUS
        {
            starterCellHeight = 90
        }
        
        let cellsTotalHeight = (starterCellHeight * multiplier) * CGFloat(shoppingCartItems.count)
        
        let tvHeight = cellsTotalHeight < space ? cellsTotalHeight : space
        
        tableViewHeightConstraint.constant = tvHeight
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
