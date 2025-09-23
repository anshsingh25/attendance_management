# Attendance Management System - Flow Chart

## System Overview
```
┌─────────────────────────────────────────────────────────────┐
│                ATTENDANCE MANAGEMENT SYSTEM                │
└─────────────────────────────────────────────────────────────┘

┌─────────────┐  ┌─────────────┐  ┌─────────────┐
│   STUDENT   │  │   TEACHER   │  │    ADMIN    │
│   PORTAL    │  │   PORTAL    │  │   PORTAL    │
└─────────────┘  └─────────────┘  └─────────────┘
       │                │                │
       ▼                ▼                ▼
┌─────────────┐  ┌─────────────┐  ┌─────────────┐
│ Login/Auth  │  │ Login/Auth  │  │ Login/Auth  │
└─────────────┘  └─────────────┘  └─────────────┘
       │                │                │
       ▼                ▼                ▼
┌─────────────┐  ┌─────────────┐  ┌─────────────┐
│ Dashboard   │  │ Dashboard   │  │ Dashboard   │
│ - Sessions  │  │ - Create QR │  │ - Users     │
│ - Mark Att. │  │ - Reports   │  │ - Settings  │
└─────────────┘  └─────────────┘  └─────────────┘
```

## Student Attendance Flow
```
┌─────────────────────────────────────────────────────────────┐
│                    STUDENT ATTENDANCE FLOW                 │
└─────────────────────────────────────────────────────────────┘

┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│ Open App    │───▶│ Check       │───▶│ Select      │
│             │    │ Sessions    │    │ Session     │
└─────────────┘    └─────────────┘    └─────────────┘
                           │                   │
                           ▼                   ▼
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│ Scan QR     │◀───│ Validate    │◀───│ Location    │
│ Code        │    │ QR Code     │    │ Check       │
└─────────────┘    └─────────────┘    └─────────────┘
       │                   │                   │
       ▼                   ▼                   ▼
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│ WiFi Check  │───▶│ Distance    │───▶│ Mark        │
│             │    │ Validation  │    │ Attendance  │
└─────────────┘    └─────────────┘    └─────────────┘
```

## Teacher Session Management
```
┌─────────────────────────────────────────────────────────────┐
│                TEACHER SESSION MANAGEMENT                  │
└─────────────────────────────────────────────────────────────┘

┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│ Login       │───▶│ Create/     │───▶│ Generate    │
│             │    │ Select      │    │ QR Code     │
│             │    │ Class       │    │             │
└─────────────┘    └─────────────┘    └─────────────┘
                           │                   │
                           ▼                   ▼
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│ Display QR  │◀───│ Monitor     │◀───│ Excel       │
│ Code        │    │ Attendance  │    │ Reports     │
└─────────────┘    └─────────────┘    └─────────────┘
       │                   │                   │
       ▼                   ▼                   ▼
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│ End Session │───▶│ Generate    │───▶│ Export      │
│             │    │ Final       │    │ Data        │
│             │    │ Report      │    │             │
└─────────────┘    └─────────────┘    └─────────────┘
```

## Admin Panel Flow
```
┌─────────────────────────────────────────────────────────────┐
│                    ADMIN PANEL FLOW                       │
└─────────────────────────────────────────────────────────────┘

┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│ Login       │───▶│ Dashboard   │───▶│ User        │
│             │    │ - Stats     │    │ Management  │
└─────────────┘    └─────────────┘    └─────────────┘
                           │                   │
                           ▼                   ▼
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│ Class       │◀───│ System      │◀───│ Analytics   │
│ Management  │    │ Settings    │    │ & Reports   │
└─────────────┘    └─────────────┘    └─────────────┘
```

## Password Management Flow
```
┌─────────────────────────────────────────────────────────────┐
│                PASSWORD MANAGEMENT FLOW                   │
└─────────────────────────────────────────────────────────────┘

┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│ User Login  │───▶│ Profile     │───▶│ Change      │
│ (Any Role)  │    │ Settings    │    │ Password    │
└─────────────┘    └─────────────┘    └─────────────┘
                           │                   │
                           ▼                   ▼
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│ Validate    │◀───│ Update      │◀───│ Logout &    │
│ Password    │    │ Database    │    │ Re-login    │
└─────────────┘    └─────────────┘    └─────────────┘
```

## Distance Validation Feature (NEW)
```
┌─────────────────────────────────────────────────────────────┐
│              DISTANCE VALIDATION FEATURE (NEW)            │
└─────────────────────────────────────────────────────────────┘

┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│ Student     │───▶│ Get         │───▶│ Get         │
│ Scans QR    │    │ Student     │    │ Teacher     │
│             │    │ Location    │    │ Location    │
└─────────────┘    └─────────────┘    └─────────────┘
                           │                   │
                           ▼                   ▼
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│ Calculate   │◀───│ Check       │◀───│ Allow/Deny  │
│ Distance    │    │ Threshold   │    │ Attendance  │
└─────────────┘    └─────────────┘    └─────────────┘
```

## Excel Report Generation (NEW)
```
┌─────────────────────────────────────────────────────────────┐
│              EXCEL REPORT GENERATION (NEW)                │
└─────────────────────────────────────────────────────────────┘

┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│ Teacher     │───▶│ Select      │───▶│ Select      │
│ Access      │    │ Date Range  │    │ Class       │
│ Reports     │    │             │    │             │
└─────────────┘    └─────────────┘    └─────────────┘
                           │                   │
                           ▼                   ▼
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│ Generate    │◀───│ Download/   │◀───│ Format      │
│ Report      │    │ View Excel  │    │ Excel Data  │
└─────────────┘    └─────────────┘    └─────────────┘
```

## Key Features Summary

**Core Features:**
- WiFi-based attendance validation
- Location-based geofencing  
- QR code scanning & generation
- Offline support with sync
- Real-time notifications

**New Features:**
- Distance validation between student & teacher devices
- Daily Excel report generation for teachers
- Password management for all users
- Enhanced admin panel with user/class management

**User Roles:**
- **Students**: Mark attendance, view history, scan QR codes
- **Teachers**: Create sessions, generate QR codes, view reports, manage classes
- **Admins**: User management, system settings, analytics, security

**Security:**
- JWT authentication
- Role-based access control
- Location & WiFi validation
- Device fingerprinting
- Audit logging

**Tech Stack:**
- **Frontend**: Flutter, Provider, Material 3
- **Backend**: Node.js, Express, MongoDB
- **Features**: QR scanning, GPS, WiFi validation, Excel generation
