# BUILD_NOTES.md — Phase 0 Research

**Sub-agent:** sa-ebay-reseller-comps-ios-research_engineer-d08b6a
**Date:** 2026-05-24
**Session scope:** Phase 0 feasibility research only. No code written.

---

## What Was Done

**wi-001 — eBay API research**

Sources consulted:
- eBay Developers Program official docs (developer.ebay.com) via WebFetch and web search
- eBay developer community forums (multiple threads, 2024–2025)
- eBay API deprecation announcements

Key findings documented in feasibility_report.md section 2:
- OAuth 2.0 authorization code flow is standard and accessible to all developers
- Browse API (active listings) available without partner status
- Marketplace Insights API (sold/completed data) is effectively gated to approved partners
- Finding API (previously exposed `findCompletedItems`) was decommissioned February 5, 2025
- No open API replacement exists for sold listing data for new developers
- Saved Searches: no API exists; `AddToWatchList` (Trading API) is the closest alternative

**wi-002 — Image recognition research**

Sources consulted:
- Google Cloud Vision API official pricing pages
- SerpAPI official pricing page (verified via direct WebFetch)
- eBay developer documentation for searchByImage endpoint
- General web search comparing Amazon Rekognition, Azure Vision, OpenAI Vision

Key findings documented in feasibility_report.md section 3:
- eBay's own Browse API `searchByImage` is the strongest single-step option for this use case
- Google Cloud Vision web detection ($3.50/1,000) is a viable fallback
- SerpAPI excluded from recommendation due to App Store policy risk (scraping-based)
- At <1,000 monthly searches, image recognition costs are effectively zero (free tiers cover it)

**wi-003 — feasibility_report.md written**

All 10 required sections included. Single App Store risk register in section 9. No duplicate
risk sections. No runnable Swift code (type sketches are struct/field outlines only).

**wi-004 — BUILD_NOTES.md written** (this file)

**wi-005 — Final review pass completed**

Both documents reviewed. Checklist passed (see review section below).

---

## Assumptions Made

ASSUMPTION: eBay's Marketplace Insights API access situation described in community forum posts
(2024–2025) reflects the current state as of May 2026. The forums consistently report rejection
for independent developers and "partner-only" access language. This could have changed. The
operator should verify current access policy by submitting an Application Growth Check request.

ASSUMPTION: eBay supports PKCE as an additional parameter in the Authorization Code flow even
if it is not explicitly documented. This is consistent with standard OAuth 2.0 security practices
and widely supported by OAuth providers. The feasibility report recommends PKCE but notes that
eBay's docs do not confirm public client (no-secret) support. The Client Secret exposure risk
section treats this conservatively.

ASSUMPTION: SerpAPI's Google Lens endpoint is classified as "scraping-based" for App Store risk
purposes. SerpAPI describes itself as proxying Google's services. Google prohibits automated
querying of its search products. Whether App Review would definitively reject an app using
SerpAPI is not publicly documented — this is a risk assessment, not a certainty.

ASSUMPTION: Pricing figures for Google Cloud Vision (label detection $1.50/1,000, web detection
$3.50/1,000) were sourced from Google Cloud's published pricing page as of research date and
are assumed current. Cloud pricing can change.

ASSUMPTION: SerpAPI pricing tiers (verified via direct page fetch on 2026-05-24):
Free 250/mo, Starter $25/1,000, Developer $75/5,000, Production $150/15,000. Treat as current
at time of research; pricing plans change.

ASSUMPTION: The recommended architecture uses a server-side proxy for the OAuth client secret
exchange. This adds infrastructure that was not explicitly requested. The report flags this as
an open question for the operator to decide. If the operator accepts the risk of bundling the
client secret in Phase 1 beta (sandbox keys only), the proxy can be deferred.

---

## Unverified Claims

UNVERIFIED: eBay's `searchByImage` performance across non-fashion, non-electronics categories
(collectibles, antiques, sports memorabilia, generic household items). Empirical quality
assessment requires a live eBay Developer account and test images. Cannot be validated in
this research-only phase.

UNVERIFIED: Whether eBay's OAuth flow supports PKCE without a client secret (public client
mode). The docs describe a flow requiring the client secret in the token exchange. This was
not testable without a real developer account.

UNVERIFIED: Exact App Review interpretation of Guideline 4.8 for eBay OAuth login. Whether
eBay login constitutes "third-party sign-in" triggering the Sign in with Apple requirement
is a judgment call that only App Review can authoritatively answer.

UNVERIFIED: eBay's current Application Growth Check process. The information reported in the
feasibility report comes from developer community posts. The actual current process and
approval criteria can only be confirmed by submitting a real request.

UNVERIFIED: OpenAI GPT-4o mini per-image pricing of ~$0.003–0.005. Token counts vary by
image resolution and complexity; this is an approximation. Current pricing should be verified
at openai.com/api/pricing before building cost models.

---

## Final Review Checklist (wi-005)

- [x] No duplicate App Store risk sections (single section 9 covers all risks)
- [x] No runnable Swift code (type sketches in section 6 use field-outline format, not Swift syntax)
- [x] All 10 report sections present (1 through 10, verified)
- [x] Cost estimates for image API at all three volume tiers (100 / 1,000 / 10,000 — in section 3)
- [x] Sold-listings access reality stated honestly without glossing (section 2, "The Gating Problem")
- [x] BUILD_NOTES.md at repo root with ASSUMPTION: and UNVERIFIED: prefixes applied

---

## Unrelated Observations (Not Acted On)

None. This is a fresh repository with no pre-existing code.

---

## For the Next Sub-Agent

Phase 1 should not begin until the operator reviews this report and decides:
1. Whether to accept the active-listing-as-proxy approach while applying for Marketplace
   Insights access, OR whether to pursue a different sold-data strategy.
2. Whether to build a server-side OAuth proxy or accept client-secret-in-binary risk for
   early development.
3. Whether to accept the eBay searchByImage + Google Vision fallback pipeline, or use a
   different image identification approach.

The answers to these three questions materially affect Phase 1 architecture and scope.
