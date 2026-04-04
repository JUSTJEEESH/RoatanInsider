# Roatan Insider: Android via Skip — Step-by-Step Setup Guide

**Follow these steps EXACTLY on your Mac. Copy-paste every command.**

---

## PHASE 0: Environment Setup (Do This First)

### Step 1: Install Skip

Open Terminal on your Mac and run:

```bash
brew install skiptools/skip/skip
```

This installs Skip AND automatically installs:
- Kotlin compiler
- Gradle build system  
- Android SDK and build tools

It takes a few minutes. Let it finish completely.

After it finishes, verify the version:

```bash
skip version
```

You should see Skip 1.8.x or later.

### Step 2: Install Android Studio

If you don't already have it:

1. Go to **developer.android.com/studio**
2. Download Android Studio for Mac
3. Install it (drag to Applications)
4. Open Android Studio
5. Complete the setup wizard (accept all defaults)

### Step 3: Create an Android Emulator

In Android Studio:

1. Click **More Actions** (or Tools menu) → **Virtual Device Manager**
2. Click **Create Virtual Device**
3. Select **Pixel 8** (or any modern phone) → Next
4. Select **API 34** (Android 14) system image → Download if needed → Next
5. Name it whatever you want → **Finish**
6. Click the **Play** button to start the emulator
7. **Leave the emulator running** — Skip needs it open

### Step 4: Verify Everything Works

Back in Terminal, run:

```bash
skip checkup
```

This checks that you have:
- Xcode (latest)
- Android Studio
- Android SDK
- A running Android emulator
- Kotlin & Gradle
- Java JDK 17 (bundled with Android Studio)

It also does a full test cycle: builds a test project, runs Swift AND Kotlin tests, and verifies APK output. **Fix any issues it flags before proceeding.** The output will tell you exactly what's missing.

For more detail if something fails:

```bash
skip checkup --verbose
```

### Step 5: Get a Google Maps API Key

