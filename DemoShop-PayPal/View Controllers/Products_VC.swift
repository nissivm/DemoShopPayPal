//
//  Products_VC.swift
//  DemoShop-PayPal
//
//  Copyright © 2016 Nissi Vieira Miranda. All rights reserved.
//

import UIKit

class Products_VC: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIScrollViewDelegate, ItemForSaleCellDelegate, ShoppingCart_VC_Delegate
{
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var shoppingCartButton: UIButton!
    @IBOutlet weak var authenticationContainerView: UIView!
    
    @IBOutlet weak var shopName: UILabel!
    @IBOutlet weak var headerHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var shoppingCartButtonHeightConstraint: NSLayoutConstraint!
    
    var allItemsForSale = [ItemForSale]()
    var itemsForSale = [ItemForSale]()
    var shoppingCartItems = [ShoppingCartItem]()
    var multiplier: CGFloat = 1
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "sessionStarted",
            name: "SessionStarted", object: nil)

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
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle
    {
        return UIStatusBarStyle.LightContent
    }
    
    deinit
    {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    //-------------------------------------------------------------------------//
    // MARK: Notifications
    //-------------------------------------------------------------------------//
    
    func sessionStarted()
    {
        authenticationContainerView.hidden = true
        retrieveProducts()
    }
    
    //-------------------------------------------------------------------------//
    // MARK: IBActions
    //-------------------------------------------------------------------------//
    
    @IBAction func shoppingCartButtonTapped(sender: UIButton)
    {
        if shoppingCartButton.enabled
        {
            performSegueWithIdentifier("ToShoppingCart", sender: self)
        }
    }
    
    //-------------------------------------------------------------------------//
    // MARK: Retrieve products
    //-------------------------------------------------------------------------//
    
    var minimum = 0
    var maximum = 5
    
    func retrieveProducts()
    {
        Auxiliar.showLoadingHUDWithText("Retrieving products...", forView: self.view)
        
        guard Reachability.connectedToNetwork() else
        {
            Auxiliar.hideLoadingHUDInView(self.view)
            return
        }
        
        let ref = Firebase(url: Constants.baseURL + "ItemsForSale")
        
        ref.observeEventType(.Value, withBlock:
            {
                [unowned self](snapshot) in
                
                if let response = snapshot.value as? [[NSObject : AnyObject]]
                {
                    for responseItem in response
                    {
                        let item = ItemForSale()
                            item.position = responseItem["position"] as! Int
                            item.itemId = responseItem["itemId"] as! String
                            item.itemName = responseItem["itemName"] as! String
                            item.itemPrice = responseItem["itemPrice"] as! CGFloat
                            item.imageAddr = responseItem["imageAddr"] as! String
                        
                        self.allItemsForSale.append(item)
                    }
                    
                    self.allItemsForSale.sortInPlace
                        {
                            item1, item2 in
                            return item1.position < item2.position
                        }
                    
                    var firstItemsForSale = [ItemForSale]()
                    for (index, item) in self.allItemsForSale.enumerate()
                    {
                        firstItemsForSale.append(item)
                        
                        if index == 5
                        {
                            break
                        }
                    }
                    
                    self.incorporateItems(firstItemsForSale)
                }
            })
    }
    
    //-------------------------------------------------------------------------//
    // MARK: UIScrollViewDelegate
    //-------------------------------------------------------------------------//
    
    var hasMoreToShow = true
    
    func scrollViewDidScroll(scrollView: UIScrollView)
    {
        if collectionView.contentOffset.y >= (collectionView.contentSize.height - collectionView.bounds.size.height)
        {
            if hasMoreToShow
            {
                hasMoreToShow = false
                
                Auxiliar.showLoadingHUDWithText("Retrieving products...", forView: self.view)
                
                var counter = 6
                var newItemsForSale = [ItemForSale]()
                while counter <= 11
                {
                    newItemsForSale.append(allItemsForSale[counter])
                    counter++
                }
                
                incorporateItems(newItemsForSale)
            }
        }
    }
    
    //-------------------------------------------------------------------------//
    // MARK: Incorporate new search items
    //-------------------------------------------------------------------------//
    
    func incorporateItems(items : [ItemForSale])
    {
        var indexPath : NSIndexPath = NSIndexPath(forItem: 0, inSection: 0)
        var counter = collectionView.numberOfItemsInSection(0)
        var newItems = [NSIndexPath]()
        
        for item in items
        {
            indexPath = NSIndexPath(forItem: counter, inSection: 0)
            newItems.append(indexPath)
            
            let imageURL : NSURL = NSURL(string: item.imageAddr)!
            item.itemImage = UIImage(data: NSData(contentsOfURL: imageURL)!)
            
            itemsForSale.append(item)
            
            counter++
        }
        
        collectionView.performBatchUpdates({
            
                [unowned self]() -> Void in
            
                self.collectionView.insertItemsAtIndexPaths(newItems)
            }){
                completed in
                
                Auxiliar.hideLoadingHUDInView(self.view)
            }
    }
    
    //-------------------------------------------------------------------------//
    // MARK: UICollectionViewDataSource
    //-------------------------------------------------------------------------//
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    {
        return itemsForSale.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell
    {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("ItemForSaleCell",
                                                            forIndexPath: indexPath) as! ItemForSaleCell
        
        cell.index = indexPath.item
        cell.delegate = self
        cell.setupCellWithItem(itemsForSale[indexPath.item])
        
        return cell
    }
    
    //-------------------------------------------------------------------------//
    // MARK: UICollectionViewDelegateFlowLayout
    //-------------------------------------------------------------------------//
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize
    {
        let cellWidth = self.view.frame.size.width/2
        return CGSizeMake(cellWidth, 190 * multiplier)
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout,
        minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat
    {
        return 0
    }
    
    //-------------------------------------------------------------------------//
    // MARK: ItemForSaleCellDelegate
    //-------------------------------------------------------------------------//
    
    func addThisItemToShoppingCart(clickedItemIndex: Int)
    {
        let item = itemsForSale[clickedItemIndex]
        var found = false
        var message = "\(item.itemName) was added to shopping cart."
        
        if shoppingCartItems.count > 0
        {
            for (index, cartItem) in shoppingCartItems.enumerate()
            {
                if cartItem.itemForSale.itemId == item.itemId
                {
                    found = true
                    cartItem.amount++
                    shoppingCartItems[index] = cartItem
                    
                    let lastLetterIdx = item.itemName.characters.count - 1
                    let lastLetter = NSString(string: item.itemName).substringFromIndex(lastLetterIdx)
                    
                    if lastLetter != "s"
                    {
                        message = "You have \(cartItem.amount) \(item.itemName)s in your shopping cart."
                    }
                    else
                    {
                        message = "You have \(cartItem.amount) \(item.itemName) in your shopping cart."
                    }
                    
                    break
                }
            }
        }
        else
        {
            shoppingCartButton.enabled = true
        }
        
        if found == false
        {
            let cartItem = ShoppingCartItem()
                cartItem.itemForSale = item
            shoppingCartItems.append(cartItem)
        }
        
        Auxiliar.presentAlertControllerWithTitle("Item added!",
            andMessage: message, forViewController: self)
    }
    
    //-------------------------------------------------------------------------//
    // MARK: ShoppingCart_VC_Delegate
    //-------------------------------------------------------------------------//
    
    func shoppingCartItemsListChanged(cartItems: [ShoppingCartItem])
    {
        shoppingCartItems = cartItems
        
        if shoppingCartItems.count == 0
        {
            shoppingCartButton.enabled = false
        }
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
        
        headerHeightConstraint.constant *= multiplier
        shoppingCartButtonHeightConstraint.constant *= multiplier
        
        var fontSize = 25.0 * multiplier
        shopName.font =  UIFont(name: "HelveticaNeue-Light", size: fontSize)
        
        fontSize = 17.0 * multiplier
        
        shoppingCartButton.imageEdgeInsets = UIEdgeInsetsMake(5 * multiplier, 144 * multiplier,
                                                              5 * multiplier, 144 * multiplier)
    }
    
    //-------------------------------------------------------------------------//
    // MARK: Navigation
    //-------------------------------------------------------------------------//
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?)
    {
        if (segue.identifier != nil) && (segue.identifier == "ToShoppingCart")
        {
            let vc = segue.destinationViewController as! ShoppingCart_VC
                vc.shoppingCartItems = shoppingCartItems
                vc.delegate = self
        }
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
