# Business Logic v1.1

> Development of an Android-based Community-Powered Passenger Visibility Platform using Kotlin and Supabase for Public Transport Commuters and Drivers

- **Allowed platforms** — Android for passengers and drivers. Web for internal administration.
- **Status** - Accepted MVP scope. See the [v1.0 baseline](business-logic-v1.0.md) and [reviewed proposal](business-logic-v1.1-proposed.md).

## Project Details

| Field | Definition |
|---|---|
| Company/Startup/Team Name | Neuriss |
| Project Code Name | Axon |
| Project Short Code | AX |
| Short Description | Axon lets waiting commuters share a temporary map pin with verified drivers on their selected public transport route. |
| Long Description | A commuter selects a route and taps **Start waiting** to share a one-time location pin. Verified drivers assigned to that route see active pins on their Android map and decide independently where to proceed. Once safely stopped near a passenger, a driver can ask the passenger to confirm pickup in the app. Confirmation, cancellation, or expiry removes the pin. Axon gives drivers a view of current waiting demand using routes and pickup practices already in use. |

**Launch positioning.** Start with one locally recognized route or service area and a small group of verified drivers and participating commuters. Expand route coverage after testing the full workflow. Axon supports route-based public transport across vehicle types. The pilot asks whether drivers can see waiting demand in time to act and whether commuters can share and clear a pin without help. Reduced waiting time is a goal to evaluate. Pickup is never guaranteed.

## User Levels

| Level | MVP responsibility |
|---|---|
| A. System Administrator | Manages privileged access, security configuration, backups, and recovery through existing service tools. |
| B. Administrator | Maintains the pilot route list, records driver verification, and grants or revokes driver route assignments through the internal web interface. |
| C. Moderator | Reviews misuse reports and restricts or restores accounts. Routine review uses account and request references. |
| D. Driver | Once verified and assigned to a route, views active waiting pins and initiates pickup confirmation on that route. |
| E. Passenger | Chooses a route, shares or cancels a waiting pin, and responds to a pickup prompt for their own request. |

A small pilot team may cover multiple operational roles. The service still checks the permission required for each action.

## System Requirements

1. **Sign in.** Google Sign-In authenticates all roles. The server grants access according to account status and role.
2. **Set, update, or switch routes.** Passengers can set and update their saved primary route from the enabled list. Drivers can set and update their saved primary route and switch their active route only among enabled routes they are authorized to serve. Drivers with no eligible routes see a pending or unavailable state. At sign-in, the app uses the saved primary route if it is eligible or prompts the user to choose an eligible route. Switching the active route applies to the current session. Changing the saved or active route shall not alter or cancel an existing waiting request. The application shall continue displaying the active request on the passenger's waiting screen, allowing the passenger to cancel it or respond to a pending pickup confirmation. The request shall remain associated with its original route until it is completed, cancelled, or expired. To post a pin on another route while a request is open, the passenger first cancels it.
3. **Start or cancel waiting.** After route setup and location permission, **Start waiting** captures one current location and opens a request for the selected route. A brief first-use notice explains who sees the pin, when it disappears, and how to cancel it. A passenger may have one open request across all routes, including while pickup confirmation is pending. If location or connectivity is unavailable, explain the failure and allow a retry. Only show success once the server accepts the request. Repeated taps or retries must leave at most one open request.
4. **Show route demand.** The driver map shows current waiting pins for the verified driver's selected, authorized route. Refresh on return to the app and regularly while the map is open. Clear markers on route changes and when the data becomes stale or access is lost. A pin exposes its waiting location and status. Passenger names, contact details, and location history stay private.
5. **Confirm pickup.** A verified driver viewing the request can initiate pickup after acknowledging they are safely stopped. Check proximity using a current driver location and the waiting pin. Pilot-test a tolerance against local GPS accuracy. If proximity cannot be established, allow retry and keep normal boarding available outside the app. Keep one pending prompt per request. Give it a short server-timed response window that ends strictly before the original waiting request deadline. Start a prompt only if the full response window fits before that deadline. The passenger can confirm or decline from their waiting screen while the prompt is active. Confirmation closes the request. Decline, prompt timeout, or revocation of the initiating driver's access clears the prompt and returns an otherwise active request to **Waiting** with its original expiry. Recheck authorization and both deadlines when processing a response. Reject late responses and ensure competing actions preserve a single outcome.
6. **Expire and clear pins.** Use server time and an initial 15-minute waiting window from creation. Pickup prompts leave that deadline unchanged. Cancellation, confirmed pickup, or waiting request expiry removes the pin from server results immediately. Reject actions on ended requests and remove expired pins locally at their known deadline. A passenger may create a new pin after the previous request closes.
7. **Operate the pilot.** Administrators enable routes, verify drivers against eligibility evidence agreed with the local route operator or authority, and assign driver routes. Passengers and drivers can report misuse from the waiting or pickup flow using a simple reason. Moderators review reports and apply or lift restrictions. Driver revocation and account suspension take effect on the next server check. Passenger suspension also ends any open request.

