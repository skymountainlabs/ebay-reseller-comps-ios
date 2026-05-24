# BUILD_NOTES.md — Phase 1: Xcode Scaffold + Image Search MVP

**Sub-agent:** sa-ebay-reseller-comps-ios-phase1-ios_engineer-b324bd
**Date:** 2026-05-24
**Branch:** subagent/sa-ebay-reseller-comps-ios-phase1-ios_engineer-b324bd

---

## 1. What Was Built

### Project scaffold
| File | Description |
|------|-------------|
| `eBayResellerComps/eBayResellerComps.xcodeproj/project.pbxproj` | Hand-authored Xcode project file. Bundle ID `com.skymountainlabs.ebayresellercomps`, iOS 17.0 deployment target, SwiftUI lifecycle, no third-party packages, `TARGETED_DEVICE_FAMILY = 1` (iPhone). |
| `eBayResellerComps/eBayResellerComps/Info.plist` | App info plist with `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription`, and placeholder keys `eBayClientID` / `eBayClientSecret`. |
| `eBayResellerComps/eBayResellerComps/Assets.xcassets/` | Asset catalog with AccentColor and AppIcon stubs. |
| `eBayResellerComps/eBayResellerComps/eBayResellerCompsApp.swift` | `@main` App entry point. Initialises `SearchHistoryService` as a `@StateObject` and injects it as an environment object. Calls `load()` on appear. |

### Models
| File | Description |
|------|-------------|
| `Models/ItemSummary.swift` | Codable, Identifiable struct with `itemId`, `title`, `price` (nested `Price` with `value`+`currency`), `condition: String?`. |
| `Models/PriceSummary.swift` | Plain struct: `condition`, `count`, `average`, `median`, `min`, `max` (all `Double`). No network dependency. |
| `Models/SearchRecord.swift` | Codable, Identifiable struct: `id UUID`, `query String`, `timestamp Date`, `imageThumbData Data?`. |

### Services
| File | Description |
|------|-------------|
| `Services/EBayAuthService.swift` | `@MainActor final class`. Reads `eBayClientID`/`eBayClientSecret` from `Bundle.main`. Base64-encodes `id:secret` for the `Authorization: Basic` header. POSTs `grant_type=client_credentials` to `https://api.ebay.com/identity/v1/oauth2/token`. Caches token in memory; re-fetches 60 s before expiry. No Keychain. |
| `Services/EBayBrowseService.swift` | `final class` (not actor-isolated). Two async methods: `searchByImage(imageData:)` POSTs base64 JPEG to `search_by_image`, returns top title. `search(query:conditions:)` GETs `item_summary/search` with `q=` and optional `filter=conditions:{...}`. Delegates auth to `EBayAuthService.shared`. Pure URLSession. |
| `Services/PriceAnalysisService.swift` | `struct`. No network. Groups `[ItemSummary]` by `condition`, filters out items with unparseable prices, computes average/median/min/max per group. Returns `[PriceSummary]` sorted alphabetically by condition. |
| `Services/SearchHistoryService.swift` | `@MainActor final class: ObservableObject`. Persists `[SearchRecord]` to `Documents/search_history.json` via `JSONEncoder`/`JSONDecoder`. Methods: `load()`, `save(_:)` (prepends), `clearAll()`. Atomic file write. |

### Views
| File | Description |
|------|-------------|
| `Views/HomeView.swift` | `NavigationStack` root. Camera/library button with loading overlay while `searchByImage` runs. Recent searches list (`ContentUnavailableView` when empty). Pushes `SearchConfirmView` via `navigationDestination`. SwiftUI Preview with two mock records. |
| `Views/ImagePickerView.swift` | Source-selection screen with "Take Photo" (UIImagePickerController `.camera`) and "Photo Library" (`.photoLibrary`) buttons. Wraps `UIImagePickerController` via `UIViewControllerRepresentable`. No AVCaptureSession. Cancel button. SwiftUI Preview. |
| `Views/SearchConfirmView.swift` | Thumbnail of picked image, editable `TextField` pre-filled with `suggestedQuery`, multi-select condition chips (NEW / USED / neither = Any), Search button that calls `EBayBrowseService.search`, saves `SearchRecord`, then pushes `PriceAnalysisView`. Loading and error states. SwiftUI Preview. |
| `Views/PriceAnalysisView.swift` | Receives `[ItemSummary]`, runs `PriceAnalysisService.analyze`. Renders one rounded-rect card per condition group (condition label, listing count, avg/median/min/max). `ContentUnavailableView` when no parseable prices. SwiftUI Preview with mock data. |

