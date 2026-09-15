# M4 Family — Complete Manual QA Test Case Document

**Application:** M4 Family (Flutter mobile app — Android / iOS)
**Package ID:** `com.m4family.m4_mobile` · **App label:** M4 Family · **Version:** 1.0.0+1
**Backend:** `https://api.mym4family.com` (overridable via `.env` → `API_URL`)
**Document version:** 1.0 · **Prepared:** 2026-09-13
**Scope:** All 4 portals (Guest, Customer, Channel Partner, Investor) · ~190 routes · ~127 screens

---

## 1. How to use this document

### 1.1 Column legend

| Column | Meaning |
|---|---|
| **TC ID** | Unique test case identifier. Prefix = module. |
| **Test Scenario** | What is being verified. |
| **Pre-condition** | State the app/user must be in before step 1. |
| **Steps** | Exact actions, in order. |
| **Expected Result** | Observable, verifiable outcome. |
| **Pri** | P1 = Critical (blocker/smoke), P2 = Major, P3 = Minor/cosmetic. |

### 1.2 Result codes to use while executing

`PASS` · `FAIL` · `BLOCKED` · `NA` (not applicable to this build/device) · `NT` (not tested)

### 1.3 Module prefixes

| Prefix | Module |
|---|---|
| `GEN` | General / cross-cutting (launch, theme, fonts, network, navigation) |
| `AUTH` | Authentication, OTP, role gating, session |
| `GST` | Guest portal |
| `CUS` | Customer portal |
| `CP` | Channel Partner portal |
| `INV` | Investor portal |
| `BOOK` | Booking & payment flows |
| `SUP` | Support, tickets, logs |
| `CON` | Content hub, media, events, blog, CMS pages |
| `SRCH` | Search |
| `CV` | Custom Views / personalisation |
| `VAL` | Form validation matrix |
| `API` | API / error-state matrix |
| `NFR` | Non-functional (performance, security, compatibility, a11y) |

### 1.4 Test environment matrix

| Item | Values to cover |
|---|---|
| OS | Android 10, 12, 13, 14, 15 · iOS 15, 16, 17, 18 |
| Screen widths | 320 dp (small), 360 dp (standard), 411 dp, tablet 600 dp+ |
| Orientation | Portrait (primary), Landscape (support/matrix screens) |
| Device font size | System smallest, default, largest (app clamps text scale to **0.85x – 1.5x**) |
| Device theme | Light **and** Dark (app is light-only — it must NOT follow the device) |
| Network | 4G/5G, Wi-Fi, throttled 2G, Airplane mode (offline), server cold-start |
| Build types | Debug and Release (release must show no verbose network logs and no dev-OTP box) |

### 1.5 Test data (recommended)

| Role | Identifier | Credential | Entry point |
|---|---|---|---|
| Customer | Registered WhatsApp mobile (10 digits) | 6-digit OTP | `/login` → CONTINUE WITH PHONE |
| Channel Partner | Registered CP mobile | Password | `/auth/cp/login` |
| Investor | Registered e-mail | Password | `/investor/login` |
| Guest | — | — | BROWSE AS GUEST |
| Negative data | Unregistered mobile, wrong OTP, CP number used on the customer gateway, investor number used on the customer gateway | — | Role-gating cases |

---

## 2. GEN — General / cross-cutting

### 2.1 App launch & splash

| TC ID | Test Scenario | Pre-condition | Steps | Expected Result | Pri |
|---|---|---|---|---|---|
| GEN-001 | App installs and launches | APK/IPA installed | 1. Tap the M4 Family icon | App opens; native splash (black) then onboarding splash; no crash and no ANR | P1 |
| GEN-002 | Onboarding splash animation | Fresh cold start | 1. Launch the app<br>2. Observe the first screen | Deep-green (`#0C312B`) screen, white M4 logo fades in within ~350 ms, auto-navigates to `/home` after ~900 ms | P1 |
| GEN-003 | Cold start with NO stored session | App data cleared | 1. Launch app<br>2. Wait for onboarding to finish | Lands on the **Guest** shell (Home tab); no forced login | P1 |
| GEN-004 | Cold start WITH stored session | Previously logged in, app killed | 1. Launch app | Black splash with white logo + spinner while the session resolves, then the correct portal — **no guest-shell flash** in between | P1 |
| GEN-005 | Portal resolution — CP | Stored token for a CP account | 1. Cold start | Channel Partner shell opens (5 tabs) | P1 |
| GEN-006 | Portal resolution — Investor | Stored token for an investor account | 1. Cold start | Investor shell opens (4 tabs) | P1 |
| GEN-007 | Portal resolution — Customer | Stored token for a customer account | 1. Cold start | Customer shell opens (Home / Projects / Support / Profile) | P1 |
| GEN-008 | Unresolvable account must not default to Customer | Token valid but `/me` returns a body with no `id` and no `role` | 1. Cold start | App holds the splash or restores the cached profile; it must **NOT** silently open the Customer portal | P1 |
| GEN-009 | No colour flash between splashes | Stored session exists | 1. Cold start | No white/coloured flash between onboarding and splash; both dark with white logo | P3 |
| GEN-010 | App icon & label | — | 1. Check the launcher | M4 adaptive icon on a white background; label reads "M4 Family" | P3 |

### 2.2 Theme & typography

| TC ID | Test Scenario | Pre-condition | Steps | Expected Result | Pri |
|---|---|---|---|---|---|
| GEN-011 | App ignores device dark mode | Device set to system **Dark** | 1. Launch the app<br>2. Browse Home, Projects, About, Profile | App renders its own light M4 theme everywhere; it never switches to an OS dark theme | P1 |
| GEN-012 | Showcase vs info surfaces | Guest portal | 1. Open Home and Properties tabs<br>2. Open About / Careers / Contact | Home & Properties = deep-green showcase, white typography; About/Careers/Contact = cream, green typography | P2 |
| GEN-013 | Nav pill follows the active surface | Guest portal | 1. Switch between Home and About | The pill re-colours with the tab surface — no mismatched band around it | P2 |
| GEN-014 | Font scale — smallest | Device font = smallest | 1. Open Home, Projects, Support, Profile | Text never smaller than 0.85x of the design size; layout intact | P2 |
| GEN-015 | Font scale — largest | Device font = largest | 1. Open Home, Project Detail, Support cards, About milestone chips, the date/time wheel | Scale capped at 1.5x; **no** overflow stripes in debug and no clipped text in release | P1 |
| GEN-016 | Font scale on a 320 dp screen | Small device, font = largest | 1. Walk every main tab of all four portals | No horizontal overflow, no clipped labels, every CTA reachable | P1 |
| GEN-017 | Typography consistency | — | 1. Compare headings across About, Project Detail, Profile | Serif display headings and sans body font are consistent across screens | P3 |

### 2.3 Navigation, drawer & back behaviour

| TC ID | Test Scenario | Pre-condition | Steps | Expected Result | Pri |
|---|---|---|---|---|---|
| GEN-018 | Side-menu button identical everywhere | Any portal | 1. Open several screens in each portal and compare the menu button | Same button everywhere: transparent 56x36 tap target, centred hamburger glyph size 24; white on green surfaces, forest-green on cream | P2 |
| GEN-019 | Side-menu opens the shell drawer | On a nested tab screen | 1. Tap the side-menu button | The full-height shell drawer opens and draws over the nav pill — not a short partial drawer | P1 |
| GEN-020 | Drawer hides the nav pill | Guest portal | 1. Open the drawer | The floating bottom nav pill is hidden while the drawer is open | P3 |
| GEN-021 | Swipe changes tabs | Any portal shell | 1. Fling horizontally on the content area | Tab changes; the bottom bar highlights the same tab (one source of truth) | P2 |
| GEN-022 | Swipe does not wrap past the ends | Guest Home (first tab) | 1. Fling right on the first tab<br>2. Go to the last tab and fling left | Stays on the first/last tab; no crash, no blank screen | P2 |
| GEN-023 | Back from a non-home bottom tab | Customer portal, Projects tab | 1. Press system Back | Returns to the Home tab | P1 |
| GEN-024 | Back from a sidebar-opened screen | Customer: Profile → MY CUSTOM VIEWS | 1. Press system Back | Returns to **Profile** (its opener), not the Dashboard | P1 |
| GEN-025 | Back from Home exits | Customer portal, Home tab | 1. Press system Back | App exits normally; it does not loop inside the app | P2 |
| GEN-026 | Guest drawer EXIT APP | Guest portal | 1. Drawer → EXIT APP<br>2. Tap YES | Confirmation dialog appears first; app closes only on YES | P2 |
| GEN-027 | Keyboard hides the floating nav | Any shell screen with a text field | 1. Tap a text field | Nav pill hides and its reserved space is returned to the content — no dead gap above the keyboard | P2 |
| GEN-028 | Content clears the floating nav | Any long list | 1. Scroll to the very bottom | The last card rests **above** the nav pill, never hidden behind it | P2 |
| GEN-029 | Route integrity | — | 1. Open every menu entry and tile in all four portals | No route errors; every entry lands on a real screen (not an unintended "Coming Soon" placeholder) | P1 |
| GEN-030 | Double-tap protection on submit | Any submit form | 1. Double-tap a submit button quickly | One request only; the button shows a loading state and is disabled while in flight | P2 |
| GEN-031 | Rotate device mid-screen | Any list screen | 1. Rotate to landscape and back | No crash; state (scroll position, entered text) is preserved | P2 |
| GEN-032 | Background / foreground | Any screen | 1. Send the app to background for 2 min<br>2. Reopen it | Returns to the same screen with data intact; no forced re-login and no crash | P1 |

### 2.4 Connectivity & error states

| TC ID | Test Scenario | Pre-condition | Steps | Expected Result | Pri |
|---|---|---|---|---|---|
| GEN-033 | Offline — listing screens | Airplane mode ON | 1. Open Projects / Communities / Content Hub | A readable message such as "No internet connection. Please check your network and try again." plus a RETRY affordance — never a raw `DioException` dump | P1 |
| GEN-034 | Offline — form submit | Airplane mode ON | 1. Fill any inquiry form and submit | Friendly offline message; the form keeps the entered values so the user can retry | P1 |
| GEN-035 | Slow server / cold start | Throttle the network heavily | 1. Open the Projects list | Shows "TAKING LONGER THAN USUAL" / "The server may be waking up. Please try again." with RETRY; it must not hang forever | P2 |
| GEN-036 | Recovery after reconnect | Was offline and showed an error | 1. Turn the network back on<br>2. Tap RETRY | Data loads correctly without restarting the app | P1 |
| GEN-037 | Session expiry (401) | Token invalidated server-side | 1. Trigger any authenticated call | "Your session has expired. Please sign in again." and the user is not left on a broken screen | P1 |
| GEN-038 | Network blip must not log the user out | Logged in, token still valid | 1. Turn off the network<br>2. Cold start the app | The cached profile is restored and the correct portal opens — it must **not** drop to the Guest shell | P1 |
| GEN-039 | Server 5xx | Backend returning 500/502/503 | 1. Open any data screen | "The server is having trouble right now. Please try again shortly." | P2 |
| GEN-040 | Server 429 | Trigger rate limiting (many OTP requests) | 1. Tap RESEND CODE repeatedly | "Too many attempts. Please wait a moment and try again." | P2 |
| GEN-041 | HTML error page is not shown raw | Backend returns an HTML error page | 1. Trigger the failing call | A generic friendly message is shown; raw HTML is never rendered in the snackbar | P2 |

---

## 3. AUTH — Authentication, role gating & session

### 3.1 Login entry screen (`/login`)

| TC ID | Test Scenario | Pre-condition | Steps | Expected Result | Pri |
|---|---|---|---|---|---|
| AUTH-001 | Login options are shown | Not logged in | 1. Open the login screen | Four options: CONTINUE WITH PHONE, BROWSE AS GUEST, CHANNEL PARTNER, INVESTOR PORTAL; M4 logo at the top and "M4 FAMILY SECURE ACCESS" footer | P1 |
| AUTH-002 | BROWSE AS GUEST | Login options visible | 1. Tap BROWSE AS GUEST | Guest portal home opens with no sign-in | P1 |
| AUTH-003 | CONTINUE WITH PHONE | Login options visible | 1. Tap CONTINUE WITH PHONE | Step 2 opens: "PHONE GATEWAY" / "SECURE MULTI-FACTOR AUTHENTICATION" with the WhatsApp number field | P1 |
| AUTH-004 | CHANNEL PARTNER option | Login options visible | 1. Tap CHANNEL PARTNER | The CP login screen (`/auth/cp/login`) is pushed | P1 |
| AUTH-005 | INVESTOR PORTAL option | Login options visible | 1. Tap INVESTOR PORTAL | Phone gateway opens with the role set to INVESTOR (OTP path) | P1 |
| AUTH-006 | BACK TO GUEST PORTAL | On the phone-entry step | 1. Tap BACK TO GUEST PORTAL | Returns to the Guest portal home | P2 |

### 3.2 Phone / OTP login

| TC ID | Test Scenario | Pre-condition | Steps | Expected Result | Pri |
|---|---|---|---|---|---|
| AUTH-007 | Phone field blocks letters | Phone gateway open | 1. Try typing letters and symbols in the number field | Only digits, `+`, space and `-` are accepted; max 18 characters | P1 |
| AUTH-008 | Empty phone | Phone gateway open | 1. Leave the field empty<br>2. Tap REQUEST TOKEN | Red snackbar: "Please enter your phone number"; no API call | P1 |
| AUTH-009 | Short phone | Phone gateway open | 1. Enter `98765`<br>2. Tap REQUEST TOKEN | Red snackbar: "Please enter a valid 10-digit phone number" | P1 |
| AUTH-010 | Over-long phone | Phone gateway open | 1. Enter 16+ digits<br>2. Tap REQUEST TOKEN | Red snackbar: "Please enter a valid phone number" | P2 |
| AUTH-011 | Valid phone sends OTP | Registered number | 1. Enter a valid 10-digit number<br>2. Tap REQUEST TOKEN | Button shows a spinner and is disabled; on success the OTP step opens showing "WHATSAPP CODE SENT TO &lt;number&gt;" | P1 |
| AUTH-012 | OTP received on WhatsApp | Valid registered number | 1. Request the token<br>2. Check WhatsApp | A 6-digit code arrives on the same number | P1 |
| AUTH-013 | OTP boxes auto-advance | OTP step open | 1. Type a digit in box 1 | Focus moves to box 2 automatically; typing 6 digits fills all boxes | P2 |
| AUTH-014 | OTP backspace moves back | Two digits entered | 1. Clear box 2 with backspace | Focus returns to box 1 | P2 |
| AUTH-015 | OTP box accepts only 1 digit | OTP step open | 1. Try typing two digits into one box | Only one character stays per box; the digit and caret are fully visible (not clipped) | P2 |
| AUTH-016 | Verify with a wrong OTP | OTP step open | 1. Enter 6 wrong digits<br>2. Tap AUTHENTICATE TOKEN | Red snackbar: "That code is incorrect or has expired. Please try again." — the user stays on the OTP step | P1 |
| AUTH-017 | Verify with an incomplete OTP | OTP step open | 1. Enter only 4 digits<br>2. Tap AUTHENTICATE TOKEN | Nothing is submitted; no API call and no crash | P2 |
| AUTH-018 | Verify with the correct OTP | Valid OTP received | 1. Enter the 6 digits<br>2. Tap AUTHENTICATE TOKEN | Loading indicator, then the user lands in the portal matching their **account's own role** | P1 |
| AUTH-019 | RESEND CODE | OTP step open | 1. Tap RESEND CODE | A new OTP is sent to the same number; no crash; a new code arrives | P2 |
| AUTH-020 | BACK from the OTP step | OTP step open | 1. Tap BACK | Returns to the phone-entry step with the number retained | P2 |
| AUTH-021 | Dev-OTP box in debug only | Debug build with `devOtp` returned | 1. Request a token | "⚡ DEV MODE — SIMULATED OTP" card with the code and an AUTO-FILL button appears | P3 |
| AUTH-022 | AUTO-FILL works | Dev-OTP card visible | 1. Tap AUTO-FILL | All six boxes are populated with the dev code | P3 |
| AUTH-023 | No dev-OTP in release | Release build | 1. Request a token | The dev-OTP card is not shown (the server must not return `devOtp` in production) | P1 |
| AUTH-024 | Unregistered number | Number not in the system | 1. Request a token and verify | A readable server-driven message is shown; the user is not signed in | P1 |

### 3.3 Role gating on the OTP gateway

| TC ID | Test Scenario | Pre-condition | Steps | Expected Result | Pri |
|---|---|---|---|---|---|
| AUTH-025 | CP number on the customer gateway | Number registered as CP | 1. Login via CONTINUE WITH PHONE with the CP number<br>2. Enter the correct OTP | Access denied: "This number is registered as a Channel Partner. Please sign in from the Channel Partner login." and the stored token is discarded | P1 |
| AUTH-026 | Investor number on the customer gateway | Number registered as Investor | 1. Same as above with an investor number | "This number is registered as an Investor. Please sign in from the Investor Portal login." and the token is discarded | P1 |
| AUTH-027 | Non-investor on the investor gateway | Customer number, INVESTOR option chosen | 1. Login via INVESTOR PORTAL with a customer number and correct OTP | "Access denied. This number is not registered to an Investor account." | P1 |
| AUTH-028 | Denied login leaves no session | After AUTH-025 / 026 / 027 | 1. Kill the app<br>2. Cold start | The app opens as **Guest** — the refused session is not restored | P1 |
| AUTH-029 | Customer number on the customer gateway | Customer account | 1. Login with a customer number and the correct OTP | Customer portal opens | P1 |
| AUTH-030 | Investor number on the investor gateway | Investor account | 1. Login via INVESTOR PORTAL with an investor number and the correct OTP | Investor portal opens | P1 |
| AUTH-031 | Sign-in with an unidentifiable account | Token returned but `/me` cannot identify the account | 1. Complete OTP sign-in | "Could not confirm which account this number belongs to. Please try again." and the token is deleted | P2 |

### 3.4 Channel Partner login (`/auth/cp/login`)