1. Go to **console.cloud.google.com**
2. Create a new project called "Roatan Insider Android"
3. Go to **APIs & Services** → **Library**
4. Search for and enable these APIs:
   - **Maps SDK for Android**
   - **Maps SDK for iOS** (for Skip's cross-platform map)
5. Go to **APIs & Services** → **Credentials**
6. Click **Create Credentials** → **API Key**
7. Copy the API key — you'll need it in Phase 1
8. (Optional but recommended) Click **Restrict Key** → restrict to Maps SDK only

**Free tier gives you 28,000 map loads/month** — more than enough.

### Step 6: Google Play Developer Account

1. Go to **play.google.com/console**
2. Sign in with your Google account
3. Pay the **$25 one-time fee**
4. Complete identity verification

You don't need this until Phase 5, but it takes 24-48 hours to verify, so start it now.

---

## PHASE 1: Proof of Concept (The Big Test)

### Step 7: Create the Skip Project

**IMPORTANT:** Don't create this inside your existing RoatanInsider repo. Create it alongside it.

```bash
cd ~/Desktop
skip init --open-xcode RoatanInsiderAndroid
```

This creates a new Skip project and opens it in Xcode. You'll see:
- An Xcode project with both iOS and Android targets
- A `Package.swift` file (this is the heart of Skip)
- `Sources/` directory for your shared code
- `Darwin/` directory for iOS-specific config
- `Android/` directory for Android-specific config

### Step 8: Understand the Project Structure

Skip created this for you:

```
RoatanInsiderAndroid/
├── Package.swift                    ← Dependencies & Skip plugin config
├── Sources/
│   └── RoatanInsiderAndroid/        ← YOUR CODE GOES HERE
│       └── RoatanInsiderAndroidApp.swift
├── Tests/
│   └── RoatanInsiderAndroidTests/
├── Darwin/                          ← iOS-specific
│   ├── RoatanInsiderAndroid.xcconfig
│   ├── Assets.xcassets/
│   └── Sources/
│       └── RoatanInsiderAndroidAppMain.swift
└── Android/                         ← Android-specific
    └── app/
        └── src/main/
            ├── AndroidManifest.xml
            └── kotlin/.../MainActivity.kt
```

### Step 9: Add Dependencies

Open `Package.swift` and update it. Replace the contents with:

```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "RoatanInsiderAndroid",
    defaultLocalization: "en",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(
            name: "RoatanInsiderAndroidModule",
            type: .dynamic,
            targets: ["RoatanInsiderAndroid"]
        ),
    ],
    dependencies: [
        .package(url: "https://source.skip.tools/skip.git", from: "1.0.0"),
        .package(url: "https://source.skip.tools/skip-ui.git", from: "1.0.0"),
        .package(url: "https://source.skip.tools/skip-foundation.git", from: "1.0.0"),
        .package(url: "https://source.skip.tools/skip-model.git", from: "1.0.0"),
        .package(url: "https://source.skip.tools/skip-device.git", from: "1.0.0"),
        .package(url: "https://source.skip.tools/skip-gmaps.git", from: "0.1.0"),
        .package(url: "https://source.skip.tools/skip-sql.git", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "RoatanInsiderAndroid",
            dependencies: [
                .product(name: "SkipUI", package: "skip-ui"),
                .product(name: "SkipFoundation", package: "skip-foundation"),
                .product(name: "SkipModel", package: "skip-model"),
                .product(name: "SkipDevice", package: "skip-device"),
                .product(name: "SkipGMaps", package: "skip-gmaps"),
                .product(name: "SkipSQL", package: "skip-sql"),
            ],
            resources: [.process("Resources")],
            plugins: [
                .plugin(name: "skipstone", package: "skip"),
            ]
        ),
        .testTarget(
            name: "RoatanInsiderAndroidTests",
            dependencies: [
                "RoatanInsiderAndroid",
                .product(name: "SkipTest", package: "skip"),
            ],
            plugins: [
                .plugin(name: "skipstone", package: "skip"),
            ]
        ),
    ]
)
```

### Step 10: Copy Your Data Files

```bash
# Create Resources directory for bundled data
mkdir -p ~/Desktop/RoatanInsiderAndroid/Sources/RoatanInsiderAndroid/Resources

# Copy your JSON data files
cp ~/path-to-your-repo/RoatanInsider/RoatanInsider/Data/businesses.json \
   ~/Desktop/RoatanInsiderAndroid/Sources/RoatanInsiderAndroid/Resources/

cp ~/path-to-your-repo/RoatanInsider/RoatanInsider/Data/areas.json \
   ~/Desktop/RoatanInsiderAndroid/Sources/RoatanInsiderAndroid/Resources/

cp ~/path-to-your-repo/RoatanInsider/RoatanInsider/Data/categories.json \
   ~/Desktop/RoatanInsiderAndroid/Sources/RoatanInsiderAndroid/Resources/

# Copy guide files
mkdir -p ~/Desktop/RoatanInsiderAndroid/Sources/RoatanInsiderAndroid/Resources/guides

cp ~/path-to-your-repo/RoatanInsider/RoatanInsider/Data/guides/*.json \
   ~/Desktop/RoatanInsiderAndroid/Sources/RoatanInsiderAndroid/Resources/guides/
```

**Replace `~/path-to-your-repo/RoatanInsider` with your actual repo path.**

### Step 11: Copy Your Core Models

Copy these files into `Sources/RoatanInsiderAndroid/`:

```bash
SRC=~/path-to-your-repo/RoatanInsider/RoatanInsider
DEST=~/Desktop/RoatanInsiderAndroid/Sources/RoatanInsiderAndroid

# Create directory structure
mkdir -p $DEST/Models
mkdir -p $DEST/Utilities

# Copy models (these should work as-is with Skip)
cp $SRC/Models/Business.swift $DEST/Models/
cp $SRC/Models/Category.swift $DEST/Models/
cp $SRC/Models/Area.swift $DEST/Models/
cp $SRC/Models/Guide.swift $DEST/Models/
cp $SRC/Models/Phrase.swift $DEST/Models/

# Copy utilities
cp $SRC/Utilities/Colors.swift $DEST/Utilities/
cp $SRC/Utilities/Constants.swift $DEST/Utilities/
```

### Step 12: Create a Simple Test View

Create a new file at `Sources/RoatanInsiderAndroid/TestListView.swift`:

```swift
import SwiftUI
#if canImport(SkipFoundation)
import SkipFoundation
#endif

struct TestListView: View {
    @State private var businesses: [Business] = []
    
    var body: some View {
        NavigationStack {
            List(businesses) { business in
                VStack(alignment: .leading, spacing: 4) {
                    Text(business.name)
                        .font(.headline)
                    Text(business.area.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Roatan Insider")
        }
        .task {
            loadBusinesses()
        }
    }
    
    private func loadBusinesses() {
        guard let url = Bundle.main.url(forResource: "businesses", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([Business].self, from: data) else {
            return
        }
        businesses = decoded
    }
}
```

### Step 13: Update the App Entry Point

Open `Sources/RoatanInsiderAndroid/RoatanInsiderAndroidApp.swift` and replace with:

```swift
import SwiftUI

@main struct RoatanInsiderApp: App {
    var body: some Scene {
        WindowGroup {
            TestListView()
        }
    }
}
```

### Step 14: The Moment of Truth — Build and Run

In Xcode:

1. Make sure your **Android emulator is running** (from Step 3)
2. Select the **RoatanInsiderAndroid** scheme
3. Press **Cmd+R** to build and run

**What to expect:**
- First build will be SLOW (5-10 minutes) — Skip compiles all its libraries from source
- Subsequent builds are fast
- The iOS simulator AND Android emulator should both launch
- You should see a list of Roatan businesses on BOTH platforms

### Step 15: Decision Point

**If it works:** Celebrate. The hardest part is over. Your data models parse, your JSON loads, and Skip can render your UI. Proceed to Phase 2.

**If there are build errors:**
- Check Terminal/Xcode build log for specific errors
- Common issues:
  - Models with `import CoreLocation` — wrap in `#if !SKIP` or remove CLLocation dependencies temporarily
  - `UIImage` references — wrap in `#if !SKIP`
  - Custom `init(from decoder:)` — may need simplification
  - Missing SF Symbol mappings — use `Image("fallback")` for now
- If errors are minor and fixable, fix them and retry
- If errors are fundamental, this tells us Skip isn't right and we pivot to native Kotlin

---

## What Happens After Phase 1

Once the POC works, we move through the remaining phases together:

**Phase 2 (Days 6-15):** Migrate all 5 tabs one at a time
**Phase 3 (Days 16-22):** Business detail, guides, full navigation  
**Phase 4 (Days 23-30):** Location, networking, polish
**Phase 5 (Days 31-40):** Testing, Play Store submission

I'll write detailed guides for each phase as we get there. Phase 1 is the gatekeeper — everything after it is incremental.

---

## Quick Reference: What Goes Where

| Your iOS Files | Skip Location | Changes Needed |
|---------------|---------------|----------------|
| Models/*.swift | Sources/Models/ | Remove CoreLocation imports, wrap UIKit |
| Utilities/Colors.swift | Sources/Utilities/ | Remove UIColor references |
| Utilities/Constants.swift | Sources/Utilities/ | Works as-is |
| Data/*.json | Sources/Resources/ | Works as-is (copy directly) |
| Views/*.swift | Sources/Views/ | Phase 2 — migrate one tab at a time |
| Services/*.swift | Sources/Services/ | Phase 3-4 — platform-specific rework |
| ViewModels/*.swift | Sources/ViewModels/ | Phase 2 — mostly works as-is |

---

## Troubleshooting Common Issues

**"skip: command not found"**
→ Run `brew install skiptools/skip/skip` again, then `source ~/.zshrc`

**"No Android emulator detected"**
→ Open Android Studio → Virtual Device Manager → Start your emulator FIRST, then build

**"Gradle build failed"**
→ Check your internet connection (first build downloads dependencies). Try `skip clean` then rebuild.

**"Module 'SkipUI' not found"**
→ Close Xcode, run `swift package resolve` in Terminal from the project directory, reopen Xcode

**"Cannot find 'Business' in scope"**
→ Make sure Business.swift is in the correct `Sources/RoatanInsiderAndroid/Models/` path

**Build is extremely slow**
→ First build is always slow (5-10 min). Subsequent builds use cache and are much faster.

**"Trust and Enable" plugin prompt in Xcode**
→ First time opening a Skip project, Xcode asks you to trust the skipstone plugin. Click "Trust & Enable" — it's safe. Easy to miss!

**Environment variables not found by Xcode**
→ If `skip checkup` passes in Terminal but Xcode builds fail, it's because Xcode launched from Finder doesn't inherit your shell environment. **Always open the project from Terminal:**
```bash
open Project.xcworkspace
```

**Java version mismatch**
→ Skip requires JDK 17 (bundled with Android Studio). If `skip checkup` flags Java, check with `java -version`. If wrong version, set JAVA_HOME to Android Studio's bundled JDK.

**"Do NOT add packages via Xcode's UI"**
→ All dependencies must go in Package.swift directly. Do NOT use Xcode's File → Add Package Dependencies menu — it won't work with Skip.

---

## Checklist Before You Start

- [ ] Mac with Xcode (latest) installed
- [ ] Homebrew installed (`brew --version` to check)
- [ ] ~10 GB free disk space (Android SDK + emulator images)
- [ ] Stable internet connection (first build downloads a lot)
- [ ] Your Roatan Insider repo accessible on this Mac
- [ ] 2-3 hours of uninterrupted time for Phase 0 + 1

---

**You've got this, Josh. The first Android build of Roatan Insider is about to happen.**