---

## 2. eBay Developer Registration Steps

The operator must register an app on eBay's developer portal before the app can make real API calls.

### Step 1 — Create an account
1. Go to [developer.ebay.com](https://developer.ebay.com) and sign in with (or create) an eBay account.
2. Accept the Developers Program User Agreement.

### Step 2 — Register an application
1. In the developer portal, click **My Account → Application Keys** (or navigate to the **Application Keys** section).
2. Click **Create an Application Key Set**.
3. Name: `eBayResellerComps` (or any descriptive name).
4. Platform: **Mobile** / iOS.
5. After creation, you will see:
   - **App ID (Client ID)** — in Sandbox and Production columns.
   - **Cert ID (Client Secret)** — for each environment.

### Step 3 — Paste credentials into Info.plist
Open `eBayResellerComps/eBayResellerComps/Info.plist` and replace the placeholder values:

```xml
<key>eBayClientID</key>
<string>YOUR_CLIENT_ID</string>        <!-- replace with App ID (Client ID) -->
<key>eBayClientSecret</key>
<string>YOUR_CLIENT_SECRET</string>    <!-- replace with Cert ID (Client Secret) -->
```

Use **Sandbox** credentials for development/testing and **Production** credentials before App Store submission.

### Step 4 — Start with Sandbox
- The `searchByImage` and `search` endpoints work with the same Base URL structure in Sandbox (`api.sandbox.ebay.com`). To test against Sandbox, change the base URLs in `EBayBrowseService.swift` and the token URL in `EBayAuthService.swift` from `api.ebay.com` to `api.sandbox.ebay.com`.
- Production credentials require eBay to review your app use case. Submit a request at **developer.ebay.com → My Account → Application Keys → Go Live**.

### Step 5 — searchByImage access
The Browse API `search_by_image` endpoint may require additional enablement. If the endpoint returns 403 or "access denied":
1. Contact eBay developer support via the portal.
2. Mention you are building a price-research app using Browse API for active listings.
3. Application-level (client_credentials) access is generally approved without partner status.

---

## 3. UNVERIFIED Items

**xcodebuild is not available in this Linux Docker container.** All Swift files were authored to be correct but could not be compiled. The operator must open the project in Xcode 15+ on a Mac and run the build (⌘B) to verify.

| File | Status |
|------|--------|
| `eBayResellerCompsApp.swift` | UNVERIFIED — not compiled |
| `Models/ItemSummary.swift` | UNVERIFIED — not compiled |
| `Models/PriceSummary.swift` | UNVERIFIED — not compiled |
| `Models/SearchRecord.swift` | UNVERIFIED — not compiled |
| `Services/EBayAuthService.swift` | UNVERIFIED — not compiled |
| `Services/EBayBrowseService.swift` | UNVERIFIED — not compiled |
| `Services/PriceAnalysisService.swift` | UNVERIFIED — not compiled |
| `Services/SearchHistoryService.swift` | UNVERIFIED — not compiled |
| `Views/HomeView.swift` | UNVERIFIED — not compiled |
| `Views/ImagePickerView.swift` | UNVERIFIED — not compiled |
| `Views/SearchConfirmView.swift` | UNVERIFIED — not compiled |
| `Views/PriceAnalysisView.swift` | UNVERIFIED — not compiled |
| `project.pbxproj` | UNVERIFIED — project file syntax hand-authored; open in Xcode to confirm it loads cleanly |

---

## 4. ASSUMPTION Log

**ASSUMPTION: `search_by_image` request body format.** eBay's documentation describes the body as `{"image": "<base64-encoded JPEG>"}`. This is implemented exactly as described. If the API requires a different field name or multipart encoding, `EBayBrowseService.searchByImage` will need adjustment. The response is decoded as `{"itemSummaries": [...]}`, consistent with other Browse API search endpoints.

**ASSUMPTION: Conditions filter format.** The Browse API `filter` parameter for conditions is implemented as `conditions:{NEW|USED}` (pipe-delimited inside braces). This matches the documented filter format for other Browse API filter fields. If eBay's conditions filter uses a different syntax (e.g., comma-delimited), `EBayBrowseService.search` will need adjustment.

**ASSUMPTION: `EBayAuthService` `@MainActor` isolation.** The work item specifies `@MainActor`-isolated. This means `EBayBrowseService` calls to `authService.validToken()` cross the main actor boundary via `await`. For Phase 1 with modest traffic this is acceptable; in a future phase, `EBayAuthService` could become a proper Swift `actor` to avoid main-thread contention.

**ASSUMPTION: `ItemSummary.condition` is optional.** The Browse API may omit the condition field on some listings. `condition: String?` handles this gracefully; `PriceAnalysisService` maps nil conditions to the group key "Unknown".

**ASSUMPTION: `ItemSummary.price.value` is a String-encoded decimal.** eBay's Browse API returns price as `{"value": "99.99", "currency": "USD"}`. `Double($0.price.value)` parses this; items with unparseable values are filtered out by `compactMap` in `PriceAnalysisService`.

**ASSUMPTION: Single-target iPhone app.** `TARGETED_DEVICE_FAMILY = 1` targets iPhone only. iPad is excluded. If iPad support is needed in a future phase, change to `1,2`.

**ASSUMPTION: No LaunchScreen storyboard.** `UILaunchScreen = {}` in Info.plist produces a plain white launch screen. This is acceptable for Phase 1.

**ASSUMPTION: Camera unavailability handling.** `UIImagePickerController.isSourceTypeAvailable(.camera)` is used to disable the camera button on simulators. On a real device the camera is always available. The library button is always enabled.

---

## 5. Known Gaps / Phase 2 Candidates

- **Sold-listing data.** Phase 1 shows active listing prices only. Sold/completed prices require either Marketplace Insights API access (apply via eBay developer portal) or a third-party data source. This was explicitly deferred per operator decision.
- **Sandbox vs. Production base URL switching.** Currently hard-coded to Production (`api.ebay.com`). A build-time flag (DEBUG / RELEASE) should select Sandbox vs. Production in a future phase.
- **Keychain-backed credential storage.** Credentials are read from Info.plist (plaintext in the binary). For production, move to Keychain or a server-side token proxy.
- **Pagination.** `EBayBrowseService.search` requests up to 50 results (eBay Browse API default page size). PriceAnalysisView shows all returned listings. Pagination was not in scope.
- **Image thumbnail display in history.** `SearchRecord.imageThumbData` is stored but `HomeView` does not render the thumbnail in the history list (was not in the wi-006 acceptance criteria). Can be added in Phase 2.
- **Sign in with Apple / user OAuth.** Explicitly deferred by operator; not in Phase 1.
- **Watchlist / save feature.** Explicitly dropped; no public eBay API supports it without Trading API complexity.
- **Marketplace Insights API.** Contingent on eBay partner approval; Phase 5 candidate per feasibility report.
- **Unit tests.** `PriceAnalysisService` is pure computation and an ideal first test target. No tests were in scope for Phase 1.

---

## For the Operator (Opening in Xcode)

1. Open `eBayResellerComps/eBayResellerComps.xcodeproj` in Xcode 15+.
2. Select your development team under **Signing & Capabilities** for the `eBayResellerComps` target.
3. Build (⌘B) to verify compilation.
4. Replace `YOUR_CLIENT_ID` and `YOUR_CLIENT_SECRET` in `Info.plist` with Sandbox credentials.
5. Run on a real device to test camera access; Simulator will disable the camera button.
