# Roatan Insider: Android Strategy Research

**Date:** April 2026
**Context:** 100+ users requesting an Android version of our live iOS app

---

## TL;DR

There is no magic "export to Android" button. But the landscape has changed dramatically -- as of **Swift 6.3 (March 2026)**, Swift officially compiles for Android. Combined with **Skip** (an open-source Swift-to-Kotlin transpiler), there are now realistic paths forward. Here are the four options ranked by practicality:

| Option | Code Reuse | Effort | Risk | Recommendation |
|--------|-----------|--------|------|----------------|
| **A. Skip (transpiler)** | 60-80% | Medium | Medium | Best starting point |
| **B. Native Kotlin/Compose rewrite** | 0% (data only) | High | Low | Safest, highest quality |
| **C. Swift SDK + Kotlin UI** | ~30% (logic only) | High | Medium | Interesting but immature |
| **D. Flutter/React Native rewrite** | 0% | High | Low | Overkill for this app |

---

## Your App at a Glance (Porting Assessment)

| Metric | Value |
|--------|-------|
| Total Swift files | 78 |
| Total lines of code | 7,725 |
| UI code (SwiftUI views) | 5,333 lines (69%) |
| Business logic + models | 2,392 lines (31%) |
| JSON data files | ~6,800 lines (fully portable) |

**Key dependencies to replace on Android:**
- SwiftUI (21 imports) --> Jetpack Compose
- MapKit (7 imports) --> Google Maps SDK
- CoreLocation (7 imports) --> Android Location Services
- SwiftData (2 imports) --> Room Database
- SF Symbols --> Material Icons

**Good news:** Clean MVVM architecture, thin ViewModels, simple JSON data layer, no complex third-party dependencies. This is very portable.

---

## Option A: Skip (Best Starting Point)

