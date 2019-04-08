//
//  AppDelegate.swift
//  NXSpot
//
//  Created by Anupriya Kumari on 11/6/17.
//  Copyright © 2017 Anupriya Kumari. All rights reserved.
//
import UIKit
import IQKeyboardManager
import Firebase
import UserNotifications
import FirebaseMessaging
import FirebaseInstanceID
import GooglePlaces
import GoogleMaps
import SlideMenuControllerSwift
import PubNub
import Toast_Swift
import Crashlytics
import Fabric
import SwiftEventBus

let gcmMessageIDKey = "gcm.message_id"
var fcmReceiveNotificationIncomming : FcmReceiveNotificationsIncomming.Request?
var apiGetPendingScheduleIncomming : ApiGetPendingScheduleIncomming?
var pendingSchedule : ApiGetPendingScheduleIncomming.ScheduleSpotDetail?
var getUserInfo : ApiGetUserInfoIncomming?
var uUid : String?
@UIApplicationMain

class AppDelegate: UIResponder, UIApplicationDelegate {
	var window: UIWindow?
    var client : PubNub
    var closureAppDelegatePubNub :((Any?) -> Void )?
    var style = ToastStyle()
    var totalTime = 2
    var countdownTimer : Timer?
    override init() {
        let    config = PNConfiguration(publishKey: "pub-c-64d048b3-56a6-44c3-ba8b-53d1deca2f7a",
                                        subscribeKey: "sub-c-75188d5c-019d-11e8-9b4e-2ef0d1716781")
       // config.uuid = "Client-yemi2"
        client = PubNub.clientWithConfiguration(config)
        
        //config.stripMobilePayload = false
        super.init()
        client.addListener(self)
        //
        //client.addListener(self)
    }

	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        firebaseConfigure()
//        Fabric.with([Crashlytics.self])
//        Fabric.sharedSDK().debug = true
		// Override point for customization after application launch.
        #if DEBUG
           // Dotzu.sharedManager.enable()
        #endif
        print(#function)
		IQKeyboardManager.shared().isEnabled = true
        postGetPendingSchedule()
        leoMapKitInitilieGoogleApi()
        GMSPlacesClient.provideAPIKey(leoGoogleMapsApiGoogleKey)
        GMSServices.provideAPIKey(leoGoogleMapsApiGoogleKey)
//          GMSPlacesClient.provideAPIKey("AIzaSyARmPKkNYv4DU1u5AbAu1cw_pfs87mi21g")
//          GMSServices.provideAPIKey("AIzaSyARmPKkNYv4DU1u5AbAu1cw_pfs87mi21g")
        // Get DeviceId And Save to UserDefault
        uUid = UIDevice.current.identifierForVendor?.uuidString
        UserDefaults.standard.setUuId(value: uUid!)
        setupIAP()
        
        
    // Register For Push Notification

        self.registerForPushNotifications(application: application)
        Messaging.messaging().delegate = self
        print("Some is " ,"🚜 🚜🚜", defaultLeoFcmToken ?? "NG")
        if InstanceID.instanceID().token() != nil {
            
            self.connectToFcm()
        }
        if launchOptions != nil {
            //opened from a push notification when the app is closed
            _ = launchOptions?[UIApplicationLaunchOptionsKey.remoteNotification] as? [AnyHashable: Any] ?? [AnyHashable: Any]()
        } else {
            //opened app without a push notification.
        }
		return true
	}

	func applicationWillResignActive(_ application: UIApplication) {
		// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
		// Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
	}

	func applicationDidEnterBackground(_ application: UIApplication) {
		// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
		// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
	}

	func applicationWillEnterForeground(_ application: UIApplication) {
		// Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
	}

	func applicationDidBecomeActive(_ application: UIApplication) {
		// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
	}

	func applicationWillTerminate(_ application: UIApplication) {
		// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
	}
    
    
    func getFirstScreen(){
        
        let storyboard = UIStoryboard.init(name: "Main", bundle: nil)
        
        let mainViewController = storyboard.instantiateViewController(withIdentifier: "ViewController" ) as! ViewController
        
        let leftViewController = storyboard.instantiateViewController(withIdentifier: "LeftViewController" ) as! LeftViewController
        //self.navigationController?.pushViewController(vc, animated: true)
        
        let slideMenuController = SlideMenuController(mainViewController: mainViewController, leftMenuViewController: leftViewController)
        self.window?.rootViewController = slideMenuController
        self.window?.makeKeyAndVisible()
        
        
    }
   
    
    


}


