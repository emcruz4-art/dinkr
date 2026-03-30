import Foundation
import Observation
import FirebaseAuth
import FirebaseFirestore
import AuthenticationServices
import CryptoKit
import GoogleSignIn
import UIKit

@Observable
final class AuthService {
    var currentUser: User? = nil
    var isAuthenticated: Bool = false
    var isLoading: Bool = false
    var error: String? = nil

    private var authStateListener: AuthStateDidChangeListenerHandle?

    init() {
        // Auth.auth() cannot be called here — FirebaseApp.configure() hasn't
        // run yet when @State properties are initialized. Listener is attached
        // in restoreSession(), which is called from AppRootView after launch.
    }

    deinit {
        if let handle = authStateListener {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }

    // MARK: - Restore Session

    func restoreSession() async {
        // Attach auth state listener now that FirebaseApp is configured.
        if authStateListener == nil {
            authStateListener = Auth.auth().addStateDidChangeListener { [weak self] _, firebaseUser in
                guard let self else { return }
                if let firebaseUser {
                    Task { await self.fetchAndSetUser(uid: firebaseUser.uid) }
                } else {
                    self.currentUser = nil
                    self.isAuthenticated = false
                }
            }
        }
        guard let firebaseUser = Auth.auth().currentUser else { return }
        await fetchAndSetUser(uid: firebaseUser.uid)
    }

    // MARK: - Email/Password Sign In

    func signIn(email: String, password: String) async throws {
        isLoading = true
        defer { isLoading = false }
        let result = try await Auth.auth().signIn(withEmail: email, password: password)
        await fetchAndSetUser(uid: result.user.uid)
    }

    // MARK: - Email/Password Sign Up

    func signUp(email: String, password: String, displayName: String) async throws {
        isLoading = true
        defer { isLoading = false }
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        let uid = result.user.uid
        let newUser = User(
            id: uid,
            displayName: displayName,
            username: displayName.lowercased().replacingOccurrences(of: " ", with: "_"),
            avatarURL: nil,
            bio: "",
            skillLevel: .intermediate30,
            city: "",
            location: nil,
            clubIds: [],
            badges: [],
            reliabilityScore: 5.0,
            gamesPlayed: 0,
            wins: 0,
            joinedDate: Date(),
            isWomenOnly: false,
            followersCount: 0,
            followingCount: 0,
                duprRating: nil,
                isPrivate: false,
                socialLinks: SocialLinks()
        )
        try await createUserDocument(newUser)
        currentUser = newUser
        isAuthenticated = true
    }

    // MARK: - Sign Out

    func signOut() {
        try? Auth.auth().signOut()
        currentUser = nil
        isAuthenticated = false
    }

    // MARK: - Apple Sign In

    func signInWithApple() async throws {
        isLoading = true
        defer { isLoading = false }

        let nonce = randomNonceString()
        let hashedNonce = sha256(nonce)

        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = hashedNonce

        let helper = AppleSignInHelper()
        let authorization = try await helper.performRequest(request)

        guard let appleCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let identityTokenData = appleCredential.identityToken,
              let identityToken = String(data: identityTokenData, encoding: .utf8) else {
            throw AuthError.appleSignInFailed
        }

        let firebaseCredential = OAuthProvider.appleCredential(
            withIDToken: identityToken,
            rawNonce: nonce,
            fullName: appleCredential.fullName
        )

        let result = try await Auth.auth().signIn(with: firebaseCredential)
        let uid = result.user.uid

        if (try? await fetchUserDocument(uid: uid)) != nil {
            await fetchAndSetUser(uid: uid)
        } else {
            let displayName = [
                appleCredential.fullName?.givenName,
                appleCredential.fullName?.familyName
            ].compactMap { $0 }.joined(separator: " ")
            let nameToUse = displayName.isEmpty ? (result.user.email ?? "Player") : displayName
            let newUser = User(
                id: uid,
                displayName: nameToUse,
                username: nameToUse.lowercased().replacingOccurrences(of: " ", with: "_"),
                avatarURL: nil,
                bio: "",
                skillLevel: .intermediate30,
                city: "",
                location: nil,
                clubIds: [],
                badges: [],
                reliabilityScore: 5.0,
                gamesPlayed: 0,
                wins: 0,
                joinedDate: Date(),
                isWomenOnly: false,
                followersCount: 0,
                followingCount: 0,
                duprRating: nil,
                isPrivate: false,
                socialLinks: SocialLinks()
            )
            try await createUserDocument(newUser)
            currentUser = newUser
            isAuthenticated = true
        }
    }

    // MARK: - Google Sign In

    func signInWithGoogle() async throws {
        isLoading = true
        defer { isLoading = false }

        guard let windowScene = await UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = await windowScene.windows.first?.rootViewController else {
            throw AuthError.noRootViewController
        }

        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootVC)
        guard let idToken = result.user.idToken?.tokenString else {
            throw AuthError.googleSignInFailed
        }

        let credential = GoogleAuthProvider.credential(
            withIDToken: idToken,
            accessToken: result.user.accessToken.tokenString
        )

        let authResult = try await Auth.auth().signIn(with: credential)
        let uid = authResult.user.uid

        if (try? await fetchUserDocument(uid: uid)) != nil {
            await fetchAndSetUser(uid: uid)
        } else {
            let displayName = result.user.profile?.name ?? "Player"
            let newUser = User(
                id: uid,
                displayName: displayName,
                username: displayName.lowercased().replacingOccurrences(of: " ", with: "_"),
                avatarURL: result.user.profile?.imageURL(withDimension: 200)?.absoluteString,
                bio: "",
                skillLevel: .intermediate30,
                city: "",
                location: nil,
                clubIds: [],
                badges: [],
                reliabilityScore: 5.0,
                gamesPlayed: 0,
                wins: 0,
                joinedDate: Date(),
                isWomenOnly: false,
                followersCount: 0,
                followingCount: 0,
                duprRating: nil,
                isPrivate: false,
                socialLinks: SocialLinks()
            )
            try await createUserDocument(newUser)
            currentUser = newUser
            isAuthenticated = true
        }
    }

