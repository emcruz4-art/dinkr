# Dinkr

> *Your game. Your court. Your crew.*

Dinkr is a social iOS app for pickleball players — find games, join groups, discover courts, buy/sell gear, and connect with your local community.

---

## Features

- **Home** — Bento-grid dashboard with live game count, featured events, community spotlight, top news, and your groups
- **Play** — Find open games, host your own, browse courts, see the leaderboard, and check in live
- **Groups** — Join neighborhood crews, competitive pools, and women's circles
- **Events** — Tournaments, clinics, and social mixers with registration and countdowns
- **Market** — Buy and sell paddles, bags, apparel, and accessories
- **Profile** — Skill level, reliability score, win rate, level system, badges, and game history

## Tech Stack

| Layer | Technology |
|---|---|
| UI | SwiftUI (iOS 17+) |
| Auth | Firebase Authentication (Email, Apple, Google) |
| Database | Cloud Firestore |
| Storage | Firebase Storage |
| Analytics | Firebase Analytics |
| Crash reporting | Firebase Crashlytics |
| Project generation | XcodeGen |

## Requirements

- Xcode 16+
- iOS 17.0+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)
- A Firebase project with `GoogleService-Info.plist`

## Getting Started

```bash
# Install XcodeGen if needed
brew install xcodegen

# Clone the repo
git clone https://github.com/emcruz4-art/dinkr.git
cd dinkr

# Generate the Xcode project
xcodegen generate

# Open in Xcode
open Dinkr.xcodeproj
```

Add your own `GoogleService-Info.plist` to `PickleballApp/Resources/` before building.

## Project Structure

```
PickleballApp/
├── App/                    # Entry point, root tab view
├── Core/
│   ├── Components/         # Reusable views (AvatarView, PickleballCard, etc.)
│   ├── Extensions/         # Color palette, SwiftUI helpers
│   ├── Models/             # Data models + mock data
│   └── Services/           # Firebase, Auth, Location, Store
└── Features/
    ├── Home/               # Bento grid + feed
    ├── Play/               # Games, courts, leaderboard
    ├── Groups/             # Group discovery + detail
    ├── Events/             # Tournament + event listings
    ├── Market/             # Gear marketplace
    ├── Profile/            # User profile + achievements
    └── Onboarding/         # Auth flow
```

## License

MIT