extension AppDelegate : UNUserNotificationCenterDelegate {
    
    // Receive displayed notifications for iOS 10 devices.
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
     //   handleNotification(userInfo :  notification.request.content.userInfo)
        //        if let type =  NotificationEnums.notificationType(notification: notification) {
        //
        //            print("🚀🚀🚀🚀" ,type)
        //
        //        }
        //
        //
        //
        //        print("🌎🌎🌎🌎will For ground Present userInfo: \(userInfo)")
        //        // With swizzling disabv led you must let Messaging know about the message, for Analytics
        //        // Messaging.messaging().appDidReceiveMessage(userInfo)
        //        // Print message ID.
        //        if let messageID = userInfo[gcmMessageIDKey] {
        //            print("🌎🌎🌎🌎Message ID: \(messageID)")
        //        }
        //
        //        // Print full message.
        //        print(userInfo)
        
        // Change this to your preferred presentation option
        completionHandler([])
    }
    
    func handleNotification(userInfo: [AnyHashable : Any]) {
        //print("Hello Notification " , notification)
      //  Logger.info("Notification " , userInfo)
        if let type =  NotificationEnums.notificationType(userInfo: userInfo) {
            switch type {
            case .send :
                print(type)
                let some = FcmSendNotificationsIncomming(userInfo: userInfo)
                print("🚀🌎🚀🌎🚀🌎🚀🌎🚀🌎🚀🌎" ,some)
                if some.requests.count > 0 {
                   let viewParking = NotificationParkingRequest.alertNotification(window: window, fcmSendNotificationsIncomming :  some)
                    viewParking?.closureFcmSendNotificationsIncomming = { fcmSendRequest in
                        let routeForFcm = RouteForLeaveASpot(request: fcmSendRequest)
                        let storyboard = UIStoryboard.init(name: "Main", bundle: nil)
                        let vc = storyboard.instantiateViewController(withIdentifier: "LeaveMapViewController") as! LeaveMapViewController
                       
                        vc.routeForLeaveASpot = routeForFcm
                        
                        if let window = self.window, let rootViewController = window.rootViewController {
                            var currentController = rootViewController
                            while let presentedController = currentController.presentedViewController {
                                currentController = presentedController
                            }
                            currentController.present(vc, animated: true, completion: nil)
                        }
                    }
                }
                break
                    case .receive:
                    print(type)
                
                let some = FcmReceiveNotificationsIncomming(userInfo: userInfo)
                print("🚀🌎🚀🌎🚀🌎🚀🌎🚀🌎🚀🌎 RECEIVE 🐥🐥🐥🐥🐥" ,some)
                if some.requests.count > 0 {
                    
                        if some.request!.actions == EnumActions.accepted.value {
                           // NotificationCenter.default.post(name: .nxSpotAccepted, object: nil)
                            print("Accepted 🐥🐥🐥🐥🐥")
                            let viewRouteForNeed = NotificationAcceptedRequest.alertNotification(window: window, fcmReceiveNotificationIncomming:  some)
                            
                            // Start Timer
                            viewRouteForNeed?.closureReceiveNotificationIncomming = { receiveNotification in
                                
                                
                                let storyboard = UIStoryboard.init(name: "Main", bundle: nil)
                                
                                let vc = storyboard.instantiateViewController(withIdentifier: "NeedRouteViewController") as! NeedRouteViewController
                                
                                // vc.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
                                
                                vc.routeForNeed = receiveNotification
                                
                                if let window = self.window, let rootViewController = window.rootViewController {
                                    var currentController = rootViewController
                                    while let presentedController = currentController.presentedViewController {
                                        currentController = presentedController
                                    }
                                    currentController.present(vc, animated: true, completion: nil)
                                }
                                
                            }
                            
                        }else if some.request!.actions == EnumActions.cancelled.value {
                            print("Declined 🐥🐥🐥🐥🐥")
                            _ = NotificationDeclinedRequest.alertNotification(window: window, fcmReceiveNotificationIncomming:  some)
                        }
                }
                
                break
                
            case .reached:
                
                let some = FcmReachedNotificationsIncomming(payload: userInfo)
                
                ViewController.notifyReached = some
                
                ViewNotificationReached.alertReachedNotification(window: window, fcmReachedNotificationsIncomming: some)
                
                NotificationCenter.default.post(name: .nxSpotReached, object: nil)
                
                break
            case .canceled:
                
                 style.backgroundColor = SOSTableViewCellsColors.orangeLight.color
                 
                 window?.makeToast("sorry that spot was close!", duration: 3.0, position: .bottom, style: style )
                
                    let storyboard = UIStoryboard.init(name: "Main", bundle: nil)
                    
                    let vc = storyboard.instantiateViewController(withIdentifier: "ContainerViewController") as! ContainerViewController
                    
                    if let window = self.window, let rootViewController = window.rootViewController {
                        var currentController = rootViewController
                        while let presentedController = currentController.presentedViewController {
                            currentController = presentedController
                        }
                        currentController.present(vc, animated: true, completion: nil)
                    }
                    
break
            case .postReceive:
                
                let some = FcmPostReceiveNotificationIncomming(userInfo: userInfo)
                if some.requests.count > 0 {
                if some.request!.actions == EnumActions.accepted.value {
                    
        let viewRouteForNeed = NotificationAcceptedRequest.alertPostNotification(window: window, fcmPostReceiveNotificationIncomming: some)
        viewRouteForNeed?.closurePostReciveNotificationIncomming = { postReceiveNotification , timer in
                            
                    let storyboard = UIStoryboard.init(name: "Main", bundle: nil)
            
                   let vc = storyboard.instantiateViewController(withIdentifier: "NeedRouteViewController") as! NeedRouteViewController
            
                  vc.postRouteForNeeed = postReceiveNotification
            
                  vc.postTimer = timer
            
                  if let window = self.window, let rootViewController = window.rootViewController {
                 var currentController = rootViewController
                    
                 while let presentedController = currentController.presentedViewController {
                                                                currentController = presentedController
                                                            }
                                                            currentController.present(vc, animated: true, completion: nil)
                                                        }
                        }
                        

                        
                    }else if some.request!.actions == EnumActions.cancelled.value {
            
//                        _ = NotificationDeclinedRequest.alertNotification(window: window, fcmReceiveNotificationIncomming:  some)
                    }
                    
                }
                break
            case .postSend:
                
                let some = FcmPostSendNotificationIncomming(userInfo: userInfo)
             if some.requests.count > 0 {
                
                  let viewParking = NotificationParkingRequest.alertPostNotification(window: window, fcmPostSendNotificationsIncomming: some)
                viewParking?.closurePostSendNotificationIncomming = {
                    routeForPost in
                 let routeForPost = RouteForPostRqst(request: routeForPost)
                SwiftEventBus.post("acceptPostRequest", sender: routeForPost as AnyObject)
                    
    
                }
                
//                        let storyboard = UIStoryboard.init(name: "Main", bundle: nil)
//
//                        let vc = storyboard.instantiateViewController(withIdentifier: "PostNotificationParkingRequestViewController") as!  PostNotificationParkingRequestViewController
//
//                        vc.postSendRequest = some.request
//
//                        if let window = self.window, let rootViewController = window.rootViewController {
//                            var currentController = rootViewController
//
//                            while let presentedController = currentController.presentedViewController {
//                                currentController = presentedController
//
//                            }
//                            currentController.present(vc, animated: false, completion: nil)
//                        }
              }
                
                // add window to shoe Notification
                
                break
            case .none :
                print(type)
                
            }
            
            
        }
        
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        
        handleNotification(userInfo : response.notification.request.content.userInfo)
        
        
        completionHandler()
    }
}
// [END ios_10_message_handling]

