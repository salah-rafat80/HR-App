# HR App Demo 🚀

This is a comprehensive UI-only simulated demo for a modern HR management application built with Flutter.

**⚠️ NOTE:** This is a purely simulated frontend demo. There is no real backend attached. All data is provided via mock DataSources (e.g. `FakeAttendanceDataSource`) using `Future.delayed` to simulate network latency.

## Architecture
- Clean Architecture (Domain, Data, Presentation) per feature.
- BLoC/Cubit for State Management.
- Dependency Injection via `get_it`.
- Localization via `easy_localization` (supports AR/EN with full RTL support).
- Theme management via centralized `AppColors`.

## Completed Modules (10/10)
1. **Authentication:** Login and 2FA flow.
2. **Home Dashboard:** Dynamic greeting, quick actions, status cards, and cross-module notifications.
3. **Attendance & Time Tracking:** Clock in/out, geofence simulation, history, and requests.
4. **Leave Management:** Balances, team calendar, multi-step approval flows.
5. **KPI Tracker:** Goal setting, progress tracking, and historical charts.
6. **Performance & Appraisal:** 360° peer feedback, self-appraisals (synced with KPIs), career path.
7. **Payslip & Compensation:** Read-only payslips with charts, YTD summary, tax certificate download.
8. **Training & Development:** Course enrollment, certifications, mandatory training alerts.
9. **Communication Hub:** Announcements, HR chat (with auto-reply), interactive polls, employee handbook.
10. **IT Requests:** Helpdesk ticketing system with status tracking.

## Supported Roles (Simulated Demo)
This application simulates a fully integrated multi-role environment where data changes in one role affect what is seen by another role.
1. **Employee:** Standard access to personal attendance, leave, KPIs, appraisal, and payslips.
2. **Team Lead:** Extended access to "Team" tab for localized team approvals and team KPI tracking.
3. **Manager:** Higher-level "Team" tab access with departmental scope and multi-stage leave/appraisal approvals.
4. **HR Admin:** Replaces "Team" tab with an "Admin" tab. Includes company-wide Approvals/KPIs, Payroll Runs, Recruitment Pipeline, and basic System Config.
5. **Super Admin:** Full "Admin" tab access including advanced System Config (Roles & Permissions, Company Settings, Integrations).
6. **C-Level Executive:** Separate standalone "Executive Dashboard" shell displaying company-wide summary cards, trend charts, and read-only aggregate data from recruitment and payroll.

## Running the App
Make sure your emulator/device is connected.
```bash
flutter run
```
You can switch the language from the Profile screen to test the RTL capabilities.
