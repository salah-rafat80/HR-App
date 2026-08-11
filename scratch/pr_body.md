# Pull Request: Premium Notifications Customization

## Summary
This Pull Request modernizes the foreground in-app notifications and background native push notifications to look premium and highly branded. It introduces a translucent glassmorphic theme, smooth pulsing micro-animations, context-aware interactive actions (like Approve/Reject for leave requests) directly inside in-app notifications, silent tray drawer storage in the foreground, and system status bar color styling.

## Changes
### Mobile (Flutter)
- **Premium Glassmorphic UI**: Redesigned `InAppNotification` overlay to support translucent blurs (`ui.ImageFilter.blur`), custom shadows, and status-colored glowing borders.
- **Heartbeat Animation**: Implemented a pulsing halo micro-animation surrounding the status icon container.
- **Action Integration**: Added direct "موافقة" (Approve) and "رفض" (Reject) actions for pending leave requests, executing API calls via `LeaveRepository` and presenting loaders/checkmark statuses. Added "عرض التفاصيل" (View Details) button for other updates.
- **Silent Foreground Drawer**: Changed `FcmService` foreground behavior to post notifications silently (`Importance.low` / `Priority.low`) to the system tray, preventing native heads-up popups from overlapping the custom glassmorphic overlay.
- **Tap Routing**: Connected GoRouter navigation inside `_onNotificationTap` to steer the user directly to corresponding pages (Leave, KPI, Attendance) based on the FCM message payload.

### Android Setup
- **Branded Notification Color**: Created a new `colors.xml` resource mapping the brand's primary teal color `#0B6E64`.
- **FCM Metadata Setup**: Configured default notification icon and color properties in `AndroidManifest.xml`.

### Backend (NestJS)
- **Target ID Forwarding**: Updated `NotificationService` convenience helpers to receive request/entity IDs and include them in the FCM data payload.
- **Leave Actions Payload**: Updated `leave.service.ts` to attach leave IDs when notifying employees and managers of submissions, approvals, or rejections.
- **Android Styling Payload**: Included `#0B6E64` color mapping in the FCM payload for native status bar styling.

## Testing
- Verified that both the backend and mobile projects compile successfully with zero errors.
- Verified NestJS compiles cleanly via `npm run build`.
- Verified Flutter compiles cleanly with zero warnings/errors via `flutter analyze`.