    // MARK: - Private Helpers

    private func fetchAndSetUser(uid: String) async {
        guard let user = try? await fetchUserDocument(uid: uid) else { return }
        currentUser = user
        isAuthenticated = true
    }

    private func createUserDocument(_ user: User) async throws {
        try await FirestoreService.shared.setDocument(user,
                                                       collection: FirestoreCollections.users,
                                                       documentId: user.id)
    }

    private func fetchUserDocument(uid: String) async throws -> User {
        try await FirestoreService.shared.getDocument(collection: FirestoreCollections.users,
                                                       documentId: uid)
    }

    private func randomNonceString(length: Int = 32) -> String {
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        while remainingLength > 0 {
            var randoms = [UInt8](repeating: 0, count: 16)
            _ = SecRandomCopyBytes(kSecRandomDefault, randoms.count, &randoms)
            randoms.forEach { random in
                if remainingLength == 0 { return }
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        return result
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hash = SHA256.hash(data: inputData)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - Apple Sign In Helper (delegate bridge)

private final class AppleSignInHelper: NSObject,
                                        ASAuthorizationControllerDelegate,
                                        ASAuthorizationControllerPresentationContextProviding {
    private var continuation: CheckedContinuation<ASAuthorization, Error>?

    func performRequest(_ request: ASAuthorizationRequest) async throws -> ASAuthorization {
        try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
        }
    }

    func authorizationController(controller: ASAuthorizationController,
                                  didCompleteWithAuthorization authorization: ASAuthorization) {
        continuation?.resume(returning: authorization)
        continuation = nil
    }

    func authorizationController(controller: ASAuthorizationController,
                                  didCompleteWithError error: Error) {
        continuation?.resume(throwing: error)
        continuation = nil
    }

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow } ?? UIWindow()
    }
}

// MARK: - Auth Errors

enum AuthError: LocalizedError {
    case appleSignInFailed
    case googleSignInFailed
    case noRootViewController

    var errorDescription: String? {
        switch self {
        case .appleSignInFailed: return "Apple Sign In failed. Please try again."
        case .googleSignInFailed: return "Google Sign In failed. Please try again."
        case .noRootViewController: return "Unable to present sign-in screen."
        }
    }
}