| TC ID | Test Scenario | Pre-condition | Steps | Expected Result | Pri |
|---|---|---|---|---|---|
| AUTH-032 | CP login screen layout | Screen open | 1. Open CP login | "AUTHORIZED PARTNER" heading, MOBILE NUMBER field, PASSWORD field, FORGOT PASSWORD?, REGISTER NOW, AUTHORIZE ACCESS button, BACK TO GUEST PORTAL | P2 |
| AUTH-033 | Both fields empty | CP login open | 1. Tap AUTHORIZE ACCESS | Snackbar: "Please enter both mobile number and password"; no API call | P1 |
| AUTH-034 | Only phone filled | CP login open | 1. Enter a number, leave the password empty<br>2. Submit | Same "Please enter both mobile number and password" message | P1 |
| AUTH-035 | Invalid mobile format | CP login open | 1. Enter `12345` + any password<br>2. Submit | "Please enter a valid 10-digit phone number"; the request never reaches the API | P1 |
| AUTH-036 | Letters blocked in the number field | CP login open | 1. Type letters in MOBILE NUMBER | Letters are rejected as you type (digits, `+`, space, `-` only) | P2 |
| AUTH-037 | Password visibility toggle | Password entered | 1. Tap the eye icon | Password toggles between masked and plain text | P2 |
| AUTH-038 | Wrong password | Valid CP number | 1. Enter the wrong password<br>2. Submit | The server's own message is shown in an error snackbar; the user stays on the login screen | P1 |
| AUTH-039 | Non-CP account on CP login | Customer/investor credentials | 1. Sign in on the CP screen | "Access denied. Channel Partner account required under this ID." | P1 |
| AUTH-040 | Successful CP login | Valid CP credentials | 1. Submit | The CP portal opens (5-tab shell) and the CP's own name/company appears on Home/Profile | P1 |
| AUTH-041 | FORGOT PASSWORD? link | CP login open | 1. Tap FORGOT PASSWORD? | CP forgot-password screen opens | P2 |
| AUTH-042 | REGISTER NOW link | CP login open | 1. Tap REGISTER NOW | CP signup screen opens | P2 |
| AUTH-043 | Loading state | Valid credentials | 1. Submit and watch the button | Button is disabled and shows progress until the response arrives | P2 |

### 3.5 Channel Partner registration (`/auth/cp/signup`)

| TC ID | Test Scenario | Pre-condition | Steps | Expected Result | Pri |
|---|---|---|---|---|---|
| AUTH-044 | Signup form layout | Screen open | 1. Open CP signup | Sections: PERSONAL INFORMATION (FULL NAME *, COMPANY NAME, EMAIL, PHONE *), RERA CREDENTIALS (RERA NUMBER, RERA ID), ACCOUNT SETUP (CHANNEL PARTNER ID, PASSWORD, CONFIRM PASSWORD), COMPLETE REGISTRATION, "ALREADY HAVE AN ACCOUNT? LOGIN" | P2 |
| AUTH-045 | Mandatory fields only | Screen open | 1. Leave FULL NAME and/or PHONE empty<br>2. Submit | "Please enter your full name and phone number" | P1 |
| AUTH-046 | Password required | Name + phone filled, password empty | 1. Submit | "Please set a password so you can sign in later" | P1 |
| AUTH-047 | Name field blocks digits | Screen open | 1. Type `John123` into FULL NAME | Digits are rejected as typed; only letters, spaces, `.`, `'`, `-` (max 50 chars) | P1 |
| AUTH-048 | Name too short | Screen open | 1. Enter `J` + valid phone + password<br>2. Submit | "Please enter a valid full name" | P2 |
| AUTH-049 | Invalid phone | Screen open | 1. Enter a 5-digit phone<br>2. Submit | "Please enter a valid 10-digit phone number" | P1 |
| AUTH-050 | Invalid e-mail (optional field filled) | Screen open | 1. Enter `abc@` in EMAIL<br>2. Submit | "Please enter a valid email address" | P1 |
| AUTH-051 | Blank e-mail is allowed | Screen open | 1. Leave EMAIL empty, fill the mandatory fields<br>2. Submit | Submission proceeds; e-mail is simply omitted from the payload | P2 |
| AUTH-052 | Password mismatch | Screen open | 1. Enter different PASSWORD and CONFIRM PASSWORD<br>2. Submit | "Passwords do not match" | P1 |
| AUTH-053 | Successful registration | Unused phone number | 1. Fill all mandatory fields correctly<br>2. Submit | Green snackbar "Registration successful! Please login." and the app navigates to the CP login screen | P1 |
| AUTH-054 | Duplicate registration | Phone already registered | 1. Register the same number again | The server's own error message is shown; no duplicate account is created | P1 |
| AUTH-055 | Optional fields are persisted | Screen open | 1. Fill COMPANY NAME, RERA NUMBER, RERA ID, CP ID<br>2. Register and then log in and open the CP profile | The optional values are stored and visible on the profile | P2 |
| AUTH-056 | Submitting state | Valid data | 1. Submit and watch the button | The button is disabled and shows progress until the call completes | P2 |
| AUTH-057 | "from=guest" return path | Opened from the guest drawer | 1. Register successfully | Returns to the CP login screen preserving the guest origin | P3 |

### 3.6 CP forgot password (`/auth/cp/forgot-password`)