## Required Solution Layers

| Layer | MVP rule |
|---|---|
| Security and privacy by design | Define access and retention with the pilot operator before launch. Document how safeguards address the Philippine Data Privacy Act. Keep secrets in server-side configuration and precise coordinates out of logs and crash reports. Cover backup access and expiration in the retention policy. |
| Authentication and authorization | Check account status, role, and request ownership on the server. Administrative permissions alone grant no access to the driver map. |
| Route isolation | Recheck route eligibility on each driver map read and pickup action. A disabled route stops accepting requests, hides existing pins, and ends open requests for that route. |
| Temporary location sharing | Capture the passenger pin once per request. Remove it from visibility on closure and purge precise coordinates from operational storage under a documented, tested schedule. Keep no per-user trails. |
| Location and pickup verification | Use foreground location for publishing a pin and a proximity check for pickup. Do not use background driver tracking or store driver positions as a history. Passenger confirmation is required for completion. |
| Community enforcement | Give moderators a reason and non-location report reference. Record moderation actions with limited access. Use restrictions and restoration controls. |
| Data minimization and aggregation | Keep only the account, route, request, and moderation data needed to run the service. Use non-location counts for pilot review. Define a minimum group size before sharing aggregate results. Exclude resale from the MVP. |

## MVP Features and Access

| Feature | Platform | Access |
|---|---|---|
| Google Sign-In and access by role | Android and web | A, B, C, D, E on their assigned surfaces |
| Saved primary route setup and updates, plus active route selection | Android | D, E. Drivers use authorized routes only. |
| Waiting pin, expiry, cancellation, and passenger pickup response | Android | E, own requests only |
| Route map and pickup prompt initiation | Android | D, verified and assigned to selected route |
| Submit and review misuse reports | Android and web | D and E submit. C reviews and acts on reports. |
| Route list, driver verification, and route assignments | Web | B |
| Privileged access, security, and backups | Service administration | A |

## Notes

- **Launch scope.** Kotlin Android app, Supabase-backed service, and a basic internal web panel. Use a preloaded route list and in-app pickup prompts. Manual driver verification keeps onboarding small.
- **Deferred features.** Reservations, fare negotiation and payments, driver tracking and ETA, push notifications, in-place waiting renewal, public ratings, rewards, and analytics dashboards.
- **Pilot decisions to confirm.** Select the first route and participating driver group. Agree on what evidence qualifies a driver and who reviews it. Field-test the 15-minute waiting window, the shorter pickup prompt window, driver map freshness, and location tolerance. Approve the location retention and backup policy before using real passenger data.
- **Launch check.** On two Android phones on the same route, post a pin, display it on the verified driver's map, and remove it after passenger confirmation. Verify that a decline or unanswered prompt returns the request to **Waiting** before its original deadline and that a late confirmation is rejected. Check that cancellation and waiting expiry clear the pin. Save a different eligible primary route, sign in again, and verify that the app selects it and rejects unauthorized driver route choices. Verify that a driver assigned elsewhere and an unverified driver see no pin, and that revoking access while the map is open clears it on refresh. Confirm a retry creates no duplicate and that the administrator and moderator can complete their respective tasks from web administration.

## Gaps Addressed From v1.0

| Gap | v1.1 decision |
|---|---|
| Broad launch scope and unclear value proposition | Pilot a single local route or service area. Measure whether visibility works before expanding. |
| Undefined defaults, authorization, and account operations | Specify saved primary route updates, session-only route switches, manual driver verification, and server authorization checks. |
| Incomplete waiting and pickup states | Define one open request and one pending prompt, with a shorter prompt deadline and an unchanged waiting request deadline. |
| Privacy and moderation principles without an operational flow | Define map fields, prompt timing, report entry and review, and the retention decisions required before launch. |
| Unclear launch readiness | Add end-to-end pilot checks and a short list of unresolved decisions. |
