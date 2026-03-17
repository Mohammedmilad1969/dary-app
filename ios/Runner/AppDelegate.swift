import UIKit
import Flutter
import Firebase
import FirebaseMessaging
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Initialize Firebase natively
    FirebaseApp.configure()
    // Set messaging delegate
    Messaging.messaging().delegate = self
    
    // Set notification delegate explicitly
    UNUserNotificationCenter.current().delegate = self
    
    // Request permission (as per guide)
    let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
    UNUserNotificationCenter.current().requestAuthorization(options: authOptions) { (granted, error) in
        if granted {
            DispatchQueue.main.async {
                application.registerForRemoteNotifications()
            }
        }
    }
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // Handle manual token registration (required when proxy is disabled)
  override func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    // Set the APNs token for Firebase Messaging.
    // Omit 'type' to let Firebase detect the environment (sandbox vs production) automatically.
    Messaging.messaging().apnsToken = deviceToken
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }

  // Handle background notifications
  override func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], 
                           fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
    print("📢 Did receive remote notification in background: \(userInfo)")
    
    // If you're using FCM, you should let it handle the notification
    super.application(application, didReceiveRemoteNotification: userInfo, fetchCompletionHandler: completionHandler)
  }
}

// Implement MessagingDelegate for explicit token logging
extension AppDelegate: MessagingDelegate {
  func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
    print("🔔 Firebase registration token: \(String(describing: fcmToken))")
  }
}

// Handle foreground notifications
extension AppDelegate {
  override func userNotificationCenter(_ center: UNUserNotificationCenter,
                                      willPresent notification: UNNotification,
                                      withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
    let userInfo = notification.request.content.userInfo
    print("📩 Foreground notification received: \(userInfo)")
    
    // Show the notification even when the app is in the foreground
    completionHandler([[.alert, .sound, .badge]])
  }

  override func userNotificationCenter(_ center: UNUserNotificationCenter,
                                      didReceive response: UNNotificationResponse,
                                      withCompletionHandler completionHandler: @escaping () -> Void) {
    let userInfo = response.notification.request.content.userInfo
    print("👆 Notification tapped: \(userInfo)")
    
    completionHandler()
  }
}

