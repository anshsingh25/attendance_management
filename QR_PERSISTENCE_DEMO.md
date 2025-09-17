# QR Code Persistence Feature

## Overview
This feature ensures that QR codes remain valid and functional even when a teacher logs out of the portal, until their natural expiration time is reached.

## How It Works

### 1. Teacher Logout Process
When a teacher logs out:
- The system checks if they have any active QR sessions
- Instead of ending these sessions, they are marked as "persistent"
- The QR codes remain valid and students can still scan them
- Sessions continue until their natural expiration time

### 2. QR Code Validation
- Students can scan QR codes even when the teacher is logged out
- The system validates QR codes based on expiration time, not teacher login status
- All existing validation rules (WiFi, location, enrollment) still apply

### 3. Teacher Login Process
When a teacher logs back in:
- The system automatically checks for any persistent sessions
- These sessions are restored to normal active status
- The teacher can continue managing the session as usual

## Backend Changes

### Session Model Updates
```javascript
qrCode: {
  data: String,
  expiresAt: Date,
  isActive: Boolean,
  persistent: Boolean,        // NEW: Marks if QR persists during logout
  teacherLoggedOut: Boolean,  // NEW: Tracks if teacher is logged out
  logoutTime: Date           // NEW: When teacher logged out
}
```

### New API Endpoints
- `GET /api/auth/persistent-sessions` - Get persistent sessions for teacher
- `POST /api/qr/cleanup-expired` - Cleanup expired persistent sessions (admin only)

### Modified Endpoints
- `POST /api/auth/logout` - Now preserves active QR sessions for teachers
- `POST /api/qr/validate` - Now accepts persistent QR codes

## Frontend Changes

### Auth Service
- Added `getPersistentSessions()` method to fetch persistent sessions

### Auth Provider
- Automatically checks for persistent sessions when teacher logs in
- Provides method to manually fetch persistent sessions

### UI Components

#### Home Screen
- **Persistent Sessions Dialog**: Automatically shows when teacher logs in with active persistent sessions
- **Session Information**: Displays class name, subject, and expiration time
- **Quick Navigation**: "Manage Sessions" button to navigate to attendance screen

#### Attendance Screen (Teacher View)
- **Persistent Sessions List**: Shows all active QR sessions with their status
- **Session Status Indicators**: 
  - 🟢 ACTIVE - Normal active session
  - 🟡 PERSISTENT - Session that persisted during logout
  - 🔴 INACTIVE - Expired or ended session
- **Session Management**: View QR code and end session buttons
- **Real-time Updates**: Refresh to get latest session status

## Usage Example

1. **Teacher generates QR code** for a 60-minute session
2. **Teacher logs out** - QR code remains active and scannable
3. **Students continue scanning** the QR code for attendance
4. **Teacher logs back in** - system automatically shows persistent sessions dialog
5. **Teacher can view and manage** the persistent session from the attendance screen
6. **Session continues normally** until the 60-minute expiration

## UI Flow

### Teacher Login with Persistent Sessions
1. Teacher logs in successfully
2. Home screen automatically checks for persistent sessions
3. If found, shows dialog: "You have X active QR session(s) that persisted during your logout"
4. Teacher can click "Manage Sessions" to view detailed session information

### Attendance Screen (Teacher View)
1. Shows list of all active QR sessions
2. Each session displays:
   - Class name and subject
   - Expiration time remaining
   - Status (ACTIVE/PERSISTENT/INACTIVE)
   - Action buttons (View QR / End Session)
3. Teacher can refresh to get latest session status
4. Teacher can end sessions manually if needed

## Benefits

- **Uninterrupted attendance marking** even if teacher's device has issues
- **Flexible teaching** - teachers can step away without ending sessions
- **Better user experience** - no need to regenerate QR codes
- **Automatic cleanup** - expired sessions are properly handled

## Security Considerations

- QR codes still expire at their designated time
- All existing validation rules remain in place
- Only the teacher who created the session can manage it
- Persistent sessions are automatically cleaned up when expired
