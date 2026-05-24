# eBay Reseller Comps iOS App — Feasibility Report

**Phase 0 | Date: 2026-05-24**

---

## 1. Brief Feasibility Summary

An iOS app that identifies items from photos and returns eBay price analytics is technically
buildable — but the app's core value proposition is blocked by a significant API access barrier.
eBay's sold/completed listings data is gated behind the Marketplace Insights API, which is
restricted to approved partners. The Finding API (which previously exposed `findCompletedItems`)
was decommissioned on February 5, 2025, and there is no open replacement. A new developer
cannot access sold listings through official eBay APIs without going through eBay's partner
approval process — a process with no guaranteed outcome and no published timeline.

The recommended path forward is to build the MVP against active listing data (Browse API,
available now, no special access required), apply immediately for Marketplace Insights API
access via eBay's Application Growth Check, and reframe the user-facing value prop as "market
price check" until partner access is granted. If eBay denies or ignores the access request, the
app can still deliver genuine value by analyzing the price distribution of currently active
listings — the same signal many resellers already use to price items. The sold-comps angle
becomes a Phase 2 enhancement, not a Phase 1 blocker.

---

## 2. eBay API Analysis

### OAuth 2.0 (Mobile Login)

eBay uses standard OAuth 2.0 authorization code grant for user-level API access. The flow for
a mobile app is:

- Register the app in the eBay Developer Portal (https://developer.ebay.com) and receive a
  Client ID and Client Secret.
- Define a RuName (Redirect URL Name) — for a native iOS app this maps to a custom URL scheme
  (e.g., `ebayresellercomps://oauth/callback`) or a Universal Link.
- Redirect the user to eBay's OAuth endpoint via `ASWebAuthenticationSession` (the iOS-standard
  secure browser). eBay shows its own consent page. User grants permissions.
- eBay redirects back with an authorization code. App exchanges the code for access + refresh
  tokens via a POST to `https://api.ebay.com/identity/v1/oauth2/token`.

Token lifetimes: access tokens expire in 2 hours; refresh tokens last 18 months. Refresh
tokens must be stored securely (iOS Keychain). eBay does not document explicit PKCE support,
but the Authorization Code flow via `ASWebAuthenticationSession` provides equivalent channel
security; PKCE should be included in the request as an additional defense-in-depth measure.

No special partner status is needed to implement OAuth login. This part of the app is
straightforward.

### Browse API (Active Listings)

Available to all registered eBay developers. No partner status required.

Capabilities:
- `search`: Keyword search across active eBay listings. Supports condition filter (New, Used,
  etc.), category, price range, buying options (fixed price / auction).
- `searchByImage`: POST a Base64-encoded image; eBay returns active listings matching the image.
  Requires an Application access token (not a user token).
- `getItem`: Full detail on a specific listing.
- `getItemsByItemGroup`: Retrieve item variations.

Condition filtering: The `filter=conditions:{NEW}` or `filter=conditions:{USED}` parameter
filters results. Condition values include: `NEW`, `LIKE_NEW`, `GOOD`, `VERY_GOOD`, `FAIR`,
`POOR`. Condition coverage varies by category.

Rate limits: Default is 5,000 API calls/day per application. Higher limits can be requested
through the developer portal.

Sandbox vs. production: Sandbox uses `api.sandbox.ebay.com` and requires sandbox credentials.
Sandbox data is synthetic and limited. Production access requires completing app registration
and complying with eBay API license terms.

**Critical limitation: Browse API returns only active (currently listed) items. It does not
return sold, completed, or expired listings.**

### Marketplace Insights API (Sold/Completed Listings) — The Gating Problem

This is the central risk for this app concept.

The Marketplace Insights API is the only official eBay API that exposes sold listing data
after the Finding API's February 5, 2025 decommission. It provides sold price history,
average sold prices, and sold volume for eBay items.

Access is **restricted to approved partners**. Multiple independent developers have applied
and reported being rejected or receiving no response. eBay's developer community posts
(2024–2025) consistently describe it as:

- "Limited to approved partners. Access can't be granted at this time."
- "Only available to high-end developers like Terapeak" (Terapeak is now eBay-owned).

To apply: Submit an Application Growth Check at
`https://developer.ebay.com/my/support/tickets?tab=app-check`. eBay's Developer Support team
reviews and decides. No published timeline, no guaranteed approval, no stated criteria.

**Bottom line for a new developer without partner status: sold listing data is inaccessible
through official eBay APIs as of May 2026. This must be treated as a hard constraint until
access is granted.**

