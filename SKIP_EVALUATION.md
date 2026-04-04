# Roatan Insider: Skip Evaluation & Android Migration Plan

**Date:** April 2026  
**Status:** Evaluation complete — ready for Phase 1

---

## Skip Compatibility Verdict

After auditing all 78 Swift files against Skip's documented capabilities, here's where things stand:

### Works Out of the Box (70% of codebase)

| Your Code | Skip Support | Notes |
|-----------|-------------|-------|
| TabView (5 tabs) | ✅ Full | Core navigation works |
| NavigationStack + NavigationLink | ✅ Full | Value-based navigation supported |
| .navigationDestination | ✅ Full | Type-based routing works |
| VStack/HStack/ZStack | ✅ Full | All layout primitives |
| ScrollView | ✅ Full | Vertical and horizontal |
| LazyVStack | ✅ High | No pinned headers (you don't use them) |
| LazyVGrid | ⚠️ Medium | Based on first GridItem only |
| Button, TextField, Picker | ✅ Full | Standard controls |
| Text, Label, Image | ✅ Full | Core display views |
| AsyncImage | ✅ Full | Backed by Coil on Android |
| .sheet / .fullScreenCover | ✅ Full | Modal presentation |
| .toolbar / ToolbarItem | ✅ Full | Navigation bar items |
| @State, @Binding | ✅ Full | Core state management |
| @Observable (10+ classes) | ✅ High | Via SkipModel |
| @Bindable | ✅ High | Via SkipModel |
| @Environment | ✅ Full | Dependency injection |
| @AppStorage | ✅ High | Maps to SharedPreferences |
| Custom ViewModifier | ✅ Full | PalmRefreshModifier works |
| @ViewBuilder | ✅ Full | Function builders |
| Codable / JSONDecoder | ✅ Full | Via SkipFoundation |
| URLSession | ✅ Full | Networking works |
| Bundle.main.url/data | ✅ Full | Bundled JSON loading |
| Color(hex:) init | ✅ Full | Custom color support |
| .clipShape (RoundedRectangle, Circle, Capsule) | ✅ Full | Shape clipping |
| .overlay, .background | ✅ Full | View layering |
| .opacity, .padding, .frame | ✅ Full | Standard modifiers |
| GeometryReader | ✅ High | .local and .global only |
| LinearGradient | ✅ Full | (SkeletonView shimmer) |
| .searchable | ✅ High | Search bar integration |
| .onAppear / .onDisappear / .task | ✅ Full | Lifecycle hooks |
| .refreshable | ✅ Full | Pull to refresh |
| async/await | ✅ Full | Concurrency basics |
| ForEach | ✅ Full | List iteration |
| Divider | ✅ Full | Visual separator |
| .alert / .confirmationDialog | ✅ Full | System dialogs |

### Needs Rework (25% of codebase)

| Your Code | Issue | Solution | Effort |
|-----------|-------|----------|--------|
| **MapKit (7 files)** | Not supported in SkipUI | Replace with `skip-gmaps` (GoogleMapView) | Medium |
| **SwiftData (4 files)** | Not supported | Replace with @AppStorage (favorites are just IDs) | Low |
| **CoreLocation** | CLLocationManager not supported | Replace with SkipDevice's LocationProvider | Low-Medium |
| **MKLocalSearch** | Apple Maps search API | Replace with Google Places API or skip | Medium |
| **SF Symbols (38 icons)** | Partial auto-mapping to Material Icons | Audit + manual mapping for unmapped ones | Low |
| **UITabBarAppearance** | UIKit bridge, not supported | Use Skip's TabView styling or `#if !SKIP` | Low |
| **UIImpactFeedbackGenerator** | UIKit haptics | `#if SKIP` Android HapticFeedback | Low |
| **UIImage(named:) validation** | UIKit image check | Platform-specific `#if SKIP` block | Low |
| **AVSpeechSynthesizer** | AVFoundation not available | `#if SKIP` Android TextToSpeech API | Low-Medium |
| **Timer.publish().autoconnect()** | Combine pattern, limited | Replace with SkipModel Combine subset or Task.sleep loop | Low |
| **Custom Triangle Shape** | Path-based custom shape | Test transpilation; may need `#if SKIP` | Low |

### Won't Work / Must Replace (5% of codebase)

| Your Code | Why | Replacement |
|-----------|-----|-------------|
| `#Predicate { }` macros | SwiftData-specific | Remove with SwiftData |
| `FetchDescriptor` | SwiftData-specific | Remove with SwiftData |
| `@Model` / `ModelContext` | SwiftData-specific | Remove with SwiftData |
| `MKMapItem.openInMaps()` | Apple Maps deep link | Google Maps intent on Android |
| `UIColor` trait collection | Adaptive colors via UIKit | Use SwiftUI Color directly |

---

## Project Restructuring Requirement

**This is the biggest structural change.** Skip requires SPM (Swift Package Manager) module structure, not a traditional `.xcodeproj`.

Your current structure:
```
RoatanInsider/
  RoatanInsider.xcodeproj
  RoatanInsider/
    Views/
    Models/
    Services/
    ...
```

Skip requires:
```
RoatanInsider/
  Package.swift              # SPM manifest with Skip plugin
  Sources/
    RoatanInsider/           # All your Swift code (shared)
      Views/
      Models/
      Services/
      ...
  Darwin/                    # iOS-only config
    RoatanInsider.xcconfig
    Assets.xcassets/
  Android/                   # Android-only config
    app/src/main/
      AndroidManifest.xml
      res/
```

This is a one-time migration. Your Swift code stays the same — it just moves into an SPM module.

---

## Detailed Migration Plan

### Phase 0: Setup (Day 1)

**Prerequisites:**
- [ ] macOS with latest Xcode installed
- [ ] Install Android Studio + Android emulator
- [ ] Install Skip: `brew install skiptools/skip/skip`
- [ ] Run `skip checkup` to verify environment
- [ ] Get a Google Maps API key (free tier: 28,000 map loads/month)

### Phase 1: Proof of Concept (Days 2-5)

**Goal:** Get a minimal version of the app running on Android emulator.

- [ ] Create new Skip project: `skip init --open-xcode RoatanInsiderSkip`
- [ ] Copy core data models: `Business.swift`, `Category.swift`, `Area.swift`
- [ ] Copy `businesses.json` into bundle resources
- [ ] Create simplified `DataManager` that loads JSON
- [ ] Build ONE screen: BusinessCard + simple list view
- [ ] Run on Android emulator — verify it renders correctly
- [ ] **Decision point:** If this works cleanly, proceed. If major issues, evaluate pivoting to native Kotlin.

### Phase 2: Core UI Migration (Days 6-15)

**Goal:** All 5 tabs rendering with basic functionality.

**Tab 1 — Home:**
- [ ] Migrate ContentView (TabView with 5 tabs)
- [ ] Migrate HomeView (hero section, featured, categories)
- [ ] Migrate HeroSection, FeaturedSection, CategoryGridSection
- [ ] Migrate InsiderPicksSection, QuickGuidesSection
- [ ] Migrate BusinessCard component
- [ ] Handle SF Symbol mapping for category icons

**Tab 2 — Explore:**
- [ ] Migrate ExploreView with search bar
- [ ] Migrate FilterBar (sheets for category/area/price filters)
- [ ] Migrate BusinessListView with LazyVGrid
- [ ] Wire up SearchEngine for filtering

**Tab 3 — Map (biggest change):**
- [ ] Add `skip-gmaps` dependency to Package.swift
- [ ] Rewrite MapTabView using GoogleMapView instead of MapKit Map
- [ ] Rewrite map annotations as GoogleMapView Markers
- [ ] Implement MapPopupCard for pin selection
- [ ] Replace MKLocalSearch with Google Places (or remove map search for v1)
- [ ] Configure Google Maps API key for Android

**Tab 4 — Tools:**
- [ ] Migrate CurrencyConverterView
- [ ] Migrate TipCalculatorView
- [ ] Migrate PhrasesView (speech: `#if SKIP` for Android TTS)

**Tab 5 — Saved:**
- [ ] Replace SwiftData FavoritesStore with @AppStorage-based storage
- [ ] Store favorite IDs as JSON-encoded array in UserDefaults/SharedPreferences
- [ ] Migrate SavedView and EmptyFavoritesView
- [ ] Wire up FavoriteButton across all views

### Phase 3: Detail & Navigation (Days 16-22)

- [ ] Migrate BusinessDetailView (hero image, info, insider tip)
- [ ] Migrate PhotoGallery (AsyncImage carousel)
- [ ] Migrate ContactActions — `#if SKIP` for Android intents (phone, WhatsApp, Maps)
- [ ] Migrate MiniMapView using skip-gmaps GoogleMapView
- [ ] Wire up all NavigationDestination routes
- [ ] Migrate guide views (CruiseDayGuide, AreaGuide, IslandEssentials)

### Phase 4: Services & Polish (Days 23-30)

- [ ] Migrate LocationManager → SkipDevice LocationProvider
- [ ] Wire up distance calculations in SearchEngine
- [ ] Migrate NetworkMonitor for connectivity detection
- [ ] Migrate ExchangeRateService (URLSession — should work as-is)
- [ ] Migrate RemoteDataService (Supabase fetch — URLSession based, should work)
- [ ] Replace UITabBarAppearance with Skip-compatible tab styling
- [ ] Replace UIKit haptics with `#if SKIP` Android haptic feedback
- [ ] Migrate AnimatedLaunchView / OnboardingView
- [ ] Dark mode testing and color verification

### Phase 5: Testing & Release (Days 31-40)

- [ ] Test every screen on Android emulator (Pixel 8 Pro, Galaxy S24)
- [ ] Test on a physical Android device
- [ ] Test bundled JSON loading and image display
- [ ] Test Supabase remote data updates
- [ ] Test favorites persistence (add, remove, persist across app restart)
- [ ] Test map functionality (pins, popup cards, navigation to detail)
- [ ] Test deep links and share functionality
- [ ] Performance profiling (scroll performance, map rendering)
- [ ] Fix any visual discrepancies between iOS and Android
- [ ] Run `skip export` to produce release AAB
- [ ] Create Google Play Store listing (screenshots, description)
- [ ] Submit to Google Play Store

---

## Risk Mitigation

| Risk | Mitigation |
|------|-----------|
| skip-gmaps too immature | Fall back to writing a native Android MapView wrapper in `#if SKIP` Kotlin |
| LazyVGrid layout differences | Use simpler List layout as fallback for Android |
| SF Symbol gaps | Pre-audit all 38 symbols against Skip's mapping table before starting |
| Build times slow | Skip caches builds; first build is slow, subsequent are fast |
| AsyncImage rendering differences | Test early in Phase 1 POC |
| `skip export` blocking bug in skip-gmaps | Monitor the GitHub issue; may be fixed before you reach Phase 5 |

---

## Fallback Plan

If Skip evaluation fails at the Phase 1 decision point, the fallback is a **native Kotlin + Jetpack Compose** build. The work done in Phase 0 (Android Studio setup, Google Maps API key, Google Play developer account) carries over. The codebase audit and design system documentation make a native build very achievable — just a different path to the same destination.

---

## What You Need Before Starting

1. **A Mac** (Skip requires macOS + Xcode)
2. **Android Studio installed** with an emulator configured
3. **Google Maps API key** (free at console.cloud.google.com)
4. **Google Play Developer account** ($25 one-time at play.google.com/console)
5. **~40 focused working days** (or equivalent spread over 2-3 months)

---

## Cost Summary

| Item | Cost |
|------|------|
| Skip framework | Free (open source) |
| Google Play Developer account | $25 (one-time) |
| Google Maps API | Free (28K loads/month free tier) |
| Android test device (optional) | $200-400 |
| **Total out-of-pocket** | **$25 - $425** |

Compare to Apple: $99/year just to maintain your iOS listing.
