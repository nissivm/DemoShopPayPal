# DemoShopPayPal
Shop demo that uses PayPal as payment gateway and Firebase as backend and for Sign In/Sign Up.

<img src="https://cloud.githubusercontent.com/assets/6089173/12726050/47548544-c8f4-11e5-8916-14584e01783a.png" alt="Sign Up" width="320" height="568"/>
<img src="https://cloud.githubusercontent.com/assets/6089173/12726051/4759bfdc-c8f4-11e5-80ae-13adadda5e57.png" alt="Products" width="320" height="568"/>
<img src="https://cloud.githubusercontent.com/assets/6089173/12726052/475eabb4-c8f4-11e5-8764-d28edddd350d.png" alt="Shopping Cart" width="320" height="568"/>
<img src="https://cloud.githubusercontent.com/assets/6089173/12726053/4765e32a-c8f4-11e5-8907-07e1e9745299.png" alt="Checkout" width="320" height="568"/>

To test:

1) Download and install XAMPP, normally it is installed under the “Applications” folder. 

2) Unzip DemoShopPayPal-ServerSide folder.

3) Open “Applications/XAMPP/htdocs”, and insert there the folder you just unzipped.

4) Create an account in https://developer.paypal.com/ . 

5) In "My Apps & Credentials", click "Create App". Once the app is created, click on it (under "App name"), get your credentials (make sure you are in Sandbox mode!) and input them in Constants.swift, inside the project, and in VerifyPayment.php, in DemoShopPayPal-ServerSide folder.

6) In "Accounts", create a Personal test account with the same country as your facilitator account. You are going to use this test account to perform the login at the moment of the purchase, inside the app. Obs.: The facilitator is the seller.

7) In the project, in ShoppingCart_VC.swift, line 105, change the currency code to the one used by the country of your test account: ISO standard currency code (http://en.wikipedia.org/wiki/ISO_4217).

8) Create an account in https://www.firebase.com/, create an app, if it's not created automatically, and click "Manage App". 

9) In Data, click "Import Data" and insert firebase_initial_data.json.

10) In Security & Rules, copy past the content of firebase_rules.rtf and click "Save Rules".

11) In Login & Auth, open Email & Password tab and check "Enable Email & Password Authentication".

12) Insert your Firebase base url(ends with .firebaseio.com) in Constants.swift.

13) In the Podfile, input the correct address to your .xcodeproj. After this, go to terminal and open project's main folder (type cd, press space, drag folder to terminal and press enter). Type "pod install" and press enter.

14) Start XAMPP: Open Xampp, open Manage Servers tab, click "Start All" and wait all lights become green.

You are ready to test!