| TC ID | Test Scenario | Pre-condition | Steps | Expected Result | Pri |
|---|---|---|---|---|---|
| AUTH-058 | Step 1 layout | Screen open | 1. Open forgot password | "RESET ACCESS" / "RECOVER YOUR PARTNER ACCOUNT", REGISTERED EMAIL field, SEND RESET CODE | P2 |
| AUTH-059 | Empty / invalid e-mail | Step 1 | 1. Tap SEND RESET CODE with an empty or malformed e-mail | Validation message ("Please enter your email address" / "Please enter a valid email address") | P1 |
| AUTH-060 | Unknown e-mail | Step 1 | 1. Enter an unregistered e-mail and submit | "User not found" (or the server's message) — no code is sent | P1 |
| AUTH-061 | Valid e-mail sends the code | Registered CP e-mail | 1. Submit | "Security code sent!" and step 2 (VERIFY CODE) opens | P1 |
| AUTH-062 | Incomplete code | Step 2 | 1. Enter fewer than 6 digits<br>2. Tap CONTINUE | "Enter the complete 6-digit code" | P1 |
| AUTH-063 | Step 3 empty fields | Step 3 (NEW PASSWORD) | 1. Tap UPDATE PASSWORD with empty fields | "Please fill in all fields" | P1 |
| AUTH-064 | New password mismatch | Step 3 | 1. Enter mismatching passwords<br>2. Submit | "Passwords do not match" | P1 |
| AUTH-065 | Password shorter than 8 | Step 3 | 1. Enter `abc123` in both fields<br>2. Submit | "Password must be at least 8 characters" | P1 |
| AUTH-066 | Successful reset | Valid code + valid new password | 1. Submit | "Password updated. You can login." and the app navigates to the CP login screen | P1 |
| AUTH-067 | Login with the new password | Password just reset | 1. Sign in with the new password | Login succeeds | P1 |
| AUTH-068 | Old password is rejected | Password just reset | 1. Sign in with the old password | Login fails with the server's message | P1 |
| AUTH-069 | Step back navigation | On step 2 or 3 | 1. Tap the back control | Returns to the previous step without losing the flow | P2 |

### 3.7 Investor login (`/investor/login`)

| TC ID | Test Scenario | Pre-condition | Steps | Expected Result | Pri |
|---|---|---|---|---|---|
| AUTH-070 | Investor landing step | Screen open | 1. Open the investor login | "INVESTOR PORTAL" hero with feature pills SECURE / ANALYTICS / REAL-TIME / PREMIUM and an ACCESS INVESTOR HUB button | P2 |
| AUTH-071 | Credentials step | Landing step | 1. Tap ACCESS INVESTOR HUB | "CREDENTIALS" step with REGISTERED EMAIL and SECURE PASSWORD fields and a LOGIN button | P1 |
| AUTH-072 | Empty fields | Credentials step | 1. Tap LOGIN with both fields empty | "Please provide your Email and Password" | P1 |
| AUTH-073 | Invalid e-mail format | Credentials step | 1. Enter `test@@x` + a password<br>2. Submit | "Please enter a valid email address"; the API is not called | P1 |
| AUTH-074 | Spaces blocked in e-mail | Credentials step | 1. Try typing a space in the e-mail field | The space is rejected as typed | P3 |
| AUTH-075 | Password visibility toggle | Password entered | 1. Tap the eye icon | Password toggles masked/plain | P2 |
| AUTH-076 | Wrong password | Valid investor e-mail | 1. Submit with a wrong password | The server's error message is shown; the user stays on the screen | P1 |
| AUTH-077 | Non-investor account | CP or customer credentials | 1. Submit | "Access denied. This portal is reserved for premium investors." | P1 |
| AUTH-078 | Missing session token | Server responds 200 without a token | 1. Submit | "Login failed: missing session token." — the user is not signed in | P2 |
| AUTH-079 | Successful investor login | Valid investor credentials | 1. Submit | Investor portal opens (4-tab shell) with the investor's own name on Home/Profile | P1 |
| AUTH-080 | AUTHENTICATING state | Valid credentials | 1. Submit and watch the button | Button shows "AUTHENTICATING" / progress and is disabled | P2 |
| AUTH-081 | Back to guest | Credentials step | 1. Tap the back control twice | Returns to the landing step, then to the Guest portal | P2 |

### 3.8 Session & logout

| TC ID | Test Scenario | Pre-condition | Steps | Expected Result | Pri |
|---|---|---|---|---|---|
| AUTH-082 | Session persists across restarts | Logged in (any role) | 1. Kill and relaunch the app | Still logged in; the same portal opens | P1 |
| AUTH-083 | Logout is instant | Logged in | 1. Profile → LOG OUT → confirm | The UI switches to the Guest shell immediately (no visible lag) | P1 |
| AUTH-084 | Logout confirmation dialog | Logged in | 1. Tap LOG OUT | A confirmation dialog appears ("Sign out of your ... account?") with Cancel and LOG OUT | P2 |
| AUTH-085 | Cancel logout | Logout dialog open | 1. Tap Cancel | The dialog closes and the session is untouched | P2 |
| AUTH-086 | Session cleared after logout | Just logged out | 1. Kill the app<br>2. Cold start | Opens as **Guest** — the old session does not return | P1 |
| AUTH-087 | Post-logout navigation | Just logged out | 1. Navigate around the guest portal | No stuck splash screen; all guest screens work | P1 |
| AUTH-088 | Token is attached to API calls | Logged in | 1. Open any authenticated screen (Profile, Payments) | Personalised data loads (the `Authorization: Bearer` header is applied) | P1 |
| AUTH-089 | Protected data is gone after logout | Just logged out | 1. Open Guest Profile | "GUEST USER" placeholder with SIGN IN / CREATE ACCOUNT; no previous user's data is visible | P1 |

---

## 4. VAL — Shared form-validation matrix

These rules come from the shared `Validators` used by every form in the app. Run this matrix once per listed form.

### 4.1 Rule reference

| Field type | Typing restriction (blocked as you type) | Validation messages |
|---|---|---|
| Name | Letters, spaces, `.`, `'`, `-` only; max 50 | Empty → "Please enter your &lt;field&gt;" · <2 chars → "Please enter a valid &lt;field&gt;" · bad chars → "Only letters are allowed in the &lt;field&gt;" |
| E-mail | No spaces; max 120 | Empty → "Please enter your email address" · malformed → "Please enter a valid email address" |
| Phone | Digits, `+`, space, `-` only; max 18 | Empty → "Please enter your phone number" · <10 digits → "Please enter a valid 10-digit phone number" · >15 digits → "Please enter a valid phone number" |
| Required (generic) | — | Empty → "Please enter &lt;field&gt;" |

### 4.2 Matrix cases

| TC ID | Test Scenario | Pre-condition | Steps | Expected Result | Pri |
|---|---|---|---|---|---|
| VAL-001 | Name field blocks digits | Any form with a name field | 1. Type `Ravi123` | The digits never appear in the field | P1 |
| VAL-002 | Name accepts legitimate punctuation | Any name field | 1. Type `D'Souza`, `Jean-Luc`, `Dr. Rao` | All three are accepted without an error | P2 |
| VAL-003 | Name max length | Any name field | 1. Paste a 60-character name | Input is truncated at 50 characters | P3 |
| VAL-004 | Name — single character | Any name field | 1. Enter `A` and submit | "Please enter a valid ..." | P2 |
| VAL-005 | E-mail rejects spaces | Any e-mail field | 1. Try typing `a b@x.com` | The space is not accepted | P2 |
| VAL-006 | E-mail malformed variants | Any e-mail field | 1. Try `abc`, `abc@`, `abc@x`, `@x.com`, `a@.com` and submit each | Each shows "Please enter a valid email address" | P1 |
| VAL-007 | E-mail valid variants | Any e-mail field | 1. Try `a.b@x.co`, `a+b@sub.domain.in` | Accepted with no error | P2 |
| VAL-008 | Phone rejects letters | Any phone field | 1. Try typing `98abc76543` | Letters never appear | P1 |
| VAL-009 | Phone accepts formatting characters | Any phone field | 1. Type `+91 98765-43210` | Accepted; validated on the digit count | P2 |
| VAL-010 | Phone below 10 digits | Any phone field | 1. Enter `98765` and submit | "Please enter a valid 10-digit phone number" | P1 |
| VAL-011 | Phone above 15 digits | Any phone field | 1. Enter 16 digits and submit | "Please enter a valid phone number" | P2 |
| VAL-012 | Whitespace-only input | Any required field | 1. Enter only spaces and submit | Treated as empty; the "please enter ..." message appears | P2 |
| VAL-013 | Error clears on correction | A field is showing an error | 1. Correct the value and submit again | The error clears and submission proceeds | P2 |
| VAL-014 | Emoji / special characters | Any name field | 1. Paste emoji into a name field | Rejected or stripped; no crash and no invalid submission | P3 |
| VAL-015 | Very long free-text message | Any message/notes field | 1. Paste 2000+ characters and submit | Either accepted cleanly or capped with a clear message; no crash and no layout break | P3 |

### 4.3 Forms this matrix must be run against

| # | Portal | Form |
|---|---|---|
| 1 | Guest | Home "REGISTER INTEREST" / Register Your Interest |
| 2 | Guest | Contact "GET IN TOUCH WITH US" |
| 3 | Guest | About → ENQUIRE FOR CUSTOM VIEWS |
| 4 | Guest | Community Detail → Express interest |
| 5 | Guest/Customer | Project Detail → SEND INQUIRY |
| 6 | Guest/Customer | Project Detail → SCHEDULE SITE VISIT |
| 7 | Customer | Dashboard inquiry form |
| 8 | Customer | Schedule Visit (`/support/schedule-visit`) |
| 9 | Customer | Raise Ticket / Create Ticket |
| 10 | Customer | Family Members add/edit |
| 11 | Customer | Profile Settings / Account details |
| 12 | Customer | Referral — refer a friend |
| 13 | CP | CP signup |
| 14 | CP | CP Inquiry (`/cp/booking/inquiry`) |
| 15 | CP | CP Site Visit (`/cp/booking/site-visit`) |
| 16 | CP | CP Referral — submit referral |
| 17 | CP | CP Employees — add/edit employee |
| 18 | CP | CP Profile details / settings |
| 19 | CP | CP Project Detail — register client lead |
| 20 | Investor | Investor Relations enquiry |
| 21 | Investor | Investor Referral — refer a friend |
| 22 | Investor | Investor CP screen — register lead |
| 23 | Investor | Investor Profile details / settings |
| 24 | All | Careers → Job Apply |
| 25 | All | Booking → Inquiry / Site Visit / Token Payment |

---

## 5. GST — Guest portal

The guest shell has 5 tabs: **Home · Properties · About · Careers · Contact**, a side drawer and a floating nav pill.

### 5.1 Guest shell & drawer

| TC ID | Test Scenario | Pre-condition | Steps | Expected Result | Pri |
|---|---|---|---|---|---|
| GST-001 | Guest shell tabs | Guest portal open | 1. Observe the bottom bar | 5 tabs in order: Home, Properties (building), About (info), Careers (briefcase), Contact (headphones) | P1 |
| GST-002 | Tab switching | Guest portal | 1. Tap each tab in turn | The correct screen opens for each; the active glyph is highlighted; no reload flicker (tabs keep their state) | P1 |
| GST-003 | Tab state is preserved | Guest portal | 1. Scroll Properties down<br>2. Switch to About and back | Properties is still scrolled to the same position | P2 |
| GST-004 | Guest drawer contents | Guest portal | 1. Open the side drawer | MENU with Home, Properties, Community, Custom Views, Content Hub, Media, Highlights, Events, Blog, Who We Are, Careers, Contact, Enquiry; QUICK ACTIONS with Call, WhatsApp, Location; plus Customer Login, CP Login, Investor Login and EXIT APP | P1 |
| GST-005 | Every drawer item navigates | Drawer open | 1. Tap each item one by one | Each opens its own screen; the drawer closes; no dead entries | P1 |
| GST-006 | Enquiry scrolls to the form | Guest Home | 1. Drawer → Enquiry | Home opens and auto-scrolls to the "Register Your Interest" form | P2 |
| GST-007 | Quick action — Call | Drawer open | 1. Tap Call | The phone dialler opens pre-filled with the M4 sales number | P2 |
| GST-008 | Quick action — WhatsApp | Drawer open | 1. Tap WhatsApp | WhatsApp opens on the M4 number (or a store/browser fallback if WhatsApp is not installed) — no crash | P2 |
| GST-009 | Quick action — Location | Drawer open | 1. Tap Location | Maps opens at the M4 head-office location | P2 |
| GST-010 | Login entries from the drawer | Drawer open | 1. Tap Customer Login / CP Login / Investor Login | Each opens the matching login screen | P1 |

### 5.2 Guest home (`guest_dashboard_screen`)

| TC ID | Test Scenario | Pre-condition | Steps | Expected Result | Pri |
|---|---|---|---|---|---|
| GST-011 | Home renders | Guest Home | 1. Open Home | Deep-green hero with the M4 FAMILY brand, "OUR PHILOSOPHY" / "Who We Are" section, and the Communities / Properties / Media segmented sections | P1 |
| GST-012 | Hero images load | Guest Home, network on | 1. Observe the hero carousel | Project hero images load; broken/missing images fall back to a placeholder with "ARTISTIC IMPRESSION" rather than a grey box or an error glyph | P2 |
| GST-013 | Communities section | Guest Home | 1. Scroll to Communities | Community cards with image, title and description; tapping one opens the community detail | P1 |
| GST-014 | Communities empty state | No published communities | 1. Open Home | "NO COMMUNITIES YET — Communities will appear here once they are published." | P2 |
| GST-015 | Properties section | Guest Home | 1. Switch to the Properties section | Project cards load; tapping one opens the guest project detail | P1 |
| GST-016 | Properties empty state | No published projects | 1. Open Home | "NO PROPERTIES YET — Properties will appear here once they are published." | P2 |
| GST-017 | Media section | Guest Home | 1. Switch to the Media section | Media tiles load; tapping one opens the content detail | P2 |
| GST-018 | RETRY on load failure | Network off | 1. Open Home<br>2. Turn the network on and tap RETRY | Error state with RETRY; after retry the content loads | P1 |
| GST-019 | Register Your Interest — happy path | Guest Home | 1. Scroll to the interest form<br>2. Fill name, e-mail, phone, message<br>3. Tick the privacy checkbox<br>4. Submit | "Interest registered successfully!" and the form resets | P1 |
| GST-020 | Privacy policy is mandatory | Interest form filled | 1. Submit without ticking the privacy box | "Please agree to the Privacy Policy" — no submission | P1 |
| GST-021 | Interest form validation | Interest form | 1. Run the VAL matrix (VAL-001…015) on name / e-mail / phone | All shared validation rules apply | P1 |
| GST-022 | Submission failure | Backend failing | 1. Submit a valid form | A readable failure message is shown and the entered data is preserved | P2 |
| GST-023 | Pull to refresh | Guest Home | 1. Pull down | Content refreshes; the spinner ends and no duplicate cards appear | P2 |

### 5.3 Guest properties / project list

| TC ID | Test Scenario | Pre-condition | Steps | Expected Result | Pri |
|---|---|---|---|---|---|
| GST-024 | Project list renders | Properties tab | 1. Open Properties | "M4 PROPERTIES / DISCOVER CURATED LUXURY" header and project cards showing image, title, location and status | P1 |
| GST-025 | Status filter chips | Properties tab | 1. Filter by Ongoing / Upcoming / Completed | Only matching projects remain in the list | P1 |
| GST-026 | Grid / List toggle | Properties tab | 1. Toggle the layout control | The layout switches between grid and list; content stays the same | P2 |
| GST-027 | REFINE SEARCH panel | Properties tab | 1. Open REFINE SEARCH | Filters: LOCATION, CONFIGURATION, AREA (SQ FT), PROPERTY TYPE and an APPLY SEARCH MATRIX button | P1 |
| GST-028 | Apply filters | Refine panel open | 1. Set a location and configuration<br>2. APPLY SEARCH MATRIX | The list narrows to matching projects; the panel closes | P1 |
| GST-029 | No-match state | Refine panel | 1. Apply filters that match nothing | "NO ARCHITECTURAL MATCHES — Try expanding your search criteria." plus a CLEAR FILTERS action | P1 |
| GST-030 | Clear filters | No-match state | 1. Tap CLEAR FILTERS | All filters reset and the full list returns | P1 |
| GST-031 | Slow-server state | Throttled network | 1. Open Properties | "TAKING LONGER THAN USUAL — The server may be waking up. Please try again." with RETRY | P2 |
| GST-032 | Offline state | Airplane mode | 1. Open Properties | "Please check your connection and try again." with RETRY | P1 |
| GST-033 | Image fallback | Project without images | 1. Open Properties | Placeholder with "ARTISTIC IMPRESSION" instead of a broken image | P2 |
| GST-034 | Open a project | Properties tab | 1. Tap any project card | The guest project detail screen opens for the correct project | P1 |
| GST-035 | Scroll performance | 20+ projects | 1. Scroll the list quickly up and down | Smooth scrolling, no jank, no memory-related crash | P2 |

### 5.4 Guest project detail

| TC ID | Test Scenario | Pre-condition | Steps | Expected Result | Pri |
|---|---|---|---|---|---|
| GST-036 | Detail screen loads | From the project list | 1. Open a project | Hero gallery, project title, location, status, overview, amenities, configuration and the action rail | P1 |
| GST-037 | EXTERIOR / INTERIOR gallery | Project detail | 1. Switch between EXTERIOR and INTERIOR | The correct image set loads for each; swiping moves between images | P2 |
| GST-038 | Full-screen image | Project detail | 1. Tap a gallery image | Opens full-screen; pinch-zoom and close work | P2 |
| GST-039 | Construction progress | Project with progress data | 1. Scroll to CONSTRUCTION PROGRESS | Phases are listed (Foundation … Structure & Handover) with Completed / In Progress / Upcoming status and percentages | P2 |
| GST-040 | Downloads — project flyer | Project detail | 1. Tap PROJECT FLYER → VIEW / DOWNLOAD | The PDF opens or downloads; a "Saved …" / "Downloading …" confirmation is shown | P1 |
| GST-041 | Download unavailable | Project with no flyer | 1. Tap the download tile | "That file is not available yet." — no crash | P2 |
| GST-042 | Virtual tour | Project with a tour URL | 1. Tap 360° VIEW / WALKTHROUGH | The tour opens in the in-app webview/browser | P2 |
| GST-043 | Broken virtual-tour link | Project with a bad URL | 1. Tap the tour | "Could not launch virtual tour link" — no crash | P2 |
| GST-044 | Share the project | Project detail | 1. Tap Share | The OS share sheet opens with the project title and link | P2 |
| GST-045 | Call / e-mail actions | Project detail | 1. Tap the call and e-mail contacts | Dialler / mail client open with the right values; if none is available "Unable to open link" is shown | P2 |
| GST-046 | SEND INQUIRY | Project detail | 1. Open SEND INQUIRY<br>2. Fill the form and submit | Success message ("Inquiry submitted! …") and the sheet closes | P1 |
| GST-047 | SCHEDULE SITE VISIT — validation | Project detail | 1. Open SCHEDULE SITE VISIT<br>2. Submit without a date/time | "Please schedule a date and time for your visit" | P1 |
| GST-048 | Past date rejected | Site-visit sheet | 1. Pick a past date/time<br>2. Submit | "Please pick a future date and time" | P1 |
| GST-049 | Site visit happy path | Site-visit sheet | 1. Fill name + phone, pick a future slot<br>2. Submit | Success confirmation and the sheet closes | P1 |
| GST-050 | Guest is prompted where login is required | Guest, on a members-only action | 1. Tap a members-only CTA (e.g. token booking) | The app either routes to login or clearly states that sign-in is needed — no silent failure | P1 |
| GST-051 | Favourite / save | Project detail | 1. Tap the heart/save icon | Toast toggles between "Saved to favorites" and "Removed from favorites" | P3 |

### 5.5 Guest About / Careers / Contact

| TC ID | Test Scenario | Pre-condition | Steps | Expected Result | Pri |
|---|---|---|---|---|---|
| GST-052 | About sections | About tab | 1. Open About | Section tabs: About, Journey, 4 Pillars, Philosophy, Custom Views; content "WHO WE ARE", "OUR STORY", "OUR MILESTONES", "THE 4 PILLARS", "OUR PHILOSOPHY" | P1 |
| GST-053 | About section switching | About tab | 1. Tap each section chip | The matching content shows; the chip stays within its bounds at 1.5x font scale | P2 |
| GST-054 | Custom Views enquiry form | About → Custom Views | 1. Fill FULL NAME, PHONE NUMBER, EMAIL (optional)<br>2. Tap ENQUIRE FOR CUSTOM VIEWS | Success confirmation; validation rules apply to each field | P1 |
| GST-055 | Careers list | Careers tab | 1. Open Careers | Job cards with title, department and location | P1 |
| GST-056 | Careers empty state | No open roles | 1. Open Careers | "NO ACTIVE VACANCIES CURRENTLY AVAILABLE" | P2 |
| GST-057 | Job detail | Careers tab | 1. Tap a job | JOB DESCRIPTION, KEY RESPONSIBILITIES, REQUIREMENTS, WHY JOIN US?, APPLY FOR THIS POSITION, EMAIL RECRUITMENT, CAREER HELPLINE | P1 |
| GST-058 | Apply — form layout | Job detail | 1. Tap APPLY FOR THIS POSITION | Form with FULL NAME, PHONE NUMBER, EMAIL ADDRESS and RESUME / PORTFOLIO (PDF) | P1 |
| GST-059 | Apply — resume required | Apply form | 1. Fill the fields but do not attach a résumé<br>2. Submit | "Please upload your resume (PDF)" | P1 |
| GST-060 | Résumé picker | Apply form | 1. Tap SELECT PDF DOCUMENT | The file picker opens and accepts a PDF; the chosen file name is displayed | P1 |
| GST-061 | Apply — happy path | Apply form filled + PDF attached | 1. Tap SUBMIT APPLICATION | "Application Submitted Successfully!" | P1 |
| GST-062 | Apply — upload failure | Backend upload failing | 1. Submit | "Failed to upload resume" / "Failed to submit application" — no crash and no silent success | P2 |
| GST-063 | Contact screen | Contact tab | 1. Open Contact | CONTACT INFORMATION, OUR HEAD OFFICE with the address, DIRECTIONS and CALL NOW, plus the GET IN TOUCH WITH US form | P1 |
| GST-064 | CALL NOW | Contact tab | 1. Tap CALL NOW | Dialler opens with the M4 sales number | P2 |
| GST-065 | DIRECTIONS | Contact tab | 1. Tap DIRECTIONS | Maps opens at the office location | P2 |
| GST-066 | Contact form | Contact tab | 1. Fill name, e-mail, phone, message<br>2. Tick Privacy Policy<br>3. SUBMIT INQUIRY | "Thank you! We will get in touch with you shortly." | P1 |
| GST-067 | Contact form — privacy required | Contact form filled | 1. Submit without ticking privacy | "Please agree to the Privacy Policy" | P1 |
| GST-068 | Guest profile | Guest portal | 1. Open Guest Profile | "GUEST USER" with SIGN IN, CREATE ACCOUNT, INVESTOR LOGIN and the "WHY JOIN M4 FAMILY?" benefits | P2 |
| GST-069 | Guest custom views showcase | Guest portal | 1. Drawer → Custom Views | "INTERACTIVE LIVING / M4 CUSTOM SHOWCASE" gallery (EXPANSIVE LIVING, MASTER SUITES, PRIVATE TERRACES, ELITE SPA BATHROOMS) — read-only for guests | P2 |
| GST-070 | Guest privacy policy page | Guest portal | 1. Drawer → Privacy Policy | The CMS privacy page renders with its content and last-updated date | P2 |

### 5.6 Guest communities

| TC ID | Test Scenario | Pre-condition | Steps | Expected Result | Pri |
|---|---|---|---|---|---|
| GST-071 | Community list | Guest portal | 1. Open Communities | "COMMUNITIES / ABOUT THE COMMUNITIES" with community cards | P1 |
| GST-072 | Read more / Read less | Community list | 1. Tap Read more on the intro text | The text expands and the control switches to "Read less" | P3 |
| GST-073 | Community empty state | No communities published | 1. Open Communities | "NO ACTIVE COMMUNITIES FOUND" | P2 |
| GST-074 | Community detail | Community list | 1. Tap a community | Hero, About the community, Benefits (community-centric design, prime location, green spaces, safety, retail, transport) and a Projects section | P1 |
| GST-075 | Community → projects | Community detail | 1. Tap VIEW ALL under Projects | The community projects screen opens listing only that community's projects | P1 |
| GST-076 | Community projects empty | Community with no projects | 1. Open its projects screen | "NO PROJECTS FOUND IN THIS COMMUNITY" with a RETURN action | P2 |
| GST-077 | Community not found | Invalid community slug | 1. Open the detail | "Community not found" / "UNABLE TO LOAD PROJECTS" with GO BACK — no crash | P2 |
| GST-078 | Express interest from a community | Community detail | 1. Fill the express-interest form and submit | "Interest registered successfully!"; validation rules apply | P1 |

---

## 6. CUS — Customer portal

Customer shell tabs: **Home · Projects · Support · Profile**, plus sidebar-only screens (Communities, Notifications, Custom Views, My Custom Views, Personalisation Logs, Content Hub).

### 6.1 Customer shell & dashboard

| TC ID | Test Scenario | Pre-condition | Steps | Expected Result | Pri |
|---|---|---|---|---|---|
| CUS-001 | Customer tabs | Logged in as customer | 1. Observe the bottom bar | 4 tabs: Home, Projects, Support, Profile | P1 |
| CUS-002 | Dashboard renders | Customer Home | 1. Open Home | Hero, FEATURED PROPERTY, the M4 COMMUNITIES / M4 PROPERTIES / M4 MEDIA sections, quick actions and the inquiry form | P1 |
| CUS-003 | Quick actions | Customer Home | 1. Tap EXPLORE PROJECTS, BOOK A VIEWING, MEDIA GALLERY, REGISTER INTEREST | Each routes to the right screen (projects list, site-visit booking, media hub, interest form) | P1 |
| CUS-004 | Featured property empty | No featured project | 1. Open Home | "No featured properties" placeholder instead of a blank card | P2 |
| CUS-005 | Section empty states | No data for a section | 1. Open Home | "NO ITEMS FOUND" / "NO MEDIA FOUND" placeholders | P2 |
| CUS-006 | Dashboard inquiry form | Customer Home | 1. Fill name, e-mail, phone, message and submit | "Inquiry submitted successfully!" | P1 |
| CUS-007 | Inquiry failure | Backend failing | 1. Submit the inquiry | "Could not submit right now. Please try again." | P2 |
| CUS-008 | Search entry | Customer Home | 1. Tap "Search Residences" / the search control | The search screen opens with the LOCATION / PROPERTY TYPE filters | P1 |
| CUS-009 | Logged-in identity | Logged in | 1. Open Home and Profile | The customer's own name and avatar are shown — never another user's data | P1 |
| CUS-010 | Customer drawer | Customer portal | 1. Open the drawer | MENU with Home, Properties, Communities, Custom Views, My Custom Views, Content Hub, Media, Highlights, Events, Blog, Notifications, Who we are, Careers, Contact Us, Enquiry; QUICK ACTIONS (Call, Whatsapp); LOG OUT | P1 |
| CUS-011 | Drawer logout confirmation | Drawer open | 1. Tap LOG OUT | Confirmation with CANCEL / LOGOUT; only LOGOUT signs out | P1 |

### 6.2 Customer projects & detail

| TC ID | Test Scenario | Pre-condition | Steps | Expected Result | Pri |
|---|---|---|---|---|---|
| CUS-012 | Project list (customer) | Projects tab | 1. Open Projects | Same list/filter behaviour as GST-024…035 but inside the customer shell | P1 |
| CUS-013 | Project detail actions | Open a project | 1. Scroll to the action rail | SEND INQUIRY, SCHEDULE SITE VISIT and TOKEN BOOKING are all available to a logged-in customer | P1 |
| CUS-014 | Inquiry prefill | Logged-in customer | 1. Open SEND INQUIRY | Name / phone / e-mail are pre-filled from the profile and remain editable | P2 |
| CUS-015 | Site-visit prefill | Logged-in customer | 1. Open SCHEDULE SITE VISIT | Name and phone are pre-filled from the profile | P2 |
| CUS-016 | Date & time picker | Site-visit sheet | 1. Open SELECT DATE & TIME | The wheel picker opens with CANCEL and CONFIRM; the AM/PM column is fully visible at 1.5x font scale | P1 |
| CUS-017 | Cancel the picker | Picker open | 1. Tap CANCEL | The picker closes and no date is applied | P2 |
| CUS-018 | Confirm the picker | Picker open | 1. Choose a slot and tap CONFIRM | The chosen date/time appears on the form in `dd MMM yyyy` + time format | P1 |
| CUS-019 | Missing date/time | Site-visit sheet | 1. Submit without a slot | "Please select a date and time" | P1 |
| CUS-020 | Site-visit success | Site-visit sheet | 1. Submit a complete form | "SUBMITTED" confirmation with a BACK TO PROJECT action | P1 |
| CUS-021 | Download brochure / flyer | Project detail | 1. Tap E-BROCHURE / PROJECT FLYER | "Downloading &lt;title&gt;…" then "Saved &lt;name&gt;" with an OPEN action that opens the file | P1 |
| CUS-022 | Download permission (Android) | First download on Android | 1. Trigger a download | Any storage permission prompt is handled; on denial a clear message is shown, not a silent failure | P1 |
| CUS-023 | RERA certificate | Project with RERA doc | 1. Tap "RERA Registration Certificate" | The document opens/downloads correctly | P2 |
| CUS-024 | Project updates / logs | Project detail | 1. Scroll to RECENT LOGS / updates | Project updates are listed newest first with dates | P2 |
| CUS-025 | 360° view | Project with a 3D asset | 1. Tap 360° VIEW | The immersive view loads in the webview; back returns to the detail screen | P2 |

### 6.3 Customer profile & account

| TC ID | Test Scenario | Pre-condition | Steps | Expected Result | Pri |
|---|---|---|---|---|---|
| CUS-026 | Profile screen | Profile tab | 1. Open Profile | Avatar, name, e-mail, phone, address, POINTS balance, PROPERTY SERVICES and MANAGEMENT & SUPPORT tiles, LOG OUT | P1 |
| CUS-027 | Missing profile values | Account with blank fields | 1. Open Profile | "No email provided" / "No phone provided" / "No address provided" — never an empty row or `null` | P2 |
| CUS-028 | MY PROPERTIES tile | Profile | 1. Tap MY PROPERTIES | The My Properties screen opens | P1 |
| CUS-029 | MY CUSTOM VIEWS tile | Profile | 1. Tap MY CUSTOM VIEWS | My Custom Views opens; system Back returns to Profile (see GEN-024) | P1 |
| CUS-030 | M4 REFERRAL PROGRAM tile | Profile | 1. Tap it | The Referral / Rewards hub opens | P1 |
| CUS-031 | Profile settings — load | Profile → Settings | 1. Open Account details / Settings | Existing values are pre-filled (name, e-mail, phone, address, PAN/AADHAR, notification switches) | P1 |
| CUS-032 | Profile settings — save | Settings open | 1. Edit the name<br>2. Tap SAVE | Success message and the new name appears immediately on Profile without a restart | P1 |
| CUS-033 | Profile settings — validation | Settings open | 1. Clear the name / enter a bad e-mail and save | The shared validation messages appear; nothing is saved | P1 |
| CUS-034 | Avatar upload | Settings open | 1. Tap the avatar → pick an image | The image uploads and the new avatar shows immediately | P1 |
| CUS-035 | Avatar too large | Image over 2 MB | 1. Pick a large image | "File too large (max 2MB)" — no upload attempt | P1 |
| CUS-036 | Avatar upload failure | Backend failing | 1. Pick a valid image | "Failed to upload profile picture" / "Upload failed" and the old avatar stays | P2 |
| CUS-037 | App settings toggles | Profile → App settings | 1. Toggle PUSH ALERTS, EMAIL REPORTS, BIOMETRIC ACCESS, AUTO REFRESH | Each toggle flips, persists after leaving and reopening the screen, and shows a save confirmation | P1 |
| CUS-037a | MY FAMILY is NOT on the customer profile | Logged in as customer | 1. Open Profile and read every tile | There is **no** MY FAMILY entry on the customer profile (it belongs to the investor profile only); the tiles around it — MY PROPERTIES, MY CUSTOM VIEWS, M4 REFERRAL PROGRAM — are all still present | P1 |
| CUS-038 | Family members — list | Family screen reached from the investor profile or the `/profile/family` route | 1. Open Family Members | Existing members with name, relation and date of birth, plus a search field | P1 |
| CUS-039 | Family — add member | Family screen | 1. ADD FAMILY MEMBER<br>2. Enter name + relation (+ DOB)<br>3. ADD MEMBER | The member is added to the list and "Family details updated successfully" is shown | P1 |
| CUS-040 | Family — required fields | Add-member sheet | 1. Submit with an empty name or relation | "Name and Relation are required" | P1 |
| CUS-041 | Family — relation options | Add-member sheet | 1. Open the relation selector | Spouse, Son, Daughter, Parent and "Other / Custom" (with a free-text field) are available | P2 |
| CUS-042 | Family — edit member | Member exists | 1. Edit a member and SAVE CHANGES | The row updates with the new values | P1 |
| CUS-043 | Family — remove member | Member exists | 1. Tap remove<br>2. Confirm REMOVE | Confirmation dialog first ("Are you sure you want to remove this family member?"); on REMOVE the member disappears | P1 |
| CUS-044 | Family — cancel removal | Remove dialog open | 1. Tap CANCEL | The member is kept | P2 |
| CUS-045 | Family — empty state | No members | 1. Open Family | "NO FAMILY MEMBERS FOUND" | P2 |
| CUS-046 | Family — search | Several members | 1. Type part of a name in Search Members | Only matching members remain | P2 |
| CUS-047 | Deactivate account — warning | Profile → Deactivate | 1. Open the screen | "PURGE PROTOCOL / CRITICAL WARNING" with the PURGE SCOPE list and a confirmation field | P1 |
| CUS-048 | Deactivate — type DELETE | Deactivate screen | 1. Tap EXECUTE PURGE without typing DELETE | The action is blocked until the exact word is typed | P1 |
| CUS-049 | Deactivate — abort | Deactivate screen | 1. Tap ABORT PROTOCOL | Returns to the previous screen with the account untouched | P1 |
| CUS-050 | Deactivate — execute | DELETE typed | 1. Tap EXECUTE PURGE and confirm | The account is deactivated, the user is signed out and cannot sign back in with the same credentials | P1 |

### 6.4 My Properties, Portfolio & Legal Vault

| TC ID | Test Scenario | Pre-condition | Steps | Expected Result | Pri |
|---|---|---|---|---|---|
| CUS-051 | My Properties list | Customer with a booking | 1. Open MY PROPERTIES | Unit cards with PROJECT, AREA, UNIT NO., CONFIG, FLOOR, TYPE, DOCUMENTS and PAY STATUS | P1 |
| CUS-052 | Payment status labels | Units with different states | 1. Review the cards | Status reads PAID / PARTIAL / PENDING correctly and the progress bar matches the percentage | P1 |
| CUS-053 | Allotted label | Confirmed booking | 1. Review a confirmed unit | Shows "Allotted" for confirmed/allotted bookings | P2 |
| CUS-054 | CUSTOMISE UNIT | Allotted unit | 1. Tap CUSTOMISE UNIT | The Custom Views personalisation flow opens for that unit | P1 |
| CUS-055 | My Properties empty | Customer with no bookings | 1. Open MY PROPERTIES | "NO PROPERTY RECORDS FOUND" | P2 |
| CUS-056 | Portfolio screen | Customer with holdings | 1. Open Portfolio | TOTAL ASSETS, COMBINED VALUE and CURRENT HOLDINGS cards with unit details | P1 |
| CUS-057 | Portfolio unit specs | Portfolio | 1. Tap VIEW SPECIFICATIONS | FLOOR LEVEL, DIMENSION, ORIENTATION and POSSESSION are shown | P2 |
| CUS-058 | Portfolio empty | No holdings | 1. Open Portfolio | "NO HOLDINGS YET — Your acquired properties will appear here." | P2 |
| CUS-059 | Portfolio error | Backend failing | 1. Open Portfolio | "UNABLE TO LOAD PORTFOLIO" with RETRY | P2 |
| CUS-060 | Legal Vault list | Customer with documents | 1. Open Legal Vault | "LEGAL VAULT / ENCRYPTED STORAGE" with documents showing title, project and added-on date | P1 |
| CUS-061 | Legal Vault — view | Document present | 1. Tap VIEW DOC | The document opens (viewer/browser) without error | P1 |
| CUS-062 | Legal Vault — share | Document present | 1. Tap SHARE | The OS share sheet opens | P2 |
| CUS-063 | Legal Vault empty | No documents | 1. Open Legal Vault | "NO DOCUMENTS FOUND" | P2 |

### 6.5 Referral & rewards (customer)

| TC ID | Test Scenario | Pre-condition | Steps | Expected Result | Pri |
|---|---|---|---|---|---|
| CUS-064 | Rewards hub | Logged-in customer | 1. Open M4 REFERRAL PROGRAM | "REWARDS HUB" with the referral code, POINTS and REFERRALS counters and the ACTIVE PIPELINE / CLOSED REFERRALS / POINT HISTORY tabs | P1 |
| CUS-065 | Copy referral code | Rewards hub | 1. Tap the referral code | "Referral code copied to clipboard!" and pasting yields the same code | P2 |
| CUS-066 | SHARE APP | Rewards hub | 1. Tap SHARE APP | Share sheet opens; "App link & code copied!" where applicable | P2 |
| CUS-067 | REFER FRIEND — form | Rewards hub | 1. Tap REFER FRIEND | A form with the friend's name, mobile number and project selection | P1 |
| CUS-068 | REFER FRIEND — validation | Refer form | 1. Submit with an empty name / bad phone / no project | The matching validation message appears and nothing is submitted | P1 |
| CUS-069 | REFER FRIEND — success | Refer form filled | 1. Submit | Success confirmation and the new referral appears in ACTIVE PIPELINE | P1 |
| CUS-070 | Active pipeline empty | No referrals | 1. Open ACTIVE PIPELINE | "NO ACTIVE LEADS" | P2 |
| CUS-071 | Point history | Points earned/spent | 1. Open POINT HISTORY | Credit and debit entries with amounts, references and dates | P2 |
| CUS-072 | Point history empty | No transactions | 1. Open POINT HISTORY | "NO RECENT HISTORY" | P2 |
| CUS-073 | REDEEM POINTS — catalog | Rewards hub | 1. Tap REDEEM POINTS | "REDEEM REWARDS / CONVERT YOUR POINTS" with the redemption catalog and the wallet balance | P1 |
| CUS-074 | Redeem — no option chosen | Redeem screen | 1. Tap CONFIRM REDEMPTION without selecting | "Please select a redemption option" | P1 |
| CUS-075 | Redeem — insufficient points | Balance below the requirement | 1. Choose an option and confirm | "Insufficient points" — nothing is deducted | P1 |
| CUS-076 | Redeem — success | Sufficient balance | 1. Choose an option, enter the amount, confirm | "Redemption Request Submitted" and the balance updates | P1 |
| CUS-077 | Redeem — failure | Backend failing | 1. Confirm a redemption | "Redemption failed" and the balance is unchanged | P2 |

### 6.6 Notifications (customer / all portals)

| TC ID | Test Scenario | Pre-condition | Steps | Expected Result | Pri |
|---|---|---|---|---|---|
| CUS-078 | Notification list | Notifications exist | 1. Open Notifications | "NOTIFICATIONS / STAY UPDATED" with entries showing title, description and date (`MMM d, y`) | P1 |
| CUS-079 | CP wording | Logged in as CP | 1. Open Notifications | The subtitle reads "PARTNER UPDATES" instead of "STAY UPDATED" | P3 |
| CUS-080 | Unread indication | Unread notifications | 1. Open the list | Unread entries are visually distinct from read ones | P2 |
| CUS-081 | MARK ALL | Unread notifications | 1. Tap MARK ALL | All entries become read and the unread badge/count clears | P1 |
| CUS-082 | Open a notification | Any notification | 1. Tap an entry | It expands / opens its target and is marked as read | P2 |
| CUS-083 | Empty state | No notifications | 1. Open Notifications | "NO NOTIFICATIONS — We'll notify you when something important happens." | P2 |
| CUS-084 | Load failure | Backend failing | 1. Open Notifications | A readable error with a retry option | P2 |

---

## 7. CV — Custom Views / personalisation

The wizard has 4 steps: **PROJECT & UNIT → SELECT SPACE → CHOOSE MATERIALS → FINALISE**.

| TC ID | Test Scenario | Pre-condition | Steps | Expected Result | Pri |
|---|---|---|---|---|---|
| CV-001 | Wizard entry | Logged-in customer with an allotted unit | 1. Open Custom Views | "M4 CUSTOM VIEWS / PERSONALISATION SUITE" with the 4-step track and the OVERVIEW / FINALISE header | P1 |
| CV-002 | Step track state | Wizard open | 1. Move through the steps | The active step icon is highlighted and completed steps are marked; the track never overflows at 1.5x font scale | P2 |
| CV-003 | Step 1 — project selection | Step 1 | 1. Open PROJECT SELECTION | Projects are listed with title and location; selecting one fills the PROJECT and LOCATION fields | P1 |
| CV-004 | Step 1 — unit configuration | Step 1 | 1. Enter UNIT NUMBER, BLOCK / TOWER, WING | The values are accepted and retained when moving to the next step | P1 |
| CV-005 | Step 1 — allotted unit prefill | Unit already allotted | 1. Open the wizard from MY PROPERTIES | The "UNIT ALLOTTED / ALLOTTED" state shows and the unit fields are pre-filled | P1 |
| CV-006 | NEXT STEP validation | Step 1 incomplete | 1. Tap NEXT STEP without a project/unit | The wizard blocks the move and indicates what is missing | P1 |
| CV-007 | Step 2 — select spaces | Step 2 | 1. Select one or more spaces (e.g. Master Bedroom) | Selected spaces are highlighted and carried into step 3 | P1 |
| CV-008 | Step 2 — deselect | A space selected | 1. Tap it again | It is deselected and removed from the selection | P2 |
| CV-009 | Step 2 — no space selected | Step 2 | 1. Tap NEXT STEP with nothing selected | Blocked, or defaults to "Full Unit" consistently with the summary shown later | P2 |
| CV-010 | Step 3 — material categories | Step 3 | 1. Open each space | Categories (e.g. flooring, doors, bath, lighting) with selectable options load from the project config | P1 |
| CV-011 | Step 3 — generic fallback | Project with no matching config | 1. Open a space | Generic categories are shown instead of an empty screen | P2 |
| CV-012 | Step 3 — option selection | Step 3 | 1. Choose an option in a category | The choice is highlighted and reflected in the FINALISE summary | P1 |
| CV-013 | BACK between steps | Any step after the first | 1. Tap BACK | Returns to the previous step with all earlier choices intact | P1 |
| CV-014 | Step 4 — summary | Step 4 | 1. Open FINALISE | A summary listing every space and every chosen specification | P1 |
| CV-015 | CONFIRM SELECTIONS | Step 4 | 1. Tap CONFIRM SELECTIONS | "Selections successfully saved!" and the submission appears in the selection history with status SUBMITTED | P1 |
| CV-016 | Save failure | Backend failing | 1. Confirm the selections | "Failed to save selections." and the wizard keeps the choices so the user can retry | P1 |
| CV-017 | My Custom Views — units tab | Customer with units | 1. Open MY CUSTOM VIEWS | ASSET CUSTOMIZATION STATUS cards with UNIT NO., PROJECT and CONFIG | P1 |
| CV-018 | My Custom Views — empty | No units | 1. Open the screen | "NO UNITS FOUND" | P2 |
| CV-019 | START PERSONALISATION | Unit not yet personalised | 1. Tap START PERSONALISATION | The wizard opens for that unit | P1 |
| CV-020 | MANAGE SELECTION | Unit already submitted | 1. Tap MANAGE SELECTION | The existing selections load pre-filled for editing | P1 |
| CV-021 | Revision limit | Unit already modified twice | 1. Try to modify again | "Maximum modification limit reached (2 revisions)." and editing is blocked | P1 |
| CV-022 | 30-day window | Allotment older than 30 days | 1. Try to modify | "The 30-day modification window has expired." and editing is blocked | P1 |
| CV-023 | Status badges | Submissions in different states | 1. Review the cards | SUBMITTED / APPROVED / COMPLETED / PENDING badges match the backend status | P2 |
| CV-024 | Selection history | Past submissions exist | 1. Open the HISTORY tab | Entries with space, status and creation date; search narrows the list | P2 |
| CV-025 | History empty | No history | 1. Open HISTORY | "NO HISTORY FOUND" | P2 |
| CV-026 | Personalisation logs | Submissions exist | 1. Open Personalisation / Customization Logs | "CUSTOMIZATION LOGS / PREVIOUS SELECTIONS" with CHOSEN SPECIFICATIONS, PROTOCOL STATUS and LOGGED ON date | P1 |
| CV-027 | Logs — status values | Mixed statuses | 1. Review the entries | REQUESTED / PENDING / APPROVED / COMPLETED / REJECTED render correctly | P2 |
| CV-028 | Logs — empty | No logs | 1. Open the screen | "NO CUSTOMIZATION LOGS FOUND" with a START CUSTOMIZING action | P2 |
| CV-029 | Logs — MODIFY SPECS | A log entry open | 1. Tap MODIFY SPECS | The wizard opens pre-filled with that submission (subject to CV-021/022 limits) | P1 |
| CV-030 | Logs — search | Several logs | 1. Type in Search Records | Only matching records remain | P2 |

---

## 8. CP — Channel Partner portal

CP shell tabs: **Home · Tracker · Projects · Support · Profile**, plus the partner drawer.

### 8.1 CP shell, home & drawer

| TC ID | Test Scenario | Pre-condition | Steps | Expected Result | Pri |
|---|---|---|---|---|---|
| CP-001 | CP tabs | Logged in as CP | 1. Observe the bottom bar | 5 tabs: Home, Tracker, Projects, Support, Profile | P1 |
| CP-002 | Tab surfaces | CP portal | 1. Switch tabs | Home and Projects are deep-green showcase screens; Tracker, Support and Profile are cream | P2 |
| CP-003 | CP home renders | CP Home | 1. Open Home | Hero, "OUR PHILOSOPHY / Who We Are" and the Communities / Properties / Media sections | P1 |
| CP-004 | CP home empty states | No published data | 1. Open Home | "NO COMMUNITIES YET", "NO PROPERTIES YET", "NO MEDIA YET" placeholders — never blank sections | P2 |
| CP-005 | CP home interest form | CP Home | 1. Fill and submit the interest form | "Interest registered successfully!"; on failure "Could not submit right now. Please try again." | P1 |
| CP-006 | Partner drawer | CP portal | 1. Open the drawer | PARTNER MENU with Dashboard, Properties, Communities, Bookings, Custom Views, Content Hub, Media, Highlights, Events, Blog, Notifications, Support Hub, Profile, Enquiry; QUICK ACTIONS (Call, Whatsapp); LOGOUT | P1 |
| CP-007 | Drawer navigation | Drawer open | 1. Tap each entry | Each opens the correct CP screen | P1 |
| CP-008 | CP logout | CP portal | 1. Drawer or Profile → LOGOUT → YES | Signed out to the Guest shell; the session is cleared | P1 |
| CP-009 | CP identity shown | Logged in as CP | 1. Open Home / Profile | The partner's own first name / company name appear | P1 |

### 8.2 CP dashboard (`/cp/dashboard`)

| TC ID | Test Scenario | Pre-condition | Steps | Expected Result | Pri |
|---|---|---|---|---|---|
| CP-010 | KPI cards | CP with data | 1. Open the CP dashboard | AVAILABLE COMMISSION, TOTAL EARNED and ACTIVE LEADS cards with correct values and currency formatting | P1 |
| CP-011 | Zero-state KPIs | New CP account | 1. Open the dashboard | KPIs show 0 rather than blank or `null` | P2 |
| CP-012 | Registered leads list | CP with leads | 1. Scroll to REGISTERED LEADS | Lead rows with client name, phone and project | P1 |
| CP-013 | Leads empty state | CP with no leads | 1. Open the dashboard | "No prospects identified." | P2 |
| CP-014 | Search prospects | Several leads | 1. Type a name in Search Prospects | Only matching leads remain; clearing restores the full list | P1 |
| CP-015 | Lead filter | Several leads | 1. Use FILTER | The list filters by the selected criterion | P2 |
| CP-016 | CALL CLIENT | A lead with a phone number | 1. Tap CALL CLIENT | The dialler opens with that client's number | P1 |
| CP-017 | UPDATE STATUS | A lead row | 1. Tap UPDATE STATUS<br>2. Choose CLEARED | "Status updated" and the row reflects the new status immediately | P1 |
| CP-018 | Status — LOST | A lead row | 1. Set the status to LOST | The status persists after leaving and reopening the screen | P1 |
| CP-019 | Status update failure | Backend failing | 1. Update a status | A readable error is shown and the old status is retained | P2 |
| CP-020 | Payment journey | Lead with payments | 1. Open PAYMENT JOURNEY | The milestone progression renders with correct stages | P2 |
| CP-021 | Load failure | Backend failing | 1. Open the dashboard | "Load failed" with a retry path — no crash | P2 |
| CP-022 | View all leads | Dashboard | 1. Tap "View all" | The full lead/tracker list opens | P2 |

### 8.3 CP tracker (`/cp/tracker`)

| TC ID | Test Scenario | Pre-condition | Steps | Expected Result | Pri |
|---|---|---|---|---|---|
| CP-023 | Tracker summary | CP with data | 1. Open the Tracker tab | "SUCCESS PIPELINE" with BOOKINGS, COMMISSION, SETTLED and VISITS counters | P1 |
| CP-024 | Tracker rows | Tracker has entries | 1. Review an entry | PROJECT, PROPERTY INFO (UNIT, TYPE/config), FINANCIAL PULSE and VERIFICATION LIFECYCLE are shown | P1 |
| CP-025 | Status values | Mixed entries | 1. Review the statuses | PENDING / In Progress / COMPLETED / Cancelled / INITIATED / CLEARED render correctly; unknown values show UNKNOWN, never a crash | P2 |
| CP-026 | Tracker search | Several entries | 1. Type in Search Prospects | Only matching entries remain | P1 |
| CP-027 | Tracker empty | No entries | 1. Open the Tracker | A clear empty state is shown, not a blank screen | P2 |
| CP-028 | Calendar strip | Tracker | 1. Review the date strip | Weekday initials M–S and month/year (`MMM yyyy`) render correctly with no overflow | P3 |
| CP-029 | Embedded vs standalone | Tracker opened from the tab and from the drawer | 1. Open it both ways | Both render correctly; the embedded version has no duplicate app bar | P2 |

### 8.4 CP visits & bookings

| TC ID | Test Scenario | Pre-condition | Steps | Expected Result | Pri |
|---|---|---|---|---|---|
| CP-030 | Visits screen tabs | CP with visits | 1. Open `/cp/visits` | "PERFORMANCE TRACKER" with VISIT TRACKING and PAYMENT TRACKER tabs | P1 |
| CP-031 | Visit rows | Visits exist | 1. Review a row | LEAD CLIENT, HANDLED BY, PROJECT FOCUS, CONFIGURATION and the visit date (`MMM d, y`) | P1 |
| CP-032 | Visit search | Several visits | 1. Type in Search Visits | Only matching visits remain | P1 |
| CP-033 | Project filter | Several projects | 1. Filter by project / choose ALL PROJECTS | The list filters correctly and ALL PROJECTS restores everything | P2 |
| CP-034 | Visit status change | A visit row | 1. Change the status (e.g. INTERESTED) | The status updates and persists; on failure "Update failed" is shown | P1 |
| CP-035 | Notify admin for settlement | A visit awaiting closure | 1. Tap the notify action | "Admin notified"; on failure "Could not notify admin" / "Failed to send notification" | P1 |
| CP-036 | AWAITING ADMIN CLOSURE | Visit already notified | 1. Review the row | Shows "AWAITING ADMIN CLOSURE" and the notify action is not repeatable | P2 |
| CP-037 | Contact the client | Visit with phone/e-mail | 1. Tap call / e-mail | Dialler or mail client opens; if none is available "Could not open" is shown | P2 |
| CP-038 | VIEW BOOKING | Visit converted to a booking | 1. Tap VIEW BOOKING | The related booking opens | P2 |
| CP-039 | Pagination | More than one page of visits | 1. Scroll to the end | The next page loads (page/totalPages honoured); no duplicates | P2 |
| CP-040 | Load failure | Backend failing | 1. Open Visits | "Could not load visits" with Retry | P2 |
| CP-041 | My bookings list | CP with bookings | 1. Open `/cp/booking/my-bookings` | "CLIENT BOOKINGS" with CLIENT NAME, UNIT SPECS, LOCK-IN DATE, EMPLOYEE NAME and MILESTONE PAYMENT PROGRESSION | P1 |
| CP-042 | Bookings filter dropdown | Several projects | 1. Open the project filter | The dropdown opens fully within the screen width (no clipping) and filtering works | P1 |
| CP-043 | Bookings search | Several bookings | 1. Type in Search Bookings | Only matching bookings remain | P1 |
| CP-044 | Bookings empty | No bookings | 1. Open the screen | "NO ACTIVE BOOKINGS DISCOVERED YET" with a CHECK SCHEDULED VISITS action | P2 |
| CP-045 | Booking status badges | Mixed statuses | 1. Review the rows | confirmed / allotted / pending render correctly with the right colours | P2 |
| CP-046 | Call the client from a booking | Booking with a phone | 1. Tap call | The dialler opens with the number correctly prefixed (country code handling) | P2 |

### 8.5 CP site visit & inquiry

| TC ID | Test Scenario | Pre-condition | Steps | Expected Result | Pri |
|---|---|---|---|---|---|
| CP-047 | CP site-visit form | CP logged in | 1. Open `/cp/booking/site-visit` | FULL NAME, PHONE NUMBER, E-MAIL, VISIT TYPE, SELECT PROJECT, HANDLED BY (EMPLOYEE), SCHEDULE date/time and ADDITIONAL NOTES | P1 |
| CP-048 | Form must not prefill with the CP's own data | CP logged in | 1. Open the form | Client fields are **empty** — the partner enters the client's details, not their own | P1 |
| CP-049 | Required fields | Form open | 1. Submit an incomplete form | "Please complete all fields" | P1 |
| CP-050 | Client name validation | Form open | 1. Leave the name empty / enter digits | "Enter the client name" / letters-only rule applies | P1 |
| CP-051 | Client number validation | Form open | 1. Enter a 5-digit number | "Enter a valid 10-digit number" | P1 |
| CP-052 | Client e-mail validation | Form open | 1. Enter `abc@` | "Enter a valid email address" | P1 |
| CP-053 | Project selection | Form open | 1. Open SELECT PROJECT | "CHOOSE PROJECT" list loads; on failure "Error loading projects" is shown | P1 |
| CP-054 | Employee selection | CP with employees | 1. Open HANDLED BY (EMPLOYEE) | "SELECT EMPLOYEE" list loads with the CP's own employees | P1 |
| CP-055 | No employees added | CP with no employees | 1. Open the employee selector | "NO EMPLOYEES ADDED" — the form can still be submitted where the field is optional | P2 |
| CP-056 | Visit type | Form open | 1. Open VISIT TYPE | "Video Call" and "Site Visit" options are available | P2 |
| CP-057 | Date & time | Form open | 1. Tap SCHEDULE | The wheel picker opens; the chosen slot shows as `dd MMM yyyy` + `hh:mm a` | P1 |
| CP-058 | Submit success | Complete form | 1. Submit | "Visit scheduled successfully!" and the visit appears under Visits | P1 |
| CP-059 | Submit failure | Backend failing | 1. Submit | "Failed to schedule visit" / "Connection problem. Please try again." — the form data is preserved | P2 |
| CP-060 | CP inquiry form | CP logged in | 1. Open `/cp/booking/inquiry` | Name, e-mail, phone, message fields and a PRIVACY POLICY checkbox with SUBMIT INTEREST | P1 |
| CP-061 | CP inquiry — privacy required | Form filled | 1. Submit without ticking privacy | "Please agree to the Privacy Policy" | P1 |
| CP-062 | CP inquiry — validation | Form open | 1. Submit with bad values | "Please fix the highlighted fields" and the offending fields turn red | P1 |
| CP-063 | CP inquiry — success | Valid form | 1. Submit | "Interest registered successfully!" | P1 |
| CP-064 | Register a client lead from a project | CP project detail | 1. Open the lead-registration sheet<br>2. Fill client name, number and e-mail<br>3. Submit | The lead is created with source `cp` and appears in the CP dashboard leads | P1 |

### 8.6 CP referral & rewards

| TC ID | Test Scenario | Pre-condition | Steps | Expected Result | Pri |
|---|---|---|---|---|---|
| CP-065 | Referral screen | CP logged in | 1. Open `/cp/referral` | "REFERRAL & REWARDS" with WALLET BALANCE, ACTIVE REFERRALS, REDEEM NOW, REFER FRIEND and SHARE CODE | P1 |
| CP-066 | Referral code | CP with a cpId | 1. Review the code | A code in the `M4FAM-CP…` format is shown | P2 |
| CP-067 | Copy the code | Referral screen | 1. Tap the code / SHARE CODE | "Referral code copied!" and the clipboard holds the same value | P2 |
| CP-068 | Referral list | CP with referrals | 1. Review ACTIVE REFERRALS | Rows with referral name, phone and project; CONVERTED entries are marked | P1 |
| CP-069 | Referral empty | No referrals | 1. Open the screen | "NO REFERRALS YET" | P2 |
| CP-070 | Submit referral — project required | Refer sheet | 1. Submit without choosing a project | "Please select a project" | P1 |
| CP-071 | Submit referral — name/phone validation | Refer sheet | 1. Submit with an empty name or short phone | The shared validation messages appear | P1 |
| CP-072 | Submit referral — success | Refer sheet filled | 1. Submit | "Referral registered!" and the referral appears in the list | P1 |
| CP-073 | Submit referral — failure | Backend failing | 1. Submit | "Failed" / "Submission error." — the entered data is preserved | P2 |
| CP-074 | Project list load failure | Backend failing | 1. Open SELECT PROJECT | "Could not load projects" — no crash | P2 |
| CP-075 | Redeem screen | CP referral screen | 1. Tap REDEEM NOW | "REDEEM REWARDS / CONVERT YOUR POINTS" with the REDEMPTION MATRIX (M4 WALLET CREDIT, BOOKING DISCOUNT, SHOPPING VOUCHERS, PRIORITY CONCIERGE) and AVAILABLE BALANCE | P1 |
| CP-076 | Redeem — no selection | Redeem screen | 1. Tap CONFIRM REDEMPTION | "Please select a redemption option" | P1 |
| CP-077 | Redeem — insufficient points | Balance too low | 1. Confirm a redemption | "Insufficient points" | P1 |
| CP-078 | Redeem — success | Sufficient balance | 1. Enter the amount and confirm | Success confirmation and the balance decreases accordingly | P1 |

### 8.7 CP payments, commissions & tax reports

| TC ID | Test Scenario | Pre-condition | Steps | Expected Result | Pri |
|---|---|---|---|---|---|
| CP-079 | Payments screen | CP with wallet data | 1. Open `/cp/payments` | "Wallet & history" with Available balance and Total earned plus the transaction list | P1 |
| CP-080 | Transaction filters | Transactions exist | 1. Filter by All / Commission / Withdrawal | Only the matching type is listed | P1 |
| CP-081 | Transaction search | Transactions exist | 1. Type in Search Transactions | Only matching rows remain | P2 |
| CP-082 | Payments empty | No transactions | 1. Open the screen | "No transactions yet" | P2 |
| CP-083 | Payment detail | Tap a transaction | 1. Open the detail | TYPE, DATE, BOOKING and COMMISSION ID are shown | P1 |
| CP-084 | Copy a reference | Payment detail | 1. Tap the commission ID | "Copied to clipboard" | P3 |
| CP-085 | Receipt export not ready | Payment detail | 1. Tap the receipt/export action | "Receipt export is not available yet." — no crash | P3 |
| CP-086 | Commission not found | Invalid id | 1. Open the detail with a bad id | "Commission not found" — no crash | P2 |
| CP-087 | Tax reports list | CP with reports | 1. Open `/cp/tax-reports` | "Tax Reports / FISCAL COMPLIANCE" with TOTAL TAX DEDUCTED and AVAILABLE DOCUMENTS | P1 |
| CP-088 | Year filter | Reports across years | 1. Change the year | Only that year's documents are listed | P1 |
| CP-089 | No reports for a year | Year with no data | 1. Select that year | "No reports found for this year." | P2 |
| CP-090 | Download summary | Reports exist | 1. Tap DOWNLOAD SUMMARY | "Downloading summary..." then the file opens/saves; if unavailable "Summary will be available soon." | P1 |
| CP-091 | Tax report detail | A report exists | 1. Open a report | VERIFIED DOCUMENT panel with TYPE, SIZE, DATE, YEAR, STATUS and DESCRIPTION | P1 |
| CP-092 | Download a tax document | Report detail | 1. Tap DOWNLOAD DOCUMENT | The document downloads/opens successfully | P1 |
| CP-093 | Report not found | Invalid id | 1. Open a bad report id | "Report not found" — no crash | P2 |

### 8.8 CP Hub (`/cp/hub` and sub-screens)

| TC ID | Test Scenario | Pre-condition | Steps | Expected Result | Pri |
|---|---|---|---|---|---|
| CP-094 | Hub landing | CP logged in | 1. Open the CP Hub | "TOOL MATRIX" with Reports, Analytics, Network and Concierge tiles plus TOTAL ASSET PORTFOLIO and MY HOLDINGS | P1 |
| CP-095 | Hub tiles navigate | Hub open | 1. Tap each tile | Each opens its screen (`/cp/hub/reports`, `/analytics`, `/network`, `/insights`, `/calculator`) | P1 |
| CP-096 | Holdings empty | No holdings | 1. Open the Hub | "NO HOLDINGS YET" with an EXPLORE OPPORTUNITIES action | P2 |
| CP-097 | Analytics screen | CP with performance data | 1. Open Analytics | Total leads, Bookings/conversions, Conversion rate, Total commission, Paid commission and the growth chart | P1 |
| CP-098 | Analytics zero-state | New CP | 1. Open Analytics | All metrics show 0 / an empty chart — no `null` and no crash | P2 |
| CP-099 | Calculator inputs | Calculator open | 1. Enter Investment Amount, Duration (Years) and Expected ROI | PROJECTED MATURITY VALUE recalculates live and correctly | P1 |
| CP-100 | Calculator edge values | Calculator open | 1. Enter 0, a negative value and a very large value | No crash, no `NaN`/`Infinity` shown; invalid input is handled gracefully | P2 |
| CP-101 | Network screen | Network open | 1. Open Network | TOTAL REFERRALS and COMMISSION counters, Upcoming Events and Member Spotlight | P1 |
| CP-102 | Network RSVP | An event listed | 1. Tap RSVP NOW | "RSVP received" | P2 |
| CP-103 | Network empty states | No data | 1. Open Network | "Events coming soon", "No referrals in your network yet", "Forum coming soon" | P2 |
| CP-104 | Reports screen | Reports open | 1. Open Reports | TOTAL TAX DEDUCTED, the document list with type badges (PDF/XLSX/CSV/DOC) and Download / Share / More actions | P1 |
| CP-105 | Report download | A report exists | 1. Tap Download / Open / Print PDF | The file opens or saves correctly | P1 |
| CP-106 | Report share | A report exists | 1. Tap Share | The OS share sheet opens with the document | P2 |
| CP-107 | Reports empty | No reports for the year | 1. Open Reports | "Check back soon or select another year" | P2 |
| CP-108 | Insights screen | Insights open | 1. Open Insights | "DAILY PULSE" with conversion metrics and the Latest Analysis article list | P2 |
| CP-109 | Read an insight | An article exists | 1. Tap READ / READ REPORT | The article opens; where no content exists "Content coming soon" / "Report coming soon" | P2 |

### 8.9 CP employees (team management)

| TC ID | Test Scenario | Pre-condition | Steps | Expected Result | Pri |
|---|---|---|---|---|---|
| CP-110 | Employees list | CP with employees | 1. Open `/cp/profile/employees` | "TEAM MANAGEMENT / MANAGE YOUR PORTAL EMPLOYEES" with rows showing name, phone, e-mail and an ACTIVE/INACTIVE badge | P1 |
| CP-111 | Search employees | Several employees | 1. Type in Search Employees | Only matching rows remain; no match → "NO MATCHING TEAM MEMBERS" | P1 |
| CP-112 | Add employee — form | Employees screen | 1. Tap add | "ADD NEW EMPLOYEE" with FULL NAME, PHONE NUMBER (10 DIGITS) and EMAIL ADDRESS | P1 |
| CP-113 | Add — name validation | Add sheet | 1. Enter digits in the name / leave it empty | Digits are blocked as typed; empty shows "Please enter your full name" | P1 |
| CP-114 | Add — phone validation | Add sheet | 1. Enter fewer than 10 digits | "Please enter a valid 10-digit phone number" | P1 |
| CP-115 | Add — e-mail validation | Add sheet | 1. Enter a malformed e-mail | "Please enter a valid email address" | P1 |
| CP-116 | Add — success | Valid data | 1. Tap ADD EMPLOYEE | "Employee added successfully" and the new row appears | P1 |
| CP-117 | Add — failure | Backend failing | 1. Submit | "Failed to add employee" and the sheet stays open with the data | P2 |
| CP-118 | Edit employee | Employee exists | 1. Tap edit → change a value → SAVE CHANGES | "Employee updated successfully" and the row updates | P1 |
| CP-119 | Delete employee — confirm | Employee exists | 1. Tap delete | "DELETE EMPLOYEE" confirmation with CANCEL and DELETE | P1 |
| CP-120 | Delete — cancel | Confirmation open | 1. Tap CANCEL | The employee is kept | P1 |
| CP-121 | Delete — confirm | Confirmation open | 1. Tap DELETE | "Employee deleted successfully" and the row disappears | P1 |
| CP-122 | Saving state | Add/Edit sheet | 1. Submit and watch the button | Shows "SAVING..." and is disabled until the call completes | P2 |
| CP-123 | Load failure | Backend failing | 1. Open the screen | "Failed to load employees" / "Something went wrong" with RETRY | P2 |
| CP-124 | Employee appears in site visit | Employee just added | 1. Open the CP site-visit form → HANDLED BY | The new employee is selectable | P1 |

### 8.10 CP profile, security & account

| TC ID | Test Scenario | Pre-condition | Steps | Expected Result | Pri |
|---|---|---|---|---|---|
| CP-125 | CP profile screen | Profile tab | 1. Open Profile | Avatar, name, company, e-mail, phone, RERA number, TEAM & ACCESS and QUICK ACTIONS (Visit, Booking, Tracker) | P1 |
| CP-126 | Missing values | Account with blanks | 1. Open Profile | "Not provided" placeholders instead of blanks | P2 |
| CP-127 | Quick action tiles | Profile | 1. Tap Book Visit / Booking / Tracker | Each opens the correct screen | P1 |
| CP-128 | EMPLOYEE MANAGEMENT | Profile | 1. Tap it | The employees screen opens | P1 |
| CP-129 | Profile details — edit | `/cp/profile/details` | 1. Edit the name/e-mail/phone/address → SAVE CHANGES | "Profile updated successfully" and the change is reflected immediately | P1 |
| CP-130 | Profile details — cancel | Details screen | 1. Edit a field and tap CANCEL | The change is discarded and the original values return | P2 |
| CP-131 | Profile details — validation | Details screen | 1. Save with an empty name / bad e-mail / bad phone | The shared validation messages appear and nothing is saved | P1 |
| CP-132 | Avatar upload | Details / settings | 1. Pick an image under 2 MB | "Profile photo updated" and the new avatar shows | P1 |
| CP-133 | Avatar over 2 MB | Details / settings | 1. Pick a large image | "File too large (max 2MB)" | P1 |
| CP-134 | Profile settings | `/cp/profile/settings` | 1. Open the screen | ACCOUNT IDENTITY and CONFIGURATION sections with SAVE CHANGES | P1 |
| CP-135 | Security passcode | Profile settings | 1. Open UPDATE SECURITY PASSCODE<br>2. Enter a passcode shorter than 4 digits | "Passcode must be at least 4 digits" | P1 |
| CP-136 | Passcode mismatch | Passcode sheet | 1. Enter mismatching values | "New passcodes do not match" | P1 |
| CP-137 | Passcode success | Passcode sheet | 1. Enter a valid matching passcode | "Passcode updated successfully" | P1 |
| CP-138 | Change password — empty | `/cp/change-password` | 1. Submit with empty fields | "Please fill in all fields" | P1 |
| CP-139 | Change password — mismatch | Change-password screen | 1. Enter mismatching new passwords | "New passwords do not match" | P1 |
| CP-140 | Change password — too short | Change-password screen | 1. Enter a 6-character password | "Password must be at least 8 characters" | P1 |
| CP-141 | Password requirement hints | Change-password screen | 1. Type a password progressively | The REQUIREMENTS checklist (8+ chars, uppercase, number, special character) ticks off live | P2 |
| CP-142 | Change password — success | Valid input | 1. Tap UPDATE PASSWORD | "Password updated successfully" | P1 |
| CP-143 | Login with the new password | Password just changed | 1. Log out and sign in with the new password | Login succeeds; the old password fails | P1 |
| CP-144 | Change password — wrong current | Change-password screen | 1. Enter a wrong current password | "Failed to update password" / the server's message; the password is unchanged | P1 |
| CP-145 | Security screen | `/cp/security` | 1. Open it | ACCOUNT PROTECTION with Biometric Login, Two-Factor Auth and RECENT ACTIVITY | P1 |
| CP-146 | Biometric toggle | Security screen | 1. Toggle Biometric Login | "Biometric login enabled" / "Biometric login disabled" and the state persists | P1 |
| CP-147 | Sign out of all devices | Security screen | 1. Tap SIGN OUT OF ALL DEVICES and confirm | "Signed out of all devices"; other sessions can no longer use the old token | P1 |
| CP-148 | Purge cache | `/cp/profile/purge-cache` | 1. Tap PURGE CACHE & REBUILD | Progress indicators run through the scope items and "Cache purged. The app cache has been rebuilt." is shown; the app remains usable | P1 |
| CP-149 | Delete account — scope | `/cp/profile/delete-account` | 1. Open the screen | WHAT WILL BE ERASED lists profile & identity, referrals & leads, wallet & commissions, bookings & visits, access history | P1 |
| CP-150 | Delete — password required | Delete screen | 1. Tap PERMANENTLY DELETE ACCOUNT without a password | Blocked with a clear message | P1 |
| CP-151 | Delete — final confirmation | Password entered | 1. Tap PERMANENTLY DELETE ACCOUNT | "FINAL CONFIRMATION" dialog with CANCEL and DELETE FOREVER | P1 |
| CP-152 | Delete — keep the account | Confirmation open | 1. Tap CANCEL / KEEP MY ACCOUNT | The account is untouched | P1 |
| CP-153 | Delete — execute | Confirmation open | 1. Tap DELETE FOREVER | "Your account has been permanently deleted", the user is signed out and cannot sign back in | P1 |
| CP-154 | Delete — wrong password | Delete screen | 1. Enter a wrong password and confirm | "Failed to delete account" / the server's message; the account survives | P1 |

### 8.11 CP Elite & connect screens

| TC ID | Test Scenario | Pre-condition | Steps | Expected Result | Pri |
|---|---|---|---|---|---|
| CP-155 | Elite dashboard | `/cp/elite` | 1. Open it | "MEMBER DASHBOARD / PLATINUM MEMBER" with Active Membership, Priority Booking and Rewards Balance plus the DOCUMENT REPOSITORY | P2 |
| CP-156 | Elite documents | Documents exist | 1. Tap a document | It previews/opens; when unavailable "Could not open document" / "Preview not available in demo" is shown — no crash | P2 |
| CP-157 | Elite documents empty | No documents | 1. Open the repository | "NO DOCUMENTS YET" | P2 |
| CP-158 | Elite upgrade | Elite screen | 1. Tap UPGRADE MEMBERSHIP TIER | "Membership upgrade coming soon" — no dead button | P3 |
| CP-159 | CP Connect | `/cp/elite/cp-connect` | 1. Open it | "INSTITUTIONAL CP NETWORK / VERIFIED NODE MATRIX" with partner cards and a search field | P2 |
| CP-160 | CP Connect search | Connect screen | 1. Search for a partner that does not exist | "NO MATCHES FOUND" | P2 |
| CP-161 | Investor Connect | `/cp/elite/investor-connect` | 1. Open it | Portfolio Value, Total ROI, Active Assets and HIGH-YIELD VENTURES | P2 |
| CP-162 | Investor Connect empty | No ventures | 1. Open it | "No ventures available right now" | P2 |
| CP-163 | Residential Connect | `/cp/elite/residential-connect` | 1. Open it | INSTITUTIONAL CONCIERGE with services and the UPDATE STREAM | P2 |
| CP-164 | Residential secure link | Residential Connect | 1. Tap INITIATE SECURE LINK | "Secure link coming soon." — no crash | P3 |

---

## 9. INV — Investor portal

Investor shell tabs: **Home · Projects · Support · Profile**, plus the investor drawer.

### 9.1 Investor shell & home

| TC ID | Test Scenario | Pre-condition | Steps | Expected Result | Pri |
|---|---|---|---|---|---|
| INV-001 | Investor tabs | Logged in as investor | 1. Observe the bottom bar | 4 tabs: Home, Projects, Support, Profile | P1 |
| INV-002 | Tab surfaces | Investor portal | 1. Switch tabs | Home and Projects are deep-green showcase screens; Support and Profile sit on the warm greige surface with cream cards | P2 |
| INV-003 | Investor home renders | Investor Home | 1. Open Home | Hero, philosophy section and the Communities / Properties / Media sections | P1 |
| INV-004 | Home empty states | No published data | 1. Open Home | Each section shows its own "NO … YET" placeholder rather than a blank area | P2 |
| INV-005 | Home interest form | Investor Home | 1. Fill and submit the interest form (privacy ticked) | "Interest registered successfully!" | P1 |
| INV-006 | Privacy required | Interest form | 1. Submit without the privacy tick | "Please agree to the Privacy Policy" | P1 |
| INV-007 | Investor drawer | Investor portal | 1. Open the drawer | INVESTOR MENU with Home, Properties, Communities, Investor Relations, Referral, Custom Views, My Custom Views, Content Hub, Media, Highlights, Events, Blog, Notifications, Who we are, Careers, Contact Us, Enquiry; QUICK ACTIONS (Call, Whatsapp); LOGOUT | P1 |
| INV-008 | Drawer navigation | Drawer open | 1. Tap each entry | Each opens the correct investor screen | P1 |
| INV-009 | Investor logout | Investor portal | 1. LOGOUT → YES | Signed out to the Guest shell; the session is cleared | P1 |
| INV-010 | Investor identity | Logged in | 1. Open Home / Profile | The investor's own name is shown (never "Investor" placeholder when real data exists) | P1 |

### 9.2 Investor projects & detail

| TC ID | Test Scenario | Pre-condition | Steps | Expected Result | Pri |
|---|---|---|---|---|---|
| INV-011 | Project list | Projects tab | 1. Open Projects | The full project catalogue with filters, identical behaviour to GST-024…035 | P1 |
| INV-012 | Project detail | Open a project | 1. Review the screen | Gallery (EXTERIOR / INTERIOR), overview, payment plans and the action rail | P1 |
| INV-013 | BOOK A SITE VISIT | Project detail | 1. Tap BOOK A SITE VISIT<br>2. Submit without a date/time | "Please select a date and time" | P1 |
| INV-014 | BOOK A VIDEO CALL | Project detail | 1. Choose Video Call, pick a slot and submit | Success: "Inquiry submitted! Our advisor will contact you shortly." | P1 |
| INV-015 | Submit failure | Backend failing | 1. Submit an inquiry | "Failed to submit inquiry" / "Connection error. Please try again." | P2 |
| INV-016 | 3D view | `/investor/projects/:id/3d-view` | 1. Open the 3D view | The immersive view loads; back returns to the detail screen | P2 |
| INV-017 | Contact links | Project detail | 1. Tap the phone/e-mail contacts | Dialler / mail client open; if unavailable "Unable to open link" | P2 |
| INV-018 | Favourite toggle | Project detail | 1. Tap save | "Saved to favorites" / "Removed from favorites" | P3 |
| INV-019 | Unimplemented action | Project detail | 1. Tap an action still in progress | "Coming soon" is shown — never a dead tap | P3 |

### 9.3 Investor portfolio & payments

| TC ID | Test Scenario | Pre-condition | Steps | Expected Result | Pri |
|---|---|---|---|---|---|
| INV-020 | Portfolio screen | Investor with holdings | 1. Open Portfolio | PORTFOLIO VALUATION, CURRENT MARKET VALUE, CAPITAL DEPLOYED, ACTIVE HOLDINGS, UNREALISED GAINS and AVG YIELD | P1 |
| INV-021 | Holding cards | Holdings exist | 1. Review a card | INVESTED, CURRENT VALUE, UNITS / STAKE, YIELD, NET RETURN and a VERIFIED INVESTMENT badge | P1 |
| INV-022 | Number formatting | Holdings exist | 1. Check the currency and percentage values | Values are formatted consistently (currency symbol, separators, 2 decimals for percentages); no raw floats or `null` | P1 |
| INV-023 | VIEW PERFORMANCE | A holding | 1. Tap VIEW PERFORMANCE | The performance detail opens for that holding | P2 |
| INV-024 | Portfolio empty | No investments | 1. Open Portfolio | "NO INVESTMENTS YET — Your portfolio holdings will appear here." with EXPLORE OPPORTUNITIES | P2 |
| INV-025 | Portfolio error | Backend failing | 1. Open Portfolio | "UNABLE TO LOAD PORTFOLIO" with RETRY | P2 |
| INV-026 | Payments ledger | Investor with payments | 1. Open `/investor/payments` | "Payment History / FINANCIAL LEDGER" with TOTAL INVESTED and TOTAL RETURNS and the transaction list | P1 |
| INV-027 | Payment direction | Mixed transactions | 1. Review the rows | PAID entries read as inbound and pending/others as outbound, matching the amount signs and icons | P2 |
| INV-028 | Payments search | Transactions exist | 1. Type in Search Transactions | Only matching rows remain | P2 |
| INV-029 | Payments empty | No transactions | 1. Open the screen | "No transactions found — Your payment ledger is empty." | P2 |
| INV-030 | Payments error | Backend failing | 1. Open the screen | "Unable to load payments — Please check your connection and try again." with RETRY | P2 |
| INV-031 | Payment detail | Tap a transaction | 1. Open it | TYPE, DATE, PROJECT, MILESTONE, DESCRIPTION and REFERENCE ID | P1 |
| INV-032 | Copy reference | Payment detail | 1. Tap the reference id | "Copied to clipboard" | P3 |
| INV-033 | Receipt / share not ready | Payment detail | 1. Tap receipt / SHARE | "Receipt export is not available yet." / "Sharing is not available yet." — no crash | P3 |
| INV-034 | GET HELP from a payment | Payment detail | 1. Tap GET HELP | "Support ticket created" and the ticket appears under Support | P1 |
| INV-035 | Transaction not found | Invalid id | 1. Open a bad transaction id | "Transaction not found — The requested transaction could not be found." | P2 |
| INV-036 | Installments schedule | Investor with a plan | 1. Open `/investor/installments` | "INSTALLMENT SCHEDULE / PAYMENT PLAN" with DUE / REMAINING and the instalment list | P1 |
| INV-037 | Installment filters | Mixed instalments | 1. Filter by All / PAID / PENDING / OVERDUE | Only matching instalments remain | P1 |
| INV-038 | Overdue highlighting | An overdue instalment exists | 1. Review the list | OVERDUE entries are visually distinct and the due date is correct | P1 |
| INV-039 | Installments empty | No instalments | 1. Open the screen | "NO INSTALLMENTS FOUND" | P2 |
| INV-040 | Installments error | Backend failing | 1. Open the screen | "COULD NOT LOAD SCHEDULE — Please check your connection and try again." with RETRY | P2 |

### 9.4 Investor documents & tax reports

| TC ID | Test Scenario | Pre-condition | Steps | Expected Result | Pri |
|---|---|---|---|---|---|
| INV-041 | Documents list | Investor with documents | 1. Open `/investor/documents` | "LEGAL VAULT / SECURE REPOSITORY" with document rows (type, issue date, size) | P1 |
| INV-042 | Document filters | Mixed document types | 1. Filter by Agreement / Receipt / Plan / Booking | Only the selected type is listed | P2 |
| INV-043 | Documents empty | No documents | 1. Open the screen | "NO DOCUMENTS FOUND" | P2 |
| INV-044 | Documents error | Backend failing | 1. Open the screen | "Failed to load secure documents" / "Something went wrong" with RETRY | P2 |
| INV-045 | Document detail | Open a document | 1. Review it | DOCUMENT OVERVIEW with ISSUE DATE, FILE SIZE and "ENCRYPTED & VERIFIED" status | P1 |
| INV-046 | OPEN SECURE LINK | Document with a file | 1. Tap OPEN SECURE LINK | The document opens in the viewer/browser | P1 |
| INV-047 | Missing secure link | Document without a file | 1. Tap OPEN SECURE LINK | "Secure link not available for this document" — no crash | P2 |
| INV-048 | Document not found | Invalid id | 1. Open a bad id | "DOCUMENT NOT FOUND — The requested document could not be found." with RETRY / CLOSE | P2 |
| INV-049 | Tax reports | Investor with reports | 1. Open `/investor/tax-reports` | "Tax Reports / FISCAL COMPLIANCE" with TOTAL TAX DEDUCTED and AVAILABLE DOCUMENTS | P1 |
| INV-050 | Year filter | Reports across years | 1. Change the year | Only that year's documents are listed; empty years show "No reports found for this year." | P1 |
| INV-051 | Download summary | Reports exist | 1. Tap DOWNLOAD SUMMARY | "Downloading summary..." then the file opens/saves | P1 |
| INV-052 | Tax report detail | A report exists | 1. Open it | VERIFIED DOCUMENT with GENERATED ON, STATUS (Ready/Pending) and DESCRIPTION | P1 |
| INV-053 | View / download | Report detail | 1. Tap VIEW DOCUMENT then DOWNLOAD DOCUMENT | The document opens and downloads correctly | P1 |
| INV-054 | Report not found | Invalid id | 1. Open a bad id | "Report not found" — no crash | P2 |
| INV-055 | Tax reports error | Backend failing | 1. Open the list | "Unable to load tax reports." with RETRY | P2 |

### 9.5 Investor referral & rewards

| TC ID | Test Scenario | Pre-condition | Steps | Expected Result | Pri |
|---|---|---|---|---|---|
| INV-056 | Referral hub | `/investor/referral` | 1. Open it | "REFERRAL & REWARDS" with MY REFERRAL IDENTITY CODE, POINTS, REFERRALS, ACTIVE REFERRALS and POINT HISTORY | P1 |
| INV-057 | Copy the code | Referral hub | 1. Tap the code | "Referral code copied to clipboard!" | P2 |
| INV-058 | SHARE CODE | Referral hub | 1. Tap SHARE CODE | The share sheet opens; "Referral link copied to clipboard!" where applicable | P2 |
| INV-059 | Stat tap navigation | Referral hub | 1. Tap the POINTS and REFERRALS stat tiles | Each navigates to its own screen (rewards / referral list) rather than doing nothing | P2 |
| INV-060 | Referral dropdown UI | REFER FRIEND sheet | 1. Open SELECT PROJECT | The dropdown renders fully inside the sheet width, is scrollable and closes on selection | P1 |
| INV-061 | REFER FRIEND — validation | Refer sheet | 1. Submit with an empty name / bad mobile / no project | The matching validation message appears | P1 |
| INV-062 | REFER FRIEND — success | Refer sheet filled | 1. Submit | Success confirmation and the referral appears under ACTIVE REFERRALS | P1 |
| INV-063 | Project load failure | Backend failing | 1. Open SELECT PROJECT | "COULD NOT LOAD PROJECTS" — no crash | P2 |
| INV-064 | Active referrals screen | `/investor/referral/active` | 1. Open it | "ACTIVE REFERRALS / LEAD MATRIX" with PIPELINE STATUS per lead | P1 |
| INV-065 | Active referrals empty | No active referrals | 1. Open it | "NO ACTIVE REFERRALS IN PIPELINE" | P2 |
| INV-066 | Closed referrals screen | `/investor/referral/closed` | 1. Open it | "SUCCESS VAULT / CLOSED CONVERSIONS" with UNIT CONFIG, REWARD EARNED and a CONVERTED badge | P1 |
| INV-067 | Closed referrals empty | No closed referrals | 1. Open it | "NO CLOSED REFERRALS YET" | P2 |
| INV-068 | Referral load error | Backend failing | 1. Open either referral screen | "COULD NOT LOAD REFERRALS" / "COULD NOT LOAD SUCCESS VAULT" with RETRY | P2 |
| INV-069 | Redeem rewards | Referral hub | 1. Tap REDEEM REWARDS | The redemption screen opens with the wallet balance and the catalog | P1 |
| INV-070 | Redeem validation & success | Redeem screen | 1. Confirm with no option, then with insufficient points, then correctly | "Please select a redemption option" → "Insufficient points" → success with an updated balance | P1 |
| INV-071 | Reward hub load failure | Backend failing | 1. Open the referral hub | "FAILED TO LOAD REWARD HUB" with RETRY | P2 |

### 9.6 Investor profile, settings & account

| TC ID | Test Scenario | Pre-condition | Steps | Expected Result | Pri |
|---|---|---|---|---|---|
| INV-072 | Investor profile | Profile tab | 1. Open Profile | Avatar, name, e-mail, phone, address, POINTS and the FAMILY / PROPERTY SERVICES / MANAGEMENT & SUPPORT tiles | P1 |
| INV-073 | Avatar theming | Profile tab | 1. Review the avatar on the profile surface | The avatar and its ring use the investor surface colours correctly in every state (with and without a photo) | P2 |
| INV-074 | Missing values | Account with blanks | 1. Open Profile | "no email provided" / "Not provided" / "No address provided" placeholders | P2 |
| INV-075 | Profile tiles | Profile | 1. Tap My Family, My Properties, My Custom Views, M4 Referral Program | Each opens the correct screen | P1 |
| INV-076 | Profile details — edit & save | `/investor/profile/details` | 1. Edit fields including DATE OF BIRTH → SAVE CHANGES | "Profile updated successfully" and the values persist after reopening | P1 |
| INV-077 | Date of birth picker | Details screen | 1. Tap SELECT DATE | The picker opens; the chosen date shows as `d MMM y` and a future date is not accepted | P2 |
| INV-078 | Details — validation | Details screen | 1. Save with an empty name / bad e-mail / bad phone | The shared validation messages appear | P1 |
| INV-079 | Settings screen | `/investor/settings` | 1. Open it | PERSONAL DETAIL, SECURITY & ACCESS (BIOMETRIC LOGIN), NOTIFICATIONS (PORTFOLIO & DEAL ALERTS) and PRIVACY MODE (MASK SENSITIVE VALUES) | P1 |
| INV-080 | Toggle & save settings | Settings screen | 1. Toggle each switch → SAVE | "Preferences updated securely" and the toggles keep their state after reopening | P1 |
| INV-081 | Privacy mode masks values | Privacy mode ON | 1. Open Portfolio / Payments | Sensitive amounts are masked | P2 |
| INV-082 | Settings save failure | Backend failing | 1. Save | "Could not save changes. Try again." | P2 |
| INV-083 | Settings load failure | Backend failing | 1. Open Settings | "Unable to load your settings. Please try again." with RETRY | P2 |
| INV-084 | Sign out on all devices | Settings / Security | 1. Tap SIGN OUT ON ALL DEVICES → confirm | "Signed out of all devices"; other sessions stop working | P1 |
| INV-085 | Security screen | `/investor/security` | 1. Open it | ACCOUNT PROTECTION, AUTHENTICATION toggles and RECENT ACTIVITY sessions (device, location, time, Active / Logged out) | P1 |
| INV-086 | Recent activity empty | No sessions recorded | 1. Open Security | "No recent activity — Your login sessions will appear here." | P2 |
| INV-087 | Recent activity error | Backend failing | 1. Open Security | "Could not load activity" with RETRY | P2 |
| INV-088 | Change password — validation | `/investor/change-password` | 1. Submit empty → mismatching → short password | "Please fill in all fields" → "Security keys do not match" → "Password must be at least 8 characters" | P1 |
| INV-089 | Password strength meter | Change-password screen | 1. Type progressively stronger passwords | The meter moves through WEAK → FAIR → STRONG → ELITE and the REQUIREMENTS list ticks off live | P2 |
| INV-090 | Change password — success | Valid input | 1. Tap UPDATE PASSWORD | "Security key established successfully" / "Security credentials updated!" | P1 |
| INV-091 | Login with the new password | Password just changed | 1. Log out and sign in again | The new password works and the old one fails | P1 |
| INV-092 | Purge data | `/investor/profile/purge-cache` | 1. Tap INITIATE FULL RESET | Scope items run through with progress and "CORE PURGE COMPLETE" is shown; the app stays usable | P1 |
| INV-093 | Estimated cache size | Purge screen | 1. Tap Refresh | A plausible size in B/KB/MB/GB is shown — no `NaN` and no negative value | P3 |
| INV-094 | Delete account — scope | `/investor/profile/delete-account` | 1. Open it | PURGE SCOPE lists bookings, site-visit logs, legal documents, customizations and personal identity | P1 |
| INV-095 | Delete — password required | Delete screen | 1. Execute without a password | Blocked; "Password verification failed" on a wrong password | P1 |
| INV-096 | Delete — confirmation | Password entered | 1. Tap DEACTIVATE / EXECUTE PURGE | "FINAL CONFIRMATION" with CANCEL and EXECUTE PURGE | P1 |
| INV-097 | Delete — abort | Confirmation open | 1. Tap ABORT PROTOCOL / CANCEL | The account is untouched | P1 |
| INV-098 | Delete — execute | Confirmation open | 1. Confirm | "Account deactivated successfully", the user is signed out of every device and cannot sign back in | P1 |
| INV-099 | Delete — failure | Backend failing | 1. Confirm | "Failed to deactivate account" / "Network error" — the account survives | P2 |

### 9.7 Investor relations, CP screen & elite

| TC ID | Test Scenario | Pre-condition | Steps | Expected Result | Pri |
|---|---|---|---|---|---|
| INV-100 | Investor relations page | `/investor/relations` | 1. Open it | "INVESTOR RELATIONS / M4 FAMILY DEVELOPMENTS" with CMS content and the enquiry form | P1 |
| INV-101 | Relations form validation | Relations form | 1. Submit with empty first/last name, bad e-mail or bad phone | The matching validation messages appear | P1 |
| INV-102 | Preferred contact mode | Relations form | 1. Choose Phone or Email | The selection is applied and submitted with the enquiry | P2 |
| INV-103 | Relations — privacy required | Form filled | 1. Submit without the privacy tick | "Please agree to the Privacy Policy" | P1 |
| INV-104 | Relations — success | Valid form | 1. Submit | "Inquiry Submitted Successfully!" | P1 |
| INV-105 | Relations — failure | Backend failing | 1. Submit | "Submission failed. Please try again." | P2 |
| INV-106 | Investor CP screen | `/investor/cp` | 1. Open it | "Partner Dashboard" with REGISTERED LEADS and a REGISTER NEW LEAD action | P2 |
| INV-107 | Register a lead | CP screen | 1. Choose a project, enter the client name and mobile<br>2. SUBMIT LEAD | "Lead registered successfully." and the lead appears in the list | P1 |
| INV-108 | Lead validation | Register-lead sheet | 1. Submit with an empty name / bad mobile / no project | The matching validation messages appear | P1 |
| INV-109 | Leads empty / search | CP screen | 1. Search for a non-existent lead | "NO LEADS FOUND" | P2 |
| INV-110 | Investor elite | `/investor/elite` | 1. Open it | MEMBER DASHBOARD with the document repository, identical behaviour to CP-155…158 | P2 |
| INV-111 | Investor connect screens | `/investor/elite/cp-connect`, `/investor-connect`, `/residential-connect` | 1. Open each | Each renders its network/stats content with proper empty states ("NO MATCHES FOUND", "No co-investors in your network yet", "No deals to show right now") | P2 |
| INV-112 | Investor connect error | Backend failing | 1. Open Investor Connect | "Could not load the investor network. Please try again." / "Something went wrong" with RETRY | P2 |

---

## 10. BOOK — Booking & payment flows

Flow: **Booking start → (Inquiry | Site Visit | Payment plan → Token payment) → Confirmation**. Each portal has its own copy of the flow (`/…/booking/*`); run the whole section per portal that exposes it.

| TC ID | Test Scenario | Pre-condition | Steps | Expected Result | Pri |
|---|---|---|---|---|---|
| BOOK-001 | Booking start options | A project selected | 1. Open Booking start | Three options: SEND INQUIRY, SCHEDULE SITE VISIT and TOKEN BOOKING, each with its description and a LEARN MORE affordance | P1 |
| BOOK-002 | Option routing | Booking start | 1. Tap each option | Each routes to its own screen (inquiry / site-visit / payment-plan) for the same project | P1 |
| BOOK-003 | Project context is carried | Booking start opened from a project | 1. Proceed through any option | The correct project title appears on every subsequent screen | P1 |
| BOOK-004 | Inquiry screen layout | Inquiry open | 1. Review the screen | FULL IDENTITY, COMMUNICATIONS (e-mail), DIRECT LINE (phone), SPECIFIC BRIEFING (OPTIONAL) and AUTHORIZE INQUIRY | P1 |
| BOOK-005 | Inquiry validation | Inquiry open | 1. Submit with an empty name / bad e-mail / bad phone | The shared validation messages appear and nothing is sent | P1 |
| BOOK-006 | Inquiry success | Valid inquiry | 1. Submit | "REQUEST REGISTERED" confirmation with RETURN TO PROJECT | P1 |
| BOOK-007 | Inquiry failure | Backend failing | 1. Submit | "Failed to send inquiry" / "Error sending inquiry. Please try again." — the data is preserved | P2 |
| BOOK-008 | Site-visit screen layout | Site visit open | 1. Review the screen | FULL NAME, PHONE NUMBER, SELECT PROJECT, HANDLED BY (EMPLOYEE), SCHEDULE date/time, ADDITIONAL NOTES and SECURE BOOKING | P1 |
| BOOK-009 | Site-visit prefill | Logged-in user | 1. Open the screen | Name and phone are pre-filled from the profile; a guest sees empty fields | P2 |
| BOOK-010 | Site-visit validation | Site visit open | 1. Submit incomplete | "Please fill in all required fields" | P1 |
| BOOK-011 | Date/time required | Site visit open | 1. Submit without a slot | "Please select a date and time" | P1 |
| BOOK-012 | Project list load error | Backend failing | 1. Open SELECT PROJECT | "Error loading projects" — no crash | P2 |
| BOOK-013 | Site-visit success | Valid form | 1. Submit | "SUBMITTED" / "Visit scheduled successfully! We will contact you soon." with BACK TO PROJECT | P1 |
| BOOK-014 | Site-visit appears in records | Visit just booked | 1. Open the visits/bookings list for that role | The new visit is listed with the correct project, date and client | P1 |
| BOOK-015 | Payment plan screen | Payment plan open | 1. Review the screen | "CHOOSE PLAN / SELECT YOUR PREFERRED SCHEDULE" with plan cards, benefit labels (MAX SAVINGS / LOWER UPFRONT COST) and a MOST POPULAR badge where applicable | P1 |
| BOOK-016 | Compare plans | Payment plan | 1. Tap COMPARE PLANS | A comparison view opens with the plan details | P2 |
| BOOK-017 | Download payment plans | Payment plan | 1. Tap DOWNLOAD ALL PAYMENT PLANS (PDF) | The PDF opens/downloads; when unavailable "Payment plan PDF will be available soon." | P2 |
| BOOK-018 | Select a plan | Payment plan | 1. Tap SELECT PLAN on a card | Proceeds to token payment carrying the chosen plan | P1 |
| BOOK-019 | Token payment layout | Token payment open | 1. Review the screen | SECURE PAYMENT header, TOKEN AMOUNT, SELECT UNIT (REQUIRED), COMPLIANCE DOCUMENTS, PAYMENT METHOD and the terms checkbox | P1 |
| BOOK-020 | Available units | Project with units | 1. Open AVAILABLE UNITS | Only AVAILABLE units are listed with unit number, tower, floor, configuration and price | P1 |
| BOOK-021 | No available units | Project with none | 1. Open the unit list | "NO AVAILABLE UNITS FOUND FOR THIS PROJECT." | P2 |
| BOOK-022 | Units load failure | Backend failing | 1. Open the screen | "Failed to load available units." — no crash | P2 |
| BOOK-023 | Unit selection required | Token payment | 1. Pay without choosing a unit | "Please select a unit to reserve." | P1 |
| BOOK-024 | Terms required | Token payment | 1. Pay without agreeing to the terms | "Please agree to the booking terms to continue." / "Please agree to the terms and conditions" | P1 |
| BOOK-025 | Document upload — allowed types | Token payment | 1. Attach a JPG, JPEG, PNG and PDF | All four are accepted and listed with their file names | P1 |
| BOOK-026 | Document upload — wrong type | Token payment | 1. Try to attach a DOCX/other type | It is rejected with a clear message | P1 |
| BOOK-027 | File picker failure | Picker cancelled / unavailable | 1. Cancel the picker | "Could not open the file picker." / "Could not read the selected file." where applicable; no crash | P2 |
| BOOK-028 | Upload failure | Backend failing | 1. Attach a document | "Failed to upload document" / "An error occurred during document upload" | P2 |
| BOOK-029 | Payment methods | Token payment | 1. Open PAYMENT METHOD | UPI (PHONEPE/GPAY), CREDIT / DEBIT CARD and NET BANKING are selectable | P1 |
| BOOK-030 | Token payment success | Valid selection + terms agreed | 1. Complete the payment | "BOOKING SUCCESSFUL" / "PAYMENT SUCCESSFUL" and a route to the dashboard/home | P1 |
| BOOK-031 | Token payment failure | Payment declined | 1. Complete the payment | "Payment could not be processed." / "Payment failed. Please try again." and no booking is created | P1 |
| BOOK-032 | Booking confirmation screen | Booking completed | 1. Review the confirmation | RECEIPT ID, PROJECT, AMOUNT PAID and STATUS VERIFIED with SAVE RECEIPT, SHARE NOW and BACK TO DASHBOARD | P1 |
| BOOK-033 | Save receipt | Confirmation screen | 1. Tap SAVE RECEIPT | "Receipt copied to clipboard" / the receipt is saved and retrievable | P1 |
| BOOK-034 | Share booking | Confirmation screen | 1. Tap SHARE NOW | The share sheet opens with the booking details; "Booking details copied to clipboard" where applicable | P2 |
| BOOK-035 | Need help | Confirmation screen | 1. Tap "NEED HELP WITH YOUR BOOKING?" | The support path opens | P2 |
| BOOK-036 | Booking appears in records | Booking completed | 1. Open My Properties / My Bookings | The new booking is listed with the correct unit and amount | P1 |
| BOOK-037 | Back-navigation safety | Mid-flow | 1. Press Back from token payment | Returns to the payment plan without creating a partial booking | P1 |
| BOOK-038 | Interrupted payment | Payment in progress | 1. Background the app mid-payment and return | The state is recovered correctly — no duplicate booking and no stuck spinner | P1 |
| BOOK-039 | Double submission | Token payment | 1. Double-tap the pay button | Only one booking is created | P1 |

---

## 11. SUP — Support, tickets & logs

The Support Hub is shared by the Customer, CP and Investor portals (tab 3 or 4 depending on the portal).

### 11.1 Support hub

| TC ID | Test Scenario | Pre-condition | Steps | Expected Result | Pri |
|---|---|---|---|---|---|
| SUP-001 | Support hub layout | Any logged-in portal | 1. Open the Support tab | "SUPPORT HUB" with the SUPPORT MATRIX tiles: WhatsApp Support, Schedule Visit, Call Us and Help Center | P1 |
| SUP-002 | Support matrix in portrait | Support tab, portrait | 1. Review the tiles | Two columns; every tile shows its icon, title and subtitle in full with no clipping | P1 |
| SUP-003 | Support matrix in landscape | Support tab | 1. Rotate to landscape | The column count grows with the width and tile height is capped — the icon, title and subtitle all stay visible (the icon must not sit alone in an over-tall card) | P1 |
| SUP-004 | WhatsApp Support tile | Support tab | 1. Tap WhatsApp Support | WhatsApp opens on the M4 support number; a graceful fallback if WhatsApp is not installed | P1 |
| SUP-005 | Schedule Visit tile | Support tab | 1. Tap Schedule Visit | The schedule-visit screen opens | P1 |
| SUP-006 | Call Us tile | Support tab | 1. Tap Call Us | The dialler opens with the support number | P1 |
| SUP-007 | Help Center tile | Support tab | 1. Tap Help Center | The FAQ / help centre opens | P1 |
| SUP-008 | Operational logs — customer & investor | Logged in as customer or investor | 1. Open the Support tab | The OPERATIONAL LOGS section with a VIEW ALL LOGS action is shown | P1 |
| SUP-009 | Operational logs hidden for CP | Logged in as CP | 1. Open the Support tab | The OPERATIONAL LOGS section is **not** shown for the CP role | P1 |
| SUP-010 | Active tickets on the hub | Open tickets exist | 1. Open the Support tab | Open / in-progress tickets are listed with subject, status and date (`MMM d`) | P1 |
| SUP-011 | No active tickets | No open tickets | 1. Open the Support tab | "No active tickets." | P2 |
| SUP-012 | No portal kicker | Any portal | 1. Review the header | The Support Hub header carries no "M4 FAMILY" kicker in any portal (web parity) | P3 |

### 11.2 Help centre

| TC ID | Test Scenario | Pre-condition | Steps | Expected Result | Pri |
|---|---|---|---|---|---|
| SUP-013 | Help centre layout | Help centre open | 1. Open it | "SUPPORT INDEX / FAQ & GOVERNANCE" with a search field, category groups (PAYMENTS, BOOKINGS & SITE VISITS, …) and FREQUENTLY ASKED QUESTIONS | P1 |
| SUP-014 | Expand an FAQ | Help centre | 1. Tap a question | The answer expands; tapping again collapses it | P1 |
| SUP-015 | Search help topics | Help centre | 1. Type a keyword in Search Help Topics | Only matching questions remain; a term with no match shows an empty state, not a blank page | P1 |
| SUP-016 | Category filter | Help centre | 1. Select a category | Only that category's questions are listed | P2 |
| SUP-017 | CONTACT SUPPORT | Help centre | 1. Scroll to "STILL NEED HELP?" and tap CONTACT SUPPORT | The contact/support path opens | P1 |

### 11.3 Tickets

| TC ID | Test Scenario | Pre-condition | Steps | Expected Result | Pri |
|---|---|---|---|---|---|
| SUP-018 | Ticket list | Tickets exist | 1. Open the tickets screen | Tickets with id, subject, status and date, newest first | P1 |
| SUP-019 | Ticket list empty | No tickets | 1. Open the screen | A clear empty state, not a blank screen or a spinner that never ends | P1 |
| SUP-020 | Ticket list error | Backend failing | 1. Open the screen | A readable error with a retry path | P2 |
| SUP-021 | Raise ticket — layout | Raise/Create ticket open | 1. Review the screen | SUBJECT, CATEGORY, PRIORITY, MESSAGE and ADD FILES (PDF, JPG) with a submit button | P1 |
| SUP-022 | Subject required | Raise ticket | 1. Submit with an empty subject | "Please enter a subject" / "Please fill in subject, category and message" | P1 |
| SUP-023 | Message required | Raise ticket | 1. Submit with an empty message | "Please enter a message" / the combined required message | P1 |
| SUP-024 | Category options | Raise ticket | 1. Open CATEGORY | Project / Possession, Payment & Billing, Legal & Technical and General Query are available | P1 |
| SUP-025 | Priority options | Create ticket | 1. Open PRIORITY | Low, Medium (default) and High are available | P2 |
| SUP-026 | Attachment types | Raise ticket | 1. Attach a PDF, JPG, JPEG and PNG | All are accepted and listed by name | P1 |
| SUP-027 | Unsupported attachment | Raise ticket | 1. Try to attach another file type | It is rejected with a clear message | P1 |
| SUP-028 | Remove an attachment | Attachment added | 1. Remove it | It disappears from the list and is not submitted | P2 |
| SUP-029 | Raise ticket — success | Valid ticket | 1. Submit | "Ticket raised successfully!" and the ticket appears in the list | P1 |
| SUP-030 | Raise ticket — failure | Backend failing | 1. Submit | "Failed to raise ticket" and the entered data is preserved | P2 |
| SUP-031 | Ticket detail | A ticket exists | 1. Open it | Subject, ticket id, status and the message thread with "SECURE CONSULTATION" | P1 |
| SUP-032 | Ticket detail — empty thread | A brand-new ticket | 1. Open it | "NO MESSAGES YET — START THE CONVERSATION BELOW" | P2 |
| SUP-033 | Send a message | Ticket open | 1. Type in the message box and send | The message appears in the thread immediately with the correct timestamp (`hh:mm a`) | P1 |
| SUP-034 | Send failure | Backend failing | 1. Send a message | "Failed to send message" and the typed text is not lost | P2 |
| SUP-035 | View an attachment | Message with an attachment | 1. Tap VIEW ATTACHMENT | The attachment opens in the viewer/browser | P1 |
| SUP-036 | Ticket load failure | Backend failing | 1. Open a ticket | "UNABLE TO LOAD TICKET" / "Failed to load ticket" with RETRY | P2 |
| SUP-037 | Agent online state | Agent available | 1. Open a ticket | "SUPPORT AGENT ONLINE" indicator renders correctly | P3 |
| SUP-038 | Day separators | Thread spanning days | 1. Scroll the thread | Date separators (`EEEE, MMM d`) appear between days | P3 |

### 11.4 Support / audit logs

| TC ID | Test Scenario | Pre-condition | Steps | Expected Result | Pri |
|---|---|---|---|---|---|
| SUP-039 | Logs screen header | Logs open | 1. Open Support / Ticket Logs | "TICKET LOGS / CONCIERGE HISTORY" header renders correctly on every portal (no duplicated or missing header) | P1 |
| SUP-040 | Log entries | Logs exist | 1. Review an entry | CATEGORY, PRIORITY, AUDIT DATE (`dd MMMM yyyy, hh:mm a`) and DESCRIPTION | P1 |
| SUP-041 | Missing description | Entry without a description | 1. Open it | "No description provided." rather than a blank area | P2 |
| SUP-042 | Category filter | Logs exist | 1. Filter by System / Tickets / Updates | Only matching entries remain | P1 |
| SUP-043 | Status filter | Logs exist | 1. Filter by PENDING / ALL | Only matching entries remain | P2 |
| SUP-044 | Search records | Logs exist | 1. Type in Search Records | Only matching entries remain | P1 |
| SUP-045 | Logs empty | No logs | 1. Open the screen | "NO LOGS FOUND" | P2 |
| SUP-046 | New ticket from logs | Logs screen | 1. Tap INITIATE NEW SERVICE TICKET | The raise-ticket screen opens | P1 |
| SUP-047 | Dismiss an audit entry | An entry is open | 1. Tap DISMISS AUDIT | The detail closes and returns to the list | P2 |
| SUP-048 | Per-portal scoping | Logged in as each role in turn | 1. Open the logs on CP, Customer and Investor | Each role sees only its own records — never another role's data | P1 |

### 11.5 Contact & schedule visit

| TC ID | Test Scenario | Pre-condition | Steps | Expected Result | Pri |
|---|---|---|---|---|---|
| SUP-049 | Contact support screen | `/support/contact` | 1. Open it | "CONTACT US / INSTITUTIONAL SUPPORT" with GLOBAL HEADQUARTERS, the office address, DIRECTIONS, CALL NOW and the GET IN TOUCH section | P1 |
| SUP-050 | Office list | Multiple offices configured | 1. Review the offices | Each office shows its title, address and phone; the CORPORATE HEAD OFFICE is identified | P2 |
| SUP-051 | OPEN MAP | Contact support | 1. Tap OPEN MAP / DIRECTIONS | Maps opens at the correct coordinates | P2 |
| SUP-052 | Map width | Contact screen with an embedded map | 1. Review the map card on 320 dp, 360 dp and tablet widths | The map fills its card width exactly — no horizontal overflow and no white gutter | P1 |
| SUP-053 | Schedule visit — role variants | Open the screen as guest, customer and investor | 1. Compare the headers and prefills | The header/protocol wording matches the role and known user details are pre-filled for logged-in roles only | P1 |
| SUP-054 | Schedule visit — validation | Schedule visit open | 1. Submit incomplete | "Please fill in all required fields" | P1 |
| SUP-055 | Schedule visit — project selection | Schedule visit open | 1. Open SELECT PROJECT / SELECT PROPERTY | The list loads with title and location; selection fills the field | P1 |
| SUP-056 | Schedule visit — employee | CP context | 1. Open HANDLED BY (EMPLOYEE) | The employee list loads; with none added "NO EMPLOYEES ADDED" | P2 |
| SUP-057 | Schedule visit — success | Valid form | 1. Tap SECURE BOOKING | "Visit scheduled successfully! We will contact you soon." | P1 |
| SUP-058 | Schedule visit — failure | Backend failing | 1. Submit | "Failed to schedule visit" and the form data is preserved | P2 |

---

## 12. CON — Content hub, media, events, blog & CMS pages

| TC ID | Test Scenario | Pre-condition | Steps | Expected Result | Pri |
|---|---|---|---|---|---|
| CON-001 | Content hub — media | Any portal | 1. Open Media | "MEDIA GALLERY" with the subtitle about multimedia releases and the media tiles | P1 |
| CON-002 | Content hub — highlights | Any portal | 1. Open Highlights | "PROJECT HIGHLIGHTS" with achievements and milestones | P1 |
| CON-003 | Content hub — events | Any portal | 1. Open Events | "M4 EVENTS" with upcoming events | P1 |
| CON-004 | Content hub — blog | Any portal | 1. Open Blog | "M4 BLOG" with insights and news | P1 |
| CON-005 | Content cards | Any content list | 1. Review a card | Image/thumbnail, type badge, title, description and a date (`MM/dd/yyyy`) with a READ ARTICLE action | P1 |
| CON-006 | Content empty state | No published content of a type | 1. Open that type | A clear empty message (e.g. "No blog posts found") — never a debug string such as "DEBUG: No data found or status false" in a release build | P1 |
| CON-007 | Content scoped by portal | Logged in as guest, customer, CP and investor | 1. Open the same content type in each | Each portal receives its own scoped content set without error | P2 |
| CON-008 | Article detail | Open an article | 1. Review the screen | Cover image, title, date, DEEP DIVE description and the formatted article body | P1 |
| CON-009 | Rich text rendering | Article with HTML content | 1. Scroll the body | Headings, lists, links and images render correctly; text is justified and no raw HTML tags are visible | P1 |
| CON-010 | In-article links | Article with links | 1. Tap a link | It opens in the browser/webview; a broken link does not crash the app | P2 |
| CON-011 | SHARE THIS ARTICLE | Article detail | 1. Tap share | The share sheet opens with the article title and link | P2 |
| CON-012 | CLOSE the article | Article detail | 1. Tap CLOSE / back | Returns to the content list at the same scroll position | P2 |
| CON-013 | Video content | Media item with a video | 1. Open it and play | The player loads and plays with working controls (play/pause, seek, fullscreen) | P1 |
| CON-014 | Unsupported video | Item with a bad video URL | 1. Open it | "Video format not supported or unreachable" — no crash | P1 |
| CON-015 | Event detail | An event exists | 1. Open it | Date (`EEEE, MMMM d, yyyy`), Time (`h:mm a`), LOCATION/venue and the attendee count | P1 |
| CON-016 | Event status badges | Events in different states | 1. Review the list | TODAY / UPCOMING / ENDED / CANCELLED badges match the event dates | P1 |
| CON-017 | Event RSVP | Event with an RSVP URL | 1. Tap RSVP TO EVENT | The RSVP page opens; without a URL the button is absent or clearly disabled | P2 |
| CON-018 | Image loading | Any content list | 1. Scroll through the images | Images are cached (no re-download on scroll-back); missing images fall back to a placeholder | P2 |
| CON-019 | Bundled asset images | Any screen using bundled art | 1. Review the screens | Bundled `assets/` images render — they must not be requested from the API host and 404 | P1 |
| CON-020 | CMS pages list | `/pages` for the portal | 1. Open it | Published pages for that portal with their titles; unnamed pages show "Untitled" | P2 |
| CON-021 | CMS pages empty | No published pages | 1. Open the list | "No published pages available." | P2 |
| CON-022 | CMS page detail | Open a page | 1. Review it | Title, LAST UPDATE date (`MMM dd, yyyy`) and the section content with icons | P1 |
| CON-023 | CMS page not found | Invalid slug | 1. Open it | "Page Not Found" with a "Back to Pages" action | P2 |
| CON-024 | Privacy policy per portal | Guest, CP and Investor privacy routes | 1. Open each | The correct privacy content renders in each portal | P2 |
| CON-025 | Loading state | Slow network | 1. Open a CMS page | "SYNCING SECURE CONTENT..." placeholder rather than a blank screen | P3 |

---

## 13. SRCH — Search

| TC ID | Test Scenario | Pre-condition | Steps | Expected Result | Pri |
|---|---|---|---|---|---|
| SRCH-001 | Open search | Any portal | 1. Tap the search entry | The search screen opens with the query field and filters | P1 |
| SRCH-002 | Keyword search | Projects exist | 1. Type a known project name | Matching projects appear in SEARCH RESULTS | P1 |
| SRCH-003 | Partial / case-insensitive match | Projects exist | 1. Type a lowercase partial name | The match is still found | P2 |
| SRCH-004 | Location filter | Projects in several locations | 1. Filter by a location | Only projects in that location are listed | P1 |
| SRCH-005 | Budget filter | Projects at different price points | 1. Apply a budget range | Only projects within the range are listed | P1 |
| SRCH-006 | Type / status filter | Mixed catalogue | 1. Filter by property type and status | Only matching projects are listed | P1 |
| SRCH-007 | Combined filters | Mixed catalogue | 1. Apply several filters together | The result set satisfies every filter | P1 |
| SRCH-008 | No results | Any query | 1. Search for nonsense text | "NO MATCHES — TRY ADJUSTING YOUR FILTERS TO FIND MORE PROPERTIES." with CHANGE FILTERS | P1 |
| SRCH-009 | Clear / change filters | No-results state | 1. Tap CHANGE FILTERS | The filter panel reopens and clearing restores results | P1 |
| SRCH-010 | Open a result | Results shown | 1. Tap a result card | The correct project detail opens | P1 |
| SRCH-011 | Price fallback | Project without a price | 1. Review its card | "price on request" / "on request" instead of a blank or `null` | P2 |
| SRCH-012 | Empty query | Search screen | 1. Submit an empty query | All projects (or a sensible default set) are shown — no crash | P2 |
| SRCH-013 | Special characters | Search screen | 1. Enter `%$#@` | No crash; an empty-result state is shown | P2 |
| SRCH-014 | Search per portal | Guest, CP and Investor search routes | 1. Search in each | Each portal's search works and stays inside its own shell | P2 |

---

## 14. API — API & error-state matrix

Run each row against a representative screen (Projects list, Profile, Payments, Ticket submit).

| TC ID | Condition | Expected user-visible result | Pri |
|---|---|---|---|
| API-001 | Connection timeout / send timeout / receive timeout | "The server is taking too long to respond. Please try again." | P1 |
| API-002 | No connection (airplane mode) | "No internet connection. Please check your network and try again." | P1 |
| API-003 | Bad TLS certificate | "Could not establish a secure connection." | P2 |
| API-004 | Request cancelled | "Request cancelled." (or a silent, harmless no-op) | P3 |
| API-005 | HTTP 400 with an empty body | "Some details look incorrect. Please check the form and try again." (or the screen's own fallback) | P1 |
| API-006 | HTTP 400/422 with a server `message` | The server's own message is shown verbatim | P1 |
| API-007 | HTTP 401 | "Your session has expired. Please sign in again." | P1 |
| API-008 | HTTP 403 | "This account does not have access here. Please check you selected the right portal, or contact support." | P1 |
| API-009 | HTTP 404 | "We could not find what you were looking for." | P1 |
| API-010 | HTTP 409 | "This entry already exists." | P2 |
| API-011 | HTTP 429 | "Too many attempts. Please wait a moment and try again." | P2 |
| API-012 | HTTP 500 / 502 / 503 / 504 | "The server is having trouble right now. Please try again shortly." | P1 |
| API-013 | Mongoose-style field errors (`errors: { field: { message } }`) | Each field message is shown, one per line | P2 |
| API-014 | Server returns an HTML error page | A generic friendly message — the raw HTML is never displayed | P2 |
| API-015 | 200 with an unexpected body shape | A friendly message; the app does not crash and does not treat it as success | P1 |
| API-016 | No `DioException` text ever reaches the UI | No snackbar or screen shows "DioException", a stack trace or a status-code dump | P1 |
| API-017 | Auth header attached | Authenticated endpoints receive `Authorization: Bearer <token>`; guest endpoints work without one | P1 |
| API-018 | Large payload handling | A catalogue with 100+ projects loads without freezing the UI thread | P2 |
| API-019 | Slow backend cold start | Long-running requests still complete (60 s connect / 90 s receive budget) rather than failing instantly | P2 |
| API-020 | Relative asset URLs | Images and documents returned as relative paths resolve against the API host and load correctly | P1 |
| API-021 | Absolute / `data:` / `tel:` / `mailto:` URLs | These are used as-is and are never prefixed with the API host | P1 |

---

## 15. NFR — Non-functional

### 15.1 Performance

| TC ID | Test Scenario | Expected Result | Pri |
|---|---|---|---|
| NFR-001 | Cold start time | The app reaches an interactive Home within ~3 s on a mid-range device | P1 |
| NFR-002 | Warm start time | Resuming from background is near-instant with no white screen | P1 |
| NFR-003 | Screen transition smoothness | No visible jank or dropped frames when switching tabs or pushing screens | P2 |
| NFR-004 | Long-list scrolling | Projects / notifications / logs scroll smoothly with 100+ items | P2 |
| NFR-005 | Image memory | Browsing many image-heavy screens does not cause an out-of-memory crash | P1 |
| NFR-006 | Release-build logging | A release build produces no verbose request/response logging in logcat | P1 |
| NFR-007 | Battery / data | Normal browsing for 15 minutes shows no abnormal battery drain or repeated redundant network calls | P3 |
| NFR-008 | APK size | The release build size is within the agreed budget | P3 |

### 15.2 Security & privacy

| TC ID | Test Scenario | Expected Result | Pri |
|---|---|---|---|
| NFR-009 | Token storage | The JWT is kept in secure storage (Keychain / Keystore), never in plain shared preferences or logs | P1 |
| NFR-010 | Token cleared on logout | After logout the stored token and cached user are removed and the session cannot be restored | P1 |
| NFR-011 | No credentials in logs | Passwords, OTPs and tokens never appear in logcat, even in a debug build | P1 |
| NFR-012 | Password masking | Every password field is masked by default and reveals only via its own toggle | P1 |
| NFR-013 | Cross-role data isolation | A CP, customer and investor each see only their own data; no other role's records are ever visible | P1 |
| NFR-014 | Screenshot of sensitive screens | Payment and document screens behave per the security policy agreed for the release | P3 |
| NFR-015 | HTTPS only | All API traffic uses HTTPS; no cleartext endpoint is reachable | P1 |
| NFR-016 | Deleted account | After account deletion the credentials no longer authenticate and no cached data remains in the app | P1 |

### 15.3 Compatibility & accessibility

| TC ID | Test Scenario | Expected Result | Pri |
|---|---|---|---|
| NFR-017 | Android version matrix | The app installs, launches and works on Android 10 through 15 | P1 |
| NFR-018 | iOS version matrix | The app installs, launches and works on iOS 15 through 18 | P1 |
| NFR-019 | Small screens (320 dp) | Every screen is usable with no overflow and no unreachable CTA | P1 |
| NFR-020 | Tablet layout | Grids reflow sensibly on a 600 dp+ width; content is not stretched into a single giant column | P2 |
| NFR-021 | Landscape | Key screens (Support matrix, Connect grids, Quick actions) reflow and stay readable in landscape | P1 |
| NFR-022 | System font scaling | Verified at the system's smallest and largest settings (app clamps to 0.85x–1.5x) | P1 |
| NFR-023 | Touch target size | Every interactive control is at least ~44 dp tall/wide or has an equivalent tap area | P2 |
| NFR-024 | Colour contrast | Text on green, cream and greige surfaces meets a readable contrast ratio | P2 |
| NFR-025 | Screen reader | Buttons, images and inputs expose meaningful labels to TalkBack / VoiceOver | P3 |
| NFR-026 | Gesture navigation | The floating nav pill and drawers do not conflict with the OS gesture bar | P2 |
| NFR-027 | Interruptions | An incoming call, notification or app switch during a form or payment does not lose data or crash the app | P1 |
| NFR-028 | Permissions | Storage, camera/photos and file-picker permissions are requested only when needed, and denial is handled with a clear message | P1 |
| NFR-029 | Fresh install vs upgrade | Both a clean install and an upgrade over a previous version launch correctly, keeping (or safely migrating) the session | P1 |

---

## 16. Regression smoke suite (run on every build)

| # | TC IDs |
|---|---|
| 1 | GEN-001, GEN-003, GEN-004, GEN-011 — launch, portal resolution, theme |
| 2 | AUTH-011, AUTH-018, AUTH-025, AUTH-040, AUTH-079 — OTP login, role gating, CP and investor login |
| 3 | AUTH-083, AUTH-086 — logout and session clearing |
| 4 | GST-024, GST-034, GST-046 — project list, project detail, inquiry |
| 5 | CUS-002, CUS-026, CUS-032 — customer dashboard, profile, profile save |
| 6 | CP-010, CP-017, CP-041, CP-116 — CP dashboard, lead status, bookings, add employee |
| 7 | INV-020, INV-026, INV-046 — investor portfolio, payments, document open |
| 8 | BOOK-013, BOOK-030, BOOK-032 — site visit, token payment, confirmation |
| 9 | SUP-029, SUP-033 — raise a ticket, reply on a ticket |
| 10 | CV-015, CV-021 — save selections, revision limit |
| 11 | API-002, API-007, API-016 — offline, session expiry, no raw exceptions |
| 12 | NFR-015, NFR-013 — HTTPS only, cross-role isolation |

---

## 17. Coverage summary

| Module | Test cases |
|---|---|
| GEN — General / cross-cutting | 41 |
| AUTH — Authentication & role gating | 89 |
| VAL — Validation matrix | 15 (+ 25 forms to repeat against) |
| GST — Guest portal | 78 |
| CUS — Customer portal | 85 |
| CV — Custom Views | 30 |
| CP — Channel Partner portal | 164 |
| INV — Investor portal | 112 |
| BOOK — Booking & payments | 39 |
| SUP — Support & tickets | 58 |
| CON — Content & CMS | 25 |
| SRCH — Search | 14 |
| API — Error matrix | 21 |
| NFR — Non-functional | 29 |
| **Total** | **≈ 800 test cases** |

---

## 18. Execution tracker template

Copy this table per cycle and fill it in while testing.

| TC ID | Build | Device / OS | Tester | Result | Defect ID | Notes |
|---|---|---|---|---|---|---|
| | | | | | | |

**Sign-off**

| Role | Name | Date | Signature |
|---|---|---|---|
| QA Engineer | | | |
| QA Lead | | | |
| Product Owner | | | |
