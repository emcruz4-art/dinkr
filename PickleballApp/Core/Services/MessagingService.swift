import Foundation
import FirebaseAuth
import FirebaseMessaging
import FirebaseFirestore
import UserNotifications
import UIKit

@MainActor
final class MessagingService: NSObject, ObservableObject, UNUserNotificationCenterDelegate, MessagingDelegate {
    static let shared = MessagingService()

    @Published var fcmToken: String? = nil
    @Published var inAppNotification: InAppNotification? = nil

    private override init() { super.init() }

    struct InAppNotification: Identifiable {
        let id = UUID()
        let title: String
        let body: String
    }

    func setup() {
        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self
    }

    func requestPermission() async {
        let granted = (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])) ?? false
        if granted {
            await MainActor.run {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }

    func saveTokenToFirestore(userId: String) async {
        guard let token = fcmToken else { return }
        try? await Firestore.firestore()
            .collection("users")
            .document(userId)
            .updateData(["fcmToken": token])
    }

    // MARK: - MessagingDelegate
    nonisolated func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let token = fcmToken else { return }
        Task { @MainActor [weak self] in
            self?.fcmToken = token
            // If a user is already authenticated, persist the refreshed token immediately
            if let userId = Auth.auth().currentUser?.uid {
                await self?.saveTokenToFirestore(userId: userId)
            }
        }
    }

    // MARK: - UNUserNotificationCenterDelegate
    // Show notification even when app is in foreground
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        completionHandler()
    }
}