extension AppDelegate : MessagingDelegate {
    // [START refresh_token]
    // MARK: FCM Token Refreshed
    func messaging(_ messaging: Messaging, didRefreshRegistrationToken fcmToken: String) {
       //  NSLog("🔥FireBase🔥 [RemoteNotification] didRefreshRegistrationToken: \(fcmToken)")
        print("🔥FireBase🔥 [RemoteNotification] didRefreshRegistrationToken: \(fcmToken)")
      //  defaultLeoFcmToken = fcmToken
        
    }
    
    // Receive data message on iOS 10 devices while app is in the foreground.
    @nonobjc internal func messaging(_ messaging: Messaging, didReceive remoteMessage: MessagingRemoteMessage) {
        NSLog("🔥FireBase🔥  remoteMessage: \(remoteMessage.appData)")
        
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
         
         print("🖥Apple🖥 💌🖥💌🖥didRegisterForRemoteNotificationsWithDeviceToken 💌🖥💌🖥💌🖥💌 🖥  APNs token retrieved: \(deviceToken)")
        
        Messaging.messaging().apnsToken = deviceToken
        
        let deviceTokenString = deviceToken.reduce("", {$0 + String(format: "%02X", $1)})
        
        print("🖥Apple🖥didRegisterForRemoteNotificationsWithDeviceToken ", deviceTokenString)
        
        if let refreshedToken = InstanceID.instanceID().token() {
            
            defaultLeoFcmToken = refreshedToken
            print("InstanceID token: \(refreshedToken)")
        }
        // With swizzling disabled you must set the APNs token here.
        // Messaging.messaging().apnsToken = deviceToken
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("🖥Apple🖥 💌🖥💌didFailToRegisterForRemoteNotificationsWithError 🖥💌🖥💌🖥💌🖥💌 🖥 Unable to register for remote notifications: \(error.localizedDescription)")
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        Messaging.messaging().appDidReceiveMessage(userInfo)
        // Print message ID.
        if let messageID = userInfo[gcmMessageIDKey] {
            print("🖥 Apple🖥  idReceiveRemoteNotification fetchCompletionHandler 💌🖥💌🖥💌🖥💌🖥💌 🖥  Message ID: \(messageID)")
        }
        
        // Print full message.
        print(userInfo)
        handleNotification(userInfo :  userInfo)
        completionHandler(UIBackgroundFetchResult.newData)
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
       // If you are receiving a notification message while your app is in the background,
        //  this callback will not be fired till the user taps on the notification launching the application.
        // TODO: Handle data of notification
        // With swizzling disabled you must let Messaging know about the message, for Analytics
        Messaging.messaging().appDidReceiveMessage(userInfo)
        // Print message ID.
        
        print("🖥 Apple🖥 didReceiveRemoteNotification 💌💌💌💌Message user info ", userInfo)
        
        if let messageID = userInfo[gcmMessageIDKey] {
            print("🖥 Apple🖥  Message ID: \(messageID)")
        }
        
        // Print full message.
        print(userInfo)
    }
    
