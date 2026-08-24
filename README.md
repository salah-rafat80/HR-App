<div align="center">

# 🚀 Smart HR System

**An Enterprise-Grade Single-Company, Multi-Branch HR Platform**

💙 **Flutter** • 🎯 **Dart** • 🐈 **NestJS** • 🏗️ **Clean Architecture**

_Elevate your factory and enterprise workforce management with seamless automation, biometric integrations, and deep operational analytics._

---

</div>

## 🌟 Overview

The **Smart HR System** is a next-generation HR Platform tailored specifically for large-scale operations and manufacturing facilities. Designed as a robust single-company, multi-branch system (with future multi-tenancy evolution in mind), it provides a highly polished, premium user experience while ensuring strict compliance with operational logic and localized labor laws.

### 🔥 Why Smart HR?

- **Level 5 Automation:** Minimize manual HR intervention. From attendance reconciliation to payroll runs, the system automates the heavy lifting.
- **Premium User Experience:** Fluid animations, a stunning "Slate & Royal Blue" color scheme, and fully localized RTL (Arabic) support.
- **Role-Based Workflows:** Seamlessly tiered approval structures connecting Employees, Supervisors, HR Admins, and C-Level Executives.

---

## 📱 Platforms

### 1. Mobile App (Employee Portal)

A buttery-smooth Flutter mobile application designed for the workforce on the go.

- **Biometric Check-In/Out:** Geo-fenced and biometric-secured attendance logging.
- **Request Management:** Apply for leaves, track approval states, and handle exceptions.
- **Overtime Tracking:** View and accept/reject overtime requests with a single tap.

### 2. Web Portal (Management Dashboard)

A comprehensive admin panel built with Flutter Web for HR professionals and Executives.

- **Executive Dashboard:** Macro-level insights, headcount trends, and overall team KPIs.
- **Approvals & Payroll:** Centralized Kanban-style pipelines for recruitments, and robust payroll automation.
- **System Configuration:** Manage roles, leaves, company branches, and integrations.

---

## 🏗️ Architecture

The entire monorepo is governed by **Clean Architecture** principles and **Feature-First** modularity.

```text
hr_app_demo/
├── apps/
│   ├── mobile/         # Flutter Mobile application (Employee focus)
│   └── web/            # Flutter Web application (Management focus)
└── packages/
    └── hr_core/        # Shared core package (Domain Entities, Repositories, BLoCs)
```

### 🏢 Organizational Architecture & Tenancy

- **Single-Company Deployment:** The current tenant boundary is strictly one company per application deployment. A `companyId` or `tenantId` is intentionally omitted from the core schema.
- **Visibility Boundaries:** Organizational grouping and data visibility rely on `branchId` and `department`.
- **Peer Feedback:** Features like 360-appraisals strictly adhere to the same-branch and same-department visibility rules to ensure privacy across the organization.

### 🛠️ Tech Stack & Design Patterns

- **State Management:** `flutter_bloc`
- **Routing:** `go_router` (with shell routes & auth guards)
- **Dependency Injection:** `get_it` & `injectable`
- **Networking:** `dio` (with idempotency, retry policies, and JWT interceptors)
- **Design System:** Centralized `AppColors`, `AppTextStyles`, and standardized tokens.

---

## ⚙️ Core Modules

| Module             | Description                                                                                        |
| ------------------ | -------------------------------------------------------------------------------------------------- |
| **Attendance**     | Real-time GPS/Biometric tracking with automated _Late_, _Present_, and _Absent_ state calculation. |
| **Recruitment**    | Drag-and-drop Kanban board for managing the entire hiring pipeline.                                |
| **Team KPIs**      | Interactive tracking and scoring for individual and departmental performance metrics.              |
| **Approvals**      | Multi-tier approval flows (e.g., Supervisor → HR Admin) for seamless request resolution.           |
| **Off/Onboarding** | Automated checklists and workflow progression for new hires and exiting staff.                     |

---

## 🚀 Getting Started

1. **Clone the repository:**

   ```bash
   git clone https://github.com/salah-rafat80/HR-App.git
   ```

2. **Fetch Dependencies:**

   ```bash
   # In the root, mobile, and web directories:
   flutter pub get
   ```

3. **Run Code Generation:**

   ```bash
   dart run build_runner build -d
   ```

4. **Launch the App:**
   ```bash
   flutter run -d chrome  # For Web Dashboard
   flutter run            # For Mobile App
   ```

---

<div align="center">
  <i>Built with ❤️ for a smarter workplace.</i>
</div>
