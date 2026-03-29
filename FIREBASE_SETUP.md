# Firebase Setup for Dinkr

## 1. Create Firebase Project

1. Go to [console.firebase.google.com](https://console.firebase.google.com)
2. Click **Add project** → Name it **Dinkr**
3. Disable Google Analytics (optional) → **Create project**

## 2. Add iOS App

1. In your Firebase project, click **Add app** → select iOS
2. Enter bundle ID: `com.dinkr.ios`
3. Enter App nickname: `Dinkr`
4. Click **Register app**
5. **Download `GoogleService-Info.plist`**
6. Replace the placeholder at:
   ```
   /PickleballApp/PickleballApp/Resources/GoogleService-Info.plist
   ```
   with the downloaded file

## 3. Enable Authentication Providers

In Firebase Console → **Authentication** → **Sign-in method**:

- **Email/Password** → Enable → Save
- **Apple** → Enable → enter your Apple Services ID → Save
- **Google** → Enable → enter support email → Save

> For Apple Sign-In in production you'll also need to configure the Sign in with Apple capability in Xcode and your Apple Developer account.

## 4. Create Firestore Database

1. Firebase Console → **Firestore Database** → **Create database**
2. Choose **Production mode** (we'll add security rules)
3. Select a region close to your users (e.g., `us-central`)

## 5. Create Storage Bucket

1. Firebase Console → **Storage** → **Get started**
2. Accept the default security rules for now
3. Choose the same region as Firestore

## 6. Add SPM Packages in Xcode

> If you're using `xcodegen` to generate the project, run `xcodegen generate` in the project root first — the `project.yml` already has the package references configured.
>
> If managing packages manually in Xcode:

1. Open `Dinkr.xcodeproj` in Xcode
2. **File** → **Add Package Dependencies...**
3. Add Firebase:
   - URL: `https://github.com/firebase/firebase-ios-sdk`
   - Version: `11.0.0` or later
   - Products to add: `FirebaseAuth`, `FirebaseFirestore`, `FirebaseFirestoreSwift`, `FirebaseStorage`
4. Add Google Sign-In:
   - URL: `https://github.com/google/GoogleSignIn-iOS`
   - Version: `7.0.0` or later
   - Products to add: `GoogleSignIn`, `GoogleSignInSwift`

## 7. Configure Google Sign-In URL Scheme

1. In Xcode, select the **Dinkr** target → **Info** tab
2. Expand **URL Types** → add a new entry
3. In **URL Schemes**, enter your `REVERSED_CLIENT_ID` from `GoogleService-Info.plist`
   (it looks like `com.googleusercontent.apps.YOUR-APP-ID`)

## 8. Deploy Firestore Security Rules

Copy the contents of `firestore.rules` (in this project root) into:
Firebase Console → **Firestore Database** → **Rules** → Paste → **Publish**

## 9. Verify Setup

1. Build and run the app — you should see the real sign-in screen (not the mock auto-login)
2. Create an account → check **Firebase Console → Firestore → users** collection
3. Browse sessions/events/market tabs → verify queries run (check Xcode console for errors)
4. Upload a profile photo → check **Firebase Console → Storage**

## Collections Created Automatically

The app will create these Firestore collections on first write:

| Collection       | Description                        |
|------------------|------------------------------------|
| `users`          | User profiles                      |
| `gameSessions`   | Scheduled game sessions            |
| `courtVenues`    | Pickleball court locations         |
| `events`         | Tournaments and events             |
| `groups`         | Pickup groups                      |
| `posts`          | Social feed posts                  |
| `marketListings` | Equipment marketplace listings     |
| `gameResults`    | Completed game results             |