        func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
    
            let token = Messaging.messaging().fcmToken
            print("FCM token: \(token ?? "")")
    
    
        }
    
    // [END receive_message]
    
    // MARK: FCM
    
    func application(received remoteMessage: MessagingRemoteMessage) {
        print("🖥 Apple🖥 pplication(received remoteMessage: MessagingRemoteMessage  💌💌💌💌💌 remoteMessage", remoteMessage.appData)
    }
    
    
 
    
    func postGetPendingSchedule(){
        
       let someRequest = ApiGetPendingScheduleOutGoing(customerId: defaultLeoDefaultUser?.id)
        WebServices.post(url: APi.getPendingSchedule.url, jsonObject: someRequest.dictionaryRepresentation(), completionHandler: { (response, _) in
            
             apiGetPendingScheduleIncomming = ApiGetPendingScheduleIncomming(response: response)
         
            if isApiSussess(response: response){
              
                 pendingSchedule =  apiGetPendingScheduleIncomming?.scheduleSpotDetails.first
                
                let storyboard = UIStoryboard.init(name: "Main", bundle: nil)
                
                let vc = storyboard.instantiateViewController(withIdentifier: "ScheduleSpotViewController") as! ScheduleSpotViewController
                
               vc.pendingSchedule = pendingSchedule
                
                if let window = self.window, let rootViewController = window.rootViewController {
                    var currentController = rootViewController
                    
                    while let presentedController = currentController.presentedViewController {
                        currentController = presentedController
                    }
                    currentController.present(vc, animated: true, completion: nil)
                }
                
            }
            else if isApiError(response: response){
                
                if defaultLeoDefaultUser == nil{
                    
                   
                    
                    UIApplication.shared.keyWindow?.windowLevel = UIWindowLevelNormal
                    let storyboard = UIStoryboard.init(name: "Main", bundle: nil)

                    let mainViewController = storyboard.instantiateViewController(withIdentifier: "ViewController" ) as! ViewController

                    let leftViewController = storyboard.instantiateViewController(withIdentifier: "LeftViewController" ) as! LeftViewController
                    //self.navigationController?.pushViewController(vc, animated: true)

                    let slideMenuController = SlideMenuController(mainViewController: mainViewController, leftMenuViewController: leftViewController)
                    self.window?.rootViewController = slideMenuController
                    self.window?.makeKeyAndVisible()
                    
                }else{
                    
                    
                    
                    UIApplication.shared.keyWindow?.windowLevel = UIWindowLevelNormal
                    let storyboard = UIStoryboard.init(name: "Main", bundle: nil)

                    let mainViewController = storyboard.instantiateViewController(withIdentifier: "HomeViewController" ) as! HomeViewController

                    let leftViewController = storyboard.instantiateViewController(withIdentifier: "LeftViewController" ) as! LeftViewController
                    //self.navigationController?.pushViewController(vc, animated: true)

                    let slideMenuController = SlideMenuController(mainViewController: mainViewController, leftMenuViewController: leftViewController)
                    self.window?.rootViewController = slideMenuController
                    self.window?.makeKeyAndVisible()
                    
                    
                }
                
            }
            
        
        }) { (response, _) in
            
            
            
        }
      
    }
    
    
    
    
  
}