### Condition Filtering

Available in Browse API for active listings. Filter parameter `conditions:{NEW}` or
`conditions:{USED}` works across categories. Some categories (e.g., trading cards, media)
use custom condition terminologies; the Metadata API (`getItemConditionPolicies`) can be
used to enumerate valid condition values per category.

### Saved Searches

No eBay API supports creating or managing "Saved Searches" in My eBay programmatically.
This feature exists in the eBay web UI but has no API equivalent.

Available workaround: The Trading API supports `AddToWatchList` (add specific items to a
user's watchlist) and `GetMyeBayBuying` (retrieve watchlist contents). Saving a search
query is not possible via API — only saving specific item listings.

Implication for the app: The "save search results to user's eBay account" requirement from
the brief cannot be fully satisfied. The closest equivalent is adding specific matched
listings to the user's eBay watchlist via `AddToWatchList`. The app can also save search
sessions locally (CoreData or UserDefaults) as an in-app history feature independent of
eBay.

---

## 3. Image Recognition Recommendation

### Recommended Approach: eBay Browse API searchByImage + Google Cloud Vision Web Detection

The recommended two-step pipeline:

1. **eBay searchByImage** — Send the user's photo directly to eBay as a Base64 image. eBay
   returns a ranked list of matching active eBay listings. This is purpose-built for this
   exact use case: identify an item from a photo and find it on eBay. The top result titles
   serve as the "product identification" output. No separate image identification API is
   needed for the happy path.

2. **Google Cloud Vision web detection (fallback/augment)** — If eBay's image search returns
   poor results (low confidence, wrong category), fall back to Google Cloud Vision's web
   detection feature to extract web entities and product labels. Feed those labels into a
   keyword search against the Browse API.

### Alternatives Evaluated

**Google Cloud Vision API (direct product search)**
- Product Search capability requires uploading a custom product catalog to Google. It searches
  within that catalog only — not against all eBay categories. Not useful here without
  maintaining a catalog mirror of eBay inventory.
- Label Detection ($1.50/1,000) + Web Detection ($3.50/1,000) are useful as a fallback to
  generate product keywords. App Store safe (direct API, not scraping).

**SerpAPI Google Lens endpoint**
- Capability: Highest-quality visual product identification (proxies actual Google Lens).
  Returns exact product matches, similar items, and product metadata.
- Pricing tiers:
  - Free: 250 searches/month
  - Starter: $25/month for 1,000 searches (~$0.025/search)
  - Developer: $75/month for 5,000 searches (~$0.015/search)
  - Production: $150/month for 15,000 searches (~$0.010/search)
- App Store risk: HIGH. SerpAPI works by scraping Google's search results. Apple's App Store
  review guidelines prohibit apps that facilitate scraping of websites or use APIs that violate
  a third party's terms of service. Google prohibits automated querying of its services. An
  app depending on SerpAPI for a core feature is at risk of rejection or post-launch removal.
  Additionally, SerpAPI is a vendor dependency — if Google blocks their scraping infrastructure,
  the app breaks with no fallback. Not recommended for a production App Store app.

**Amazon Rekognition**
- Strong for face recognition and scene analysis; Custom Labels for domain-specific objects
  requires training with your own labeled dataset. Not suitable for general open-category
  product identification without significant training data investment. Pricing starts at
  $0.001/image for image analysis (Custom Labels $0.012/image at low volume).

**Azure AI Vision / Custom Vision**
- Similar to Google Vision: strong for trained custom categories, limited for open-ended
  product identification. Requires custom model training for catalog-specific use. Pricing:
  free tier 5,000 transactions/month; $1/1,000 thereafter (standard tier).

**OpenAI GPT-4o mini (Vision)**
- Can analyze a product image and generate a natural language eBay search query (e.g.,
  "vintage Sony Walkman WM-2 cassette player"). Pricing approximately $0.15/million input
  tokens; a typical 512×512 image costs roughly $0.003–0.005 to analyze, making it
  competitive as an augmentation step.
- App Store safe. But adds latency and cost for a step eBay's own searchByImage handles more
  directly.

### Cost Estimates (Recommended Pipeline)

eBay searchByImage: free at all volumes (included in Browse API access, no per-call fee).

Google Cloud Vision web detection (fallback tier, not called on every request — estimated
usage at 30% fallback rate):
- At 100 total monthly searches: ~30 fallback calls — within free tier (1,000 free/month).
  Cost: $0.
- At 1,000 total monthly searches: ~300 fallback calls — within free tier. Cost: $0.
- At 10,000 total monthly searches: ~3,000 fallback calls. First 1,000 free; 2,000 billed at
  $3.50/1,000. Cost: ~$7/month for image step.

If Google Vision is called on every request (no smart fallback):
- At 100 searches/month: $0 (free tier covers first 1,000/month).
- At 1,000 searches/month: $0 (within free tier).
- At 10,000 searches/month: ~$31.50 (9,000 paid calls × $3.50/1,000).

### Capability Assessment

eBay's `searchByImage` is the strongest single-step option for this use case because it
directly maps product photos to eBay listings. Its main limitation is that results quality
varies by item category and image quality. Categories with visual ambiguity (e.g., generic
household items, loose clothing without distinctive logos) may return poor results. Google
Vision web detection fills that gap with web entity labels. This pipeline is App Store safe,
has no vendor lock-in to scraping intermediaries, and has near-zero incremental cost at
typical reseller usage volumes.

---

## 4. Recommended Architecture

### High-Level Structure

```
iOS App (SwiftUI + Swift Concurrency)
├── Views (SwiftUI)
│   ├── Authentication flow
│   ├── Home + search trigger
│   ├── Image capture / picker
│   ├── Search results + query confirmation
│   └── Price analysis summary
├── ViewModels (ObservableObject / @Observable)
│   └── One ViewModel per screen
├── Services (async/await)
│   ├── EBayAuthService        – OAuth token management
│   ├── EBayBrowseService      – Browse API calls (search, searchByImage)
│   ├── EBayTradingService     – Watchlist (AddToWatchList)
│   ├── VisionService          – Google Cloud Vision fallback
│   └── PriceAnalysisService   – Aggregation logic (avg, min, max, median)
├── Storage
│   ├── KeychainWrapper        – OAuth tokens
│   └── UserDefaults / JSON    – Search history (local, no server needed)
└── Networking
    └── HTTPClient             – URLSession-based, async/await, no Alamofire needed
```

### OAuth Handling

- `ASWebAuthenticationSession` handles the in-app browser flow. No WKWebView.
- Access token stored in iOS Keychain under a private key; refresh token also in Keychain.
- `EBayAuthService` manages silent token refresh using the refresh token before expiry.
- Client Secret is NOT embedded in the app binary; OAuth exchange that requires the secret
  should go through a thin backend proxy (see App Store risk section). Alternatively, the
  app can use PKCE-only flow if eBay adds public client support; as of current docs eBay
  appears to require a Client Secret for token exchange, which creates a mobile security risk.

### Image Upload Flow

1. User taps camera icon → `ImagePickerView` (PHPickerViewController wrapper).
2. Selected image → downsample to ≤1024px on longest side for bandwidth.
3. Convert to Base64 → POST to `https://api.ebay.com/buy/browse/v1/item_summary/search_by_image`.
4. Parse returned `itemSummaries` → extract title, price, condition, category.
5. Present top matches to user for confirmation ("Is this the item?").
6. User confirms or edits the derived search query.
7. Run keyword search via Browse API with condition and category filters.

### Networking Layer

Use Swift's native `URLSession` with `async/await`. No third-party networking library needed.
Pattern: a generic `HTTPClient` struct wraps `URLSession.data(for:)` and decodes JSON with
`JSONDecoder`. Each API service composes the client.

---

## 5. API Integration Plan

### Authentication Flow

- Scopes required:
  - `https://api.ebay.com/oauth/api_scope` (application scope, for Browse API calls)
  - `https://api.ebay.com/oauth/api_scope/buy.item.feed` (for user-level Browse calls)
  - `https://api.ebay.com/oauth/api_scope/buy.marketplace.insights` (for Marketplace
    Insights — only requestable after partner access is granted)
  - `https://api.ebay.com/oauth/api_scope/buy.offer.auction` (if watchlist use extends
    to auctions)
  - Legacy Trading API scope for `AddToWatchList` requires a separate token type or
    Auth'n'Auth token — check eBay's hybrid OAuth + Trading docs.

- OAuth endpoint: `https://signin.ebay.com/authorize?...`
- Token endpoint: `https://api.ebay.com/identity/v1/oauth2/token`

### Browse API Usage

- `searchByImage`: POST `https://api.ebay.com/buy/browse/v1/item_summary/search_by_image`
  Body: `{"image": "<base64>"}`; Query params: `limit=20`, `filter=conditions:{NEW|USED}`
- `search`: GET `https://api.ebay.com/buy/browse/v1/item_summary/search`
  Query: `q=<keyword>&filter=conditions:{NEW}&limit=50`
- Condition filter syntax: `filter=conditions:{NEW}` or `filter=conditions:{USED}` or
  omit for both. Multiple conditions: `filter=conditions:{NEW|USED}`.

### Rate Limits and Error Handling

- Default: 5,000 calls/day application-level. Monitor via Analytics API `getRateLimits`.
- HTTP 429 (rate limit): Implement exponential backoff with jitter; surface a user-friendly
  message.
- HTTP 400 on searchByImage with large images: Pre-compress images before sending.
- Token expiry (HTTP 401): Transparently refresh via refresh token; retry the original call
  once.

### Marketplace Insights API (When Access Granted)

- Endpoint: `https://api.ebay.com/buy/marketplace_insights/v1_beta/item_sales/search`
- Query: `q=<keyword>&filter=lastSoldDate:[<start>..<end>]&limit=200`
- Date filter supports ISO 8601 ranges; for 90-day window use `lastSoldDate:[2026-02-24..2026-05-24]`
- Response includes `soldPrice`, `lastSoldDate`, `condition`, `itemId`.
- This endpoint is the path to true sold-comps functionality; build the data model to handle
  it even if not activated in Phase 1.

---

## 6. Data Model

Swift type sketches (not runnable implementation code):

```
// OAuth
OAuthTokens {
    accessToken: String         // stored in Keychain
    refreshToken: String        // stored in Keychain
    accessTokenExpiry: Date
    refreshTokenExpiry: Date
    grantedScopes: [String]
}

// Search
ItemSearchQuery {
    id: UUID
    rawSearchText: String
    sourceImageData: Data?      // transient, not persisted to disk
    categoryId: String?
    condition: ConditionFilter   // .new | .used | .all
    createdAt: Date
}

enum ConditionFilter { all, new, used }

// Listing (Browse API active listing result)
EBayListing {
    itemId: String
    title: String
    price: MoneyAmount
    condition: String           // raw eBay condition string
    conditionId: Int
    listingURL: URL
    thumbnailURL: URL?
    buyingOptions: [String]     // ["FIXED_PRICE"] or ["AUCTION"]
    endDate: Date?
    categoryId: String
    categoryName: String
}

MoneyAmount {
    value: Decimal
    currency: String            // ISO 4217, e.g. "USD"
}

// Analytics Summary
ConditionPriceSummary {
    condition: ConditionFilter
    count: Int
    averagePrice: MoneyAmount
    medianPrice: MoneyAmount
    minPrice: MoneyAmount
    maxPrice: MoneyAmount
}

// A complete search session
SearchSession {
    id: UUID
    query: ItemSearchQuery
    listings: [EBayListing]     // raw active listings from Browse API
    priceSummary: [ConditionPriceSummary]
    dataSource: DataSource      // .activeListings | .soldComps (when MI API available)
    completedAt: Date
}

enum DataSource { activeListings, soldComps }

// Sold listing (Marketplace Insights API — future)
SoldListing {
    itemId: String
    title: String
    soldPrice: MoneyAmount
    soldDate: Date
    condition: String
    conditionId: Int
    listingURL: URL
}
```

Keychain handling: Use Apple's Security framework directly (`SecItemAdd`, `SecItemCopyMatching`)
or a thin wrapper. Store `OAuthTokens` as JSON data under a private Keychain key with
`kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly` protection class. Never store tokens in
UserDefaults or NSUserActivity.

---

## 7. SwiftUI Screen List

- **LoginView** — eBay OAuth login. Displays eBay branding, "Connect with eBay" button.
  Triggers `ASWebAuthenticationSession`. Skipped on subsequent launches if a valid token
  exists in Keychain.

- **HomeView** — Entry point after login. Camera/photo button, recent searches list, sign-out
  option. Checks token validity on appear; prompts re-auth if refresh token expired.

- **ImagePickerView** — System photo picker (`PHPickerViewController`) and camera option
  (`UIImagePickerController`). Crops/downsamples selected image before forwarding.

- **SearchConfirmView** — Shows the image plus the eBay search query derived from
  `searchByImage` results. User can edit the query text or select a different top match
  before committing. This is the "confirm or correct" step.

- **PriceAnalysisView** — Main results screen. Shows two cards:
  - New: X listings, avg $Y, range $A–$B
  - Used: X listings, avg $Y, range $A–$B
  Includes a note on data source ("Based on currently active eBay listings" or "Based on
  sold listings from last 90 days"). Offers "Save to Watchlist" to add top matching listings
  via `AddToWatchList`.

- **HistoryView** — List of previous search sessions stored locally. Tap to reload a past
  analysis. Accessible from HomeView.

Total: 6 screens for MVP. No account settings, no listing creation, no messaging.

---

## 8. MVP Build Plan

Each phase below is sized to fit a single sub-agent project run (estimated 1–2 hours of
implementation work). Phases depend on the operator's review and decision after Phase 0.

**Phase 1 — Project scaffold + OAuth**
- Create Xcode project (SwiftUI, iOS 17+)
- Configure eBay Developer app credentials (sandbox)
- Implement `EBayAuthService` with `ASWebAuthenticationSession`
- Keychain token storage (`OAuthTokens`)
- LoginView + HomeView stub
- Deliverable: User can log in with eBay sandbox account; token persists across launches.

**Phase 2 — Image search + query confirmation**
- `ImagePickerView` (camera + library)
- Image downsampling + Base64 encoding
- `EBayBrowseService.searchByImage()` integration
- `SearchConfirmView` with editable query
- Deliverable: User can take/upload a photo and see a derived eBay search query.

**Phase 3 — Active listing price analysis**
- `EBayBrowseService.search()` with condition filter
- `PriceAnalysisService` aggregation (avg, median, min, max per condition)
- `PriceAnalysisView` summary cards
- Deliverable: User sees price distribution for New and Used active listings.

**Phase 4 — Local history + watchlist**
- `HistoryView` with `SearchSession` persistence (JSON file in app's Documents directory)
- `EBayTradingService.addToWatchList()` for top matched listings
- Error handling, loading states, empty states throughout
- Deliverable: History persists between sessions; user can save listings to eBay watchlist.

**Phase 5 — Marketplace Insights integration (contingent on API access)**
- Only after eBay grants Marketplace Insights API scope
- Swap `EBayBrowseService.search()` with `MarketplaceInsightsService.searchSoldListings()`
- 90-day date window filter
- Update `PriceAnalysisView` to show "sold" label and use `SoldListing` data model
- Deliverable: True sold-comps analytics replacing active listing analysis.

**Phase 6 — App Store prep**
- Privacy policy URL (required for App Store)
- App Store screenshots (iPhone 6.5" + iPad if supporting iPad)
- App Review Notes explaining OAuth and camera usage
- TestFlight beta build
- Deliverable: App ready for external beta and App Store submission.

---

## 9. App Store Risk Register

**Risk 1: Marketplace Insights API access denied (HIGH)**
- Description: eBay's sold-comps API is gated behind partner approval. Without access, the
  app's primary value proposition cannot be delivered.
- Mitigation: Apply for access via Application Growth Check immediately after Phase 1.
  Build Phase 1–4 against active listings as a viable fallback product. Reframe UI as
  "active market price check" until sold-comps access is granted. If eBay denies access
  permanently, evaluate whether active listing analysis satisfies enough reseller use cases
  to ship the product.

**Risk 2: App Store rejection — scraping-dependent APIs (HIGH if SerpAPI used)**
- Description: APIs that scrape third-party sites (SerpAPI Google Lens, Apify eBay scrapers)
  violate the terms of service of those sites. Apple's App Store Review Guidelines prohibit
  apps that facilitate or depend on such services for core functionality. Rejection probability
  is high if a scraping proxy is the only image identification mechanism.
- Mitigation: Use only direct APIs (eBay Browse API searchByImage, Google Cloud Vision)
  for production builds. SerpAPI is excluded from the recommended architecture.

**Risk 3: Client Secret exposure in mobile binary (HIGH)**
- Description: eBay's token exchange endpoint currently requires a Client Secret. Embedding
  the secret in the iOS binary exposes it to extraction. This is a standard mobile OAuth
  security problem.
- Mitigation: Route the token exchange (authorization code → access token) through a
  lightweight server-side endpoint (e.g., a Cloudflare Worker or AWS Lambda). The secret
  lives server-side only. The mobile app sends the authorization code to the proxy, which
  exchanges it and returns the tokens. Alternatively, if eBay adds support for public clients
  (PKCE-only, no secret), this risk is eliminated.

**Risk 4: Sign in with Apple requirement (MEDIUM)**
- Description: Apple requires apps that offer third-party sign-in to also offer Sign in with
  Apple. eBay login is a third-party sign-in; this may trigger the requirement under App
  Store Review Guideline 4.8.
- Mitigation: Review the exact scope of Guideline 4.8. The guideline applies when "third-
  party sign-in services" are offered primarily for account creation/management within the
  app. If eBay login is used solely to access the user's existing eBay account (not to
  create an app-specific account), the guideline may not apply. Confirm with a pre-submission
  review inquiry to App Review. Budget time for adding Sign in with Apple as a fallback if
  App Review rejects the initial build.

**Risk 5: eBay Brand and Logo Usage (MEDIUM)**
- Description: Using eBay's name and logo requires compliance with eBay Brand Guidelines.
  Unauthorized usage can trigger a DMCA takedown of the app or App Store listing.
- Mitigation: Review eBay's Brand Center guidelines. Use text references ("connects to eBay")
  rather than logo graphics unless eBay's guidelines explicitly permit usage for API-based
  apps. Avoid implying eBay endorsement.

**Risk 6: Image privacy — user photos (LOW)**
- Description: App captures photos that may contain personal information (faces, locations,
  private property). If photos are uploaded to any server, this triggers App Store privacy
  label requirements and may require a privacy policy.
- Mitigation: Photos are sent only to eBay's API endpoint and Google Vision (if fallback
  is triggered). Do not store images server-side. Privacy policy must disclose API-level
  image transmission. In the App Store privacy nutrition labels, mark photos as
  "Data Used to provide the app's primary functionality."

**Risk 7: Camera and Photo Library permissions (LOW)**
- Description: Missing or vague permission strings trigger App Store rejection.
- Mitigation: Add `NSCameraUsageDescription` and `NSPhotoLibraryUsageDescription` to
  Info.plist with clear, specific descriptions ("To photograph items for eBay price lookup").

**Risk 8: eBay API rate limits under production load (LOW)**
- Description: Default 5,000 calls/day is sufficient for early beta but may throttle a
  popular app.
- Mitigation: Apply for a higher rate limit through eBay Developer Portal when approaching
  the threshold. Implement client-side caching of search results (TTL: 1 hour) to reduce
  redundant API calls.

---

## 10. Honest Open Questions

1. **Will eBay approve Marketplace Insights API access?** The Application Growth Check
   process has no published criteria, timeline, or success rate. Multiple independent
   developers have been rejected or ignored. This is an operational unknown that cannot be
   resolved through technical research. The operator should engage eBay business development
   directly to assess access likelihood before Phase 5 investment.

2. **Does eBay's searchByImage work reliably across all item categories?** eBay's image
   search was initially designed for fashion and electronics. Performance on collectibles,
   antiques, handmade items, and loose parts may be inconsistent. This needs empirical
   validation with a developer account — unverifiable in this research phase.

3. **Does eBay support PKCE for public clients (no client secret)?** eBay's developer docs
   describe the standard Authorization Code flow with a client secret. PKCE-only flows for
   mobile (RFC 7636 / OAuth 2.1) are not explicitly documented on eBay's current developer
   portal. This directly affects the Client Secret exposure risk. Needs verification with a
   test app registration.

4. **Does App Store Guideline 4.8 (Sign in with Apple) apply to eBay OAuth login?** This
   depends on how App Review interprets "third-party sign-in." The answer materially affects
   the authentication architecture. Should be confirmed via an App Review inquiry before
   finalizing Phase 1 implementation.

5. **What is the Google Cloud Vision web detection quality for non-branded or generic items?**
   The fallback image identification path relies on web detection generating useful eBay
   search terms. For truly generic items (a plain screw, a common houseplant pot) this may
   return unhelpfully broad labels. A validation experiment with a sample of diverse reseller
   item types is needed.

6. **Is a backend proxy required, and if so, what infrastructure?** The Client Secret
   exposure risk recommends a server-side token exchange proxy. The operator should decide
   whether to use serverless (Cloudflare Worker, AWS Lambda) or accept the risk of embedding
   the secret while in early beta. This architectural decision affects Phase 1 scope.

7. **What does "save search to eBay account" mean for the operator's product vision?**
   Research confirms no API exists for saving eBay searches programmatically. The app can
   save locally, or add specific listings to the watchlist. If saving searches to eBay
   account is a hard requirement, the feature cannot be built and the operator should be
   informed before Phase 1 begins.