### What it is
[Skip](https://skip.tools) is a **Swift-to-Kotlin transpiler** that converts Swift + SwiftUI into Kotlin + Jetpack Compose, producing a fully native Android app. It became **free and open source** in January 2026.

### How it works
1. Skip parses your Swift code using Apple's SwiftSyntax
2. Translates it to equivalent Kotlin ("Kotlish")
3. **SkipUI** reimplements SwiftUI APIs mapping to Jetpack Compose
4. iOS runs normal Swift/SwiftUI; Android runs transpiled native Kotlin/Compose
5. Output is human-readable Kotlin -- you can "eject" and maintain it directly

### What would need to change for Roatan Insider

| Component | Skip Support | Notes |
|-----------|-------------|-------|
| TabView, NavigationStack | Supported | Core navigation works |
| ScrollView, List, LazyVGrid | Supported | Standard layouts work |
| Map (MapKit) | Via skip-map | Bridges to Google Maps on Android |
| SwiftData | NOT supported | Replace with skip-model or custom solution |
| SF Symbols | Partial | Many map to Material Icons; some need manual mapping |
| @Observable | Supported | Skip supports modern observation |
| Bundled JSON loading | Supported | Foundation's JSONDecoder works |
| CoreLocation | Via skip-location | Bridges to Android Location Services |

### Realistic assessment
- **60-80% of your code** could be shared through Skip
- SwiftData replacement is the biggest hurdle -- need to rearchitect favorites storage
- Some SwiftUI views may need `#if SKIP` conditionals for platform-specific behavior
- Debugging transpiled Kotlin is harder than debugging native code
- Skip is actively developed but not yet at 100% SwiftUI API coverage

### Risk level: Medium
Skip is open source with active development, but it's still a transpilation layer. Complex UI animations or niche SwiftUI features may not translate perfectly.

---

## Option B: Native Kotlin + Jetpack Compose (Safest)

### What it is
Build a dedicated Android app from scratch using Kotlin and Jetpack Compose (Android's modern UI framework, analogous to SwiftUI).

### What carries over
- **All JSON data** (businesses.json, areas.json, guides/) -- 100% portable
- **Architecture patterns** -- MVVM maps directly to Android's ViewModel + Compose
- **Business logic concepts** -- search/filter algorithms, currency conversion, etc. rewritten in Kotlin
- **Design system** -- colors, typography, spacing all translate to Compose themes
- **All content** -- descriptions, tips, guide text

### What gets rewritten
- All 49 SwiftUI view files --> Jetpack Compose equivalents
- MapKit integration --> Google Maps Compose
- SwiftData --> Room Database
- CoreLocation --> Android FusedLocationProvider
- ViewModels --> Android ViewModel + StateFlow

### Estimated effort
- **8,000-9,500 lines of Kotlin** (slightly more verbose than Swift)
- With Claude Code assistance, this is very achievable
- The CLAUDE.md and design system documentation would guide the Android build perfectly

### Risk level: Low
This is the most predictable path. Kotlin/Compose is mature, well-documented, and the standard way to build Android apps. No transpilation layer to debug.

---

## Option C: Official Swift SDK + Kotlin UI (Hybrid)

### What it is
Use the **official Swift Android SDK** (stable as of Swift 6.3, March 2026) to compile your Swift business logic into native Android libraries. Write the UI in Kotlin/Compose.

### How it works
- Swift code compiles to native Android binaries (.so files)
- **swift-java** generates JNI bindings between Swift and Kotlin
- Your Android app calls Swift functions through these bindings
- All UI is native Kotlin/Compose

### What you'd share
- Business.swift model and enums (~700 lines)
- SearchEngine.swift filtering logic (~114 lines)
- DataManager.swift JSON loading (~178 lines)
- SunsetCalculator, ExchangeRateService, etc.
- Total: ~1,500 lines of shared Swift business logic

### What you'd still build natively
- All UI (5,333 lines) in Jetpack Compose
- All Android-specific services (maps, location, storage)
- ViewModels in Kotlin (bridging to Swift models)

### Realistic assessment
This is technically impressive but the JNI bridging adds complexity. For an app this size, the shared logic (~1,500 lines) may not justify the overhead of maintaining Swift-Java bindings. More valuable for large apps with complex business logic.

### Risk level: Medium
The Swift SDK is officially stable, but the tooling ecosystem is young. Debugging across Swift-JNI-Kotlin boundaries is non-trivial.

---

## Option D: Flutter or React Native (Not Recommended)

### Why not
- Requires a **complete rewrite** in Dart (Flutter) or JavaScript/TypeScript (React Native)
- Your iOS app would also need to be rewritten or you'd maintain two completely different codebases
- For a single-platform addition, the overhead isn't justified
- These frameworks shine when building **both platforms from scratch simultaneously**

---

## Can Claude Code Build This?

**Yes, absolutely.** Here's why this is realistic:

1. **Your app is well-documented.** The CLAUDE.md is essentially a complete spec. It would guide an Android build just as well as it guided the iOS build.

2. **The app is the right size.** At ~7,700 lines, this is within the sweet spot for AI-assisted development.

3. **The architecture is clean.** MVVM translates directly. The data layer is simple JSON. No complex backend integration.

4. **Jetpack Compose and SwiftUI are conceptual siblings.** The mental models are nearly identical -- declarative UI, state-driven, composable components.

5. **Your JSON data is platform-agnostic.** businesses.json, guides, areas -- all of it works as-is on Android.

### What a Claude Code Android build would look like

**If going with Option B (native Kotlin):**
- Create a new Android project (Kotlin + Compose + Material 3)
- Port the CLAUDE.md design system to a Compose theme
- Translate each SwiftUI view to Compose equivalents
- Integrate Google Maps SDK (replacing MapKit)
- Set up Room database (replacing SwiftData)
- Bundle the same JSON data files
- Same MVVM architecture, same screen flow

**If going with Option A (Skip):**
- Set up Skip in the existing Xcode project
- Audit each Swift file for Skip compatibility
- Replace SwiftData with a Skip-compatible alternative
- Add `#if SKIP` conditionals where needed
- Configure Android build and Google Maps
- Test and iterate on the transpiled output

---

## My Recommendation

### Start with Skip, but have a fallback plan.

1. **Phase 1: Skip evaluation (1-2 weeks)**
   - Set up Skip in the project
   - Test transpilation of core views
   - Identify what works and what breaks
   - Evaluate the quality of the transpiled Android output

2. **Phase 2: Decision point**
   - If Skip handles 80%+ cleanly --> proceed with Skip, fix the gaps
   - If Skip has too many issues --> pivot to native Kotlin/Compose rewrite

3. **Phase 3: Build and ship**
   - Either path, Claude Code can help build it
   - Target: feature-complete Android app matching iOS functionality

### Why this approach?
- Skip could save enormous time if it works well with your codebase
- If it doesn't, you've only lost 1-2 weeks of evaluation
- The native Kotlin path is always available as a reliable fallback
- Either way, your JSON data, architecture, and design system carry over

---

## Key Links

- [Swift SDK for Android (official)](https://www.swift.org/documentation/articles/swift-sdk-for-android-getting-started.html)
- [Skip - Swift to Kotlin transpiler](https://skip.tools)
- [SkipUI - SwiftUI for Android](https://github.com/skiptools/skip-ui)
- [Skip is now free and open source (Jan 2026)](https://skip.dev/blog/skip-is-free/)
- [Android Workgroup announcement](https://forums.swift.org/t/announcing-the-android-workgroup/80666)
- [Swift 6.3 Android SDK stabilization](https://www.swift.org/blog/swift-6.3-released/)
- [Jetpack Compose documentation](https://developer.android.com/compose)

---

## Important Caveat

This research reflects the state of things as of April 2026. The Swift-on-Android ecosystem is evolving rapidly. Skip in particular is shipping updates frequently. Before starting, check the latest Skip release notes and Swift Android SDK documentation for any changes.