extension AppDelegate {
    
    //Register for push notification.
    func registerForPushNotifications(application: UIApplication) {
        
        if #available(iOS 10.0, *) {
            
            Messaging.messaging().shouldEstablishDirectChannel = true
            
            let center  = UNUserNotificationCenter.current()
            center.delegate = self
            center.requestAuthorization(options: [.alert, .sound]) { (_, error) in
                if error == nil {
                    DispatchQueue.main.async(execute: {
                        application.registerForRemoteNotifications()
                    })
                }
            }
        } else {
            
            let settings = UIUserNotificationSettings(types: [.alert, .sound], categories: nil)
            application.registerUserNotificationSettings(settings)
            application.registerForRemoteNotifications()
            
        }
        
        // Add observer for InstanceID token refresh callback.
        NotificationCenter.default.addObserver(self, selector: #selector(self.tokenRefreshNotification), name: NSNotification.Name.InstanceIDTokenRefresh, object: nil)
        
    }
    
    @objc func tokenRefreshNotification(_ notification: Notification) {
        
        print(#function)
        
        if let refreshedToken = InstanceID.instanceID().token() {
            NSLog("Notification: refresh token from FCM -> \(refreshedToken)")
            
        }
        // Connect to FCM since connection may have failed when attempted before having a token.
        connectToFcm()
        
    }
    
    func connectToFcm() {
        // Won't connect since there is no token
        guard InstanceID.instanceID().token() != nil else {
            NSLog("FCM: Token does not exist.")
            return
        }
        
        Messaging.messaging().shouldEstablishDirectChannel = true
    }
}

extension AppDelegate {
    
    func firebaseConfigure() {
        
        FirebaseApp.configure()
        
    }
}

extension AppDelegate{
    
    func startTimer() {
        countdownTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updateTime), userInfo: nil, repeats: true)
        
    }
    
    @objc func updateTime() {
        
        
        if totalTime != 0 {
            
            totalTime -= 1
            
        } else {
          
            endTimer()
        }
    }
    
    func endTimer() {
        
        countdownTimer?.invalidate()
        if countdownTimer?.isValid == false{
            let storyboard = UIStoryboard.init(name: "Main", bundle: nil)
            
            let vc = storyboard.instantiateViewController(withIdentifier: "ContainerViewController") as!  ContainerViewController
            
            if let window = self.window, let rootViewController = window.rootViewController {
                var currentController = rootViewController
                
                while let presentedController = currentController.presentedViewController {
                    currentController = presentedController
                }
                currentController.present(vc, animated: false, completion: nil)
            }
            
        }
        
    
    }
    
    func timeFormatted(_ totalSeconds: Int) -> String {
        let seconds: Int = totalSeconds % 60
        let minutes: Int = (totalSeconds / 60) % 60
        //     let hours: Int = totalSeconds / 3600
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    
}


