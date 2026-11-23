# Business Logic

> Development of an Android-based Community-Powered Passenger Visibility Platform using Kotlin and Supabase for Public Transport Commuters and Drivers

- Allowed Platforms: Web, Android

## Project Details

- Company/Startup/Team Name: `Neuriss`
- Project Code Name: `Axon`
- Project Short Code: `AX`
- Short Description: `A community-powered platform that allows passengers to share their temporary waiting locations with verified public transport drivers operating along their selected routes, helping drivers identify nearby passenger demand and reducing unnecessary waiting time.`
- Long Description: `Axon is an Android-based platform with a companion web application designed to improve communication between public transport drivers and commuters. Passengers can indicate that they are waiting for transportation by pressing a single button, which creates a temporary location marker visible only to verified drivers assigned to the selected route. Each user has a primary route automatically selected upon login, with the option to change routes when necessary, subject to driver authorization. Drivers can view active waiting passengers on a map and decide whether to proceed toward them or remain at their current location. Upon reaching a passenger, a driver may initiate a pickup confirmation while safely stopped nearby. The passenger confirms the pickup, after which the waiting marker is removed. Passengers may also cancel their waiting status, and unattended requests automatically expire. The platform focuses on real-time passenger visibility rather than reservations, fare payments, or ride-hailing services. It implements route-based access control, driver verification, temporary location sharing, and privacy safeguards to protect users while encouraging community participation. The system is designed to support different types of route-based public transportation without being restricted to a particular vehicle type.`

## User Levels

| User Level | Description |
|---|---|
| A. System Administrator | Maintains system/server configurations, manages security settings, and performs regular backups. |
| B. Administrator | Manages registered routes, verifies driver accounts and authorized route assignments, manages platform settings, and accesses permitted aggregate system reports. |
| C. Moderator | Reviews reported misuse, enforces community guidelines, and manages inappropriate activity without unnecessary access to passengers' precise locations. |
| D. Driver | A verified public transport driver who views active waiting passengers along authorized routes and initiates pickup confirmation when safely stopped near a passenger. |
| E. Passenger | A registered commuter who selects a route, shares a temporary waiting location, cancels waiting requests, and confirms completed pickups. |

## System Requirements

1. The app shall allow users to authenticate using Google Sign-In integration and access functions based on their assigned user levels.
2. The app shall allow passengers and drivers to select a primary route during account setup, automatically use that route upon login, and change their active route when necessary, subject to driver route authorization.
3. The app shall allow passengers to publish their current waiting location on a map through a single button, creating a temporary waiting request associated with their selected route.
4. The app shall allow verified drivers to view active waiting locations belonging only to their authorized and currently selected route, enabling them to identify nearby passenger demand.
5. The app shall allow drivers to initiate a pickup confirmation when safely stopped near a waiting passenger, using GPS proximity as a supporting check, and allow passengers to confirm the pickup before the waiting request is closed.
6. The app shall allow passengers to cancel their waiting requests and automatically expire inactive requests to prevent outdated passenger locations from remaining visible.
7. The app shall allow authorized administrators and moderators to manage routes, verify driver accounts, enforce community guidelines, and maintain system security and privacy controls according to their assigned permissions.

## Required Solution Layers

1. **Security and privacy by design.** The platform shall incorporate safeguards consistent with the Philippine Data Privacy Act, including location protection, retention limits, no persistent per-user location trails, aggregation thresholds, and explicit consent for any proposed data resale.
2. **Authentication and role-based authorization.** Google Sign-In shall authenticate users, while server-side authorization shall restrict access according to their roles. Driver accounts must be verified before accessing passenger waiting locations.
3. **Route-based information isolation.** Waiting locations shall be visible only to verified drivers authorized for the selected route. Drivers shall not access active passenger requests belonging to unrelated routes.
4. **Temporary location sharing.** Passenger locations shall be shared only during an active waiting request. Requests shall be removed from active visibility following cancellation, confirmed pickup, or automatic expiration. Precise location data shall not be retained beyond its operational necessity.
5. **Location accuracy and pickup verification.** GPS proximity shall support pickup confirmation without relying on an inflexible five-meter threshold. Passenger confirmation shall be required to complete a pickup, preventing drivers from independently dismissing waiting requests.
6. **Community-guideline enforcement.** Moderators shall address misuse through community-guideline violations and appropriate account restrictions rather than public reputation scores or visible user rankings.
7. **Data minimization and aggregation.** The platform shall collect only information necessary for registration, route selection, waiting visibility, pickup confirmation, and administration. Analytics shall use aggregate information with minimum reporting thresholds to prevent identifying individual users.

## MVP Features and Access

| Feature | Access |
|---|---|
| 1. Google Sign-In authentication and role-based account access | A,B,C,D,E |
| 2. Passenger waiting-location sharing, cancellation, and pickup confirmation | E |
| 3. Route-filtered waiting-passenger map and driver pickup initiation | D |
| 4. Primary route configuration and active route selection | D,E |
| 5. Community-guideline enforcement and misuse moderation | A,B,C |
| 6. Route management, driver verification, and authorized route assignments | A,B |
| 7. System configuration, security management, and database backup administration | A |

## Notes

- Android is the primary application platform, developed using Kotlin, with Supabase PostgreSQL as the planned database service.
- The web application shall serve as a companion administrative interface for managing routes, driver verification, and moderation.
- The MVP shall initially focus on local route-based public transportation, with route definitions based on applicable local transport arrangements.
- The system shall be designed to accommodate different types of public utility vehicles operating along designated routes.
- A passenger shall only have one active waiting request at a time to prevent duplicate location markers.
- A passenger's primary route shall be selected automatically upon login but may be changed based on transportation needs.
- Drivers may switch between routes only when authorized to operate on those routes.
- Waiting requests shall automatically expire after a configurable period, initially proposed as 15 minutes, unless the passenger renews the request.
- Drivers shall initiate pickup confirmation only when safely stopped. Passenger confirmation shall close the waiting request and remove it from active driver maps.
- The application shall not guarantee pickup, reserve drivers, negotiate fares, or provide real-time driver tracking as part of the MVP.
- Waiting locations shall not be publicly visible to unverified users.
- Passenger names, contact information, and historical location trails shall not be exposed through the waiting map.
- No monetary rewards, convertible credits, or public reputation rankings shall be implemented.
- The initial release shall prioritize simple interactions, route-based visibility, reliable request expiration, and user privacy over additional features.