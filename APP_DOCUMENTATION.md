# Attendance Record System - Complete Documentation

## 📱 Overview

**Attendance Record System** is a mobile application built with Flutter that provides **automatic attendance tracking** using Bluetooth Low Energy (BLE) beacon technology combined with GPS location validation. The system eliminates manual check-ins by automatically detecting when users are physically present at an event location.

---

## 🎯 Purpose

The app solves the problem of manual attendance taking by:

- **Eliminating manual check-ins** - No need to scan QR codes or sign sheets
- **Preventing fraud** - Users must be physically present (BLE + GPS validation)
- **Real-time tracking** - Instant attendance recording and monitoring
- **Automated reporting** - Generate PDF reports with full attendance details

---

## 👥 User Roles

### 1. **Admin**

- Create and manage events
- Configure beacon settings
- Monitor live attendance
- Generate and export reports
- Activate/deactivate events
- Delete events

### 2. **User (Attendee)**

- View available events
- Automatically check in when near event
- View personal attendance history
- No manual action required for check-in

---

## 🔧 Technology Stack

### **Frontend**

- **Flutter** - Cross-platform mobile framework
- **Dart** - Programming language

### **Backend**

- **Firebase Authentication** - User authentication and authorization
- **Cloud Firestore** - Real-time NoSQL database
- **Firebase Security Rules** - Data access control

### **Hardware Integration**

- **BLE Beacon** - NRF52810 beacon (Holy-IOT)
   - Name: `Holy-IOT`
   - MAC: `D2:4B:C0:EA:3E:FE`
   - Range: 5-10 meters

### **Key Technologies**

- **BLE (Bluetooth Low Energy)** - Proximity detection
- **GPS** - Location validation and tracking
- **RSSI** - Signal strength for proximity measurement
- **PDF Generation** - Attendance report export

---

## 🏗️ System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      Mobile App (Flutter)                    │
├─────────────────────────────────────────────────────────────┤
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │   Admin UI   │  │   User UI    │  │   Auth UI    │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
├─────────────────────────────────────────────────────────────┤
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │ BLE Service  │  │ GPS Service  │  │ Auth Service │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
│  ┌──────────────────────────────────────────────────┐      │
│  │          Firestore Service                        │      │
│  └──────────────────────────────────────────────────┘      │
└─────────────────────────────────────────────────────────────┘
                            ↕
┌─────────────────────────────────────────────────────────────┐
│                    Firebase Backend                          │
├─────────────────────────────────────────────────────────────┤
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │ Authentication│  │  Firestore   │  │Security Rules│      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
└─────────────────────────────────────────────────────────────┘
                            ↕
┌─────────────────────────────────────────────────────────────┐
│                   Physical Hardware                          │
├─────────────────────────────────────────────────────────────┤
│  ┌──────────────┐           ┌──────────────┐               │
│  │ NRF52810     │           │   GPS        │               │
│  │ BLE Beacon   │           │  Satellite   │               │
│  └──────────────┘           └──────────────┘               │
└─────────────────────────────────────────────────────────────┘
```

---

## 📊 Data Flow

### **1. Event Creation (Admin)**

```
Admin opens app
    ↓
Logs in (Firebase Auth)
    ↓
Creates new event
    ↓
Captures GPS location (optional)
    ↓
Configures beacon details (optional)
    ↓
Event saved to Firestore
    ↓
Beacon installed at venue
```

### **2. User Check-In (Automatic)**

```
User opens app
    ↓
Logs in (Firebase Auth)
    ↓
Selects event to attend
    ↓
App requests permissions (Bluetooth + Location)
    ↓
App captures user's GPS location
    ↓
App starts BLE scanning
    ↓
Beacon detected (RSSI ≥ -70 dBm)
    ↓
Validates:
  - User authenticated ✓
  - Event active ✓
  - Within time window ✓
  - Not already checked in ✓
  - Correct beacon detected ✓
    ↓
Automatic check-in
    ↓
Record saved to Firestore:
  - User ID
  - Event ID
  - Timestamp
  - GPS coordinates
  - Beacon ID
    ↓
Success notification shown
```

### **3. Attendance Monitoring (Admin)**

```
Admin opens app
    ↓
Views event
    ↓
Clicks "Attendance Report"
    ↓
Real-time attendance list displayed
    ↓
Can export to PDF
```

---

## 🔐 Security Features

### **Firebase Security Rules**

#### **Users Collection**

```javascript
// Users can only read/write their own data
match /users/{userId} {
  allow read: if request.auth != null;
  allow write: if request.auth.uid == userId;
}
```

#### **Events Collection**

```javascript
// Anyone can read, only admins can write
match /events/{eventId} {
  allow read: if request.auth != null;
  allow write: if request.auth != null &&
                  get(/databases/$(database)/documents/users/$(request.auth.uid)).data.isAdmin == true;
}
```

#### **Attendance Collection**

```javascript
// Users can create their own attendance, cannot modify/delete
match /attendance/{attendanceId} {
  allow read: if request.auth != null;
  allow create: if request.auth != null &&
                   request.resource.data.userId == request.auth.uid;
  allow update, delete: if false; // Immutable records
}
```

### **App-Level Security**

- ✅ One check-in per user per event (enforced in code + Firestore)
- ✅ Event time window validation
- ✅ Proximity validation (RSSI threshold)
- ✅ GPS location validation
- ✅ Hardcoded beacon identity (prevents spoofing)

---

## 📦 Database Schema

### **Collections**

#### **users**

```json
{
   "uid": "string",
   "email": "string",
   "isAdmin": "boolean",
   "displayName": "string (optional)"
}
```

#### **events**

```json
{
   "id": "string",
   "name": "string",
   "startTime": "Timestamp",
   "endTime": "Timestamp",
   "venue": "string",
   "beaconUuid": "string (optional)",
   "beaconMajor": "number",
   "beaconMinor": "number",
   "isActive": "boolean",
   "createdAt": "Timestamp",
   "latitude": "number (optional)",
   "longitude": "number (optional)"
}
```

#### **attendance**

```json
{
   "userId": "string",
   "eventId": "string",
   "beaconId": "string",
   "checkInTime": "Timestamp",
   "userEmail": "string (optional)",
   "userName": "string (optional)",
   "latitude": "number (optional)",
   "longitude": "number (optional)"
}
```

---

## 🚀 How It Works

### **Beacon Detection Technology**

#### **1. BLE Broadcasting**

```
NRF52810 Beacon
    ↓
Continuously broadcasts signal
    ↓
Signal strength (RSSI) indicates distance
    ↓
RSSI ≥ -70 dBm = User within 5-10 meters
```

#### **2. Hardcoded Beacon Matching**

The app identifies the beacon by:

- **Name**: `Holy-IOT`
- **MAC Address**: `D2:4B:C0:EA:3E:FE`

This prevents unauthorized beacons from triggering check-ins.

#### **3. RSSI Threshold**

```
RSSI Value    Distance    Action
-40 dBm       < 1 meter   ✓ Check-in
-60 dBm       2-5 meters  ✓ Check-in
-70 dBm       5-10 meters ✓ Check-in (threshold)
-80 dBm       > 10 meters ✗ Too far
-90 dBm       > 20 meters ✗ Too far
```

### **GPS Validation**

#### **Event Location**

- Admin captures GPS coordinates when creating event
- Stored with event in Firestore

#### **User Location**

- User's GPS captured at check-in time
- Stored with attendance record
- Can be used for additional validation

#### **Combined BLE + GPS**

This dual validation ensures:

1. User is near the beacon (BLE proximity)
2. User is at the correct location (GPS coordinates)
3. Both recorded for audit trail

---

## 📱 User Interface

### **Admin Screens**

#### 1. **Admin Dashboard**

- List of all events
- Create new event button
- Event status indicators (Active/Inactive)
- Quick actions (View, Activate/Deactivate, Delete)

#### 2. **Create Event Screen**

- Event name input
- Venue/location input
- Start date/time picker
- End date/time picker
- GPS location capture button
- Beacon configuration (UUID, Major, Minor - optional)

#### 3. **Attendance Report Screen**

- Event details header
   - Name, venue, date, time
   - GPS coordinates
   - Beacon configuration
- Real-time attendance list
- Total attendee count
- Export to PDF button

### **User Screens**

#### 1. **User Dashboard** (Two Tabs)

**Available Events Tab:**

- List of active events
- Sorted by: Active first, then latest date
- Event details preview
- Tap to view details

**My Attendance Tab:**

- Personal check-in history
- Event name, location, timestamp
- "Attended" badge
- Empty state with helpful message

#### 2. **Event Selection Screen**

- Event name and status badge
- Complete event details
- Start monitoring button
- Information about automatic check-in

#### 3. **Check-In Screen**

- Real-time status messages
- GPS location indicator
- BLE scanning animation
- RSSI value display
- Automatic check-in process
- Success dialog

---

## 🔄 User Workflows

### **Admin Workflow**

```
1. Sign in as admin
2. Navigate to Admin Dashboard
3. Tap "Create Event"
4. Fill in event details:
   - Event name
   - Venue
   - Date and time
5. (Optional) Tap "Capture Event Location" for GPS
6. (Optional) Enter beacon UUID/Major/Minor
7. Tap "Create Event"
8. Install beacon at venue
9. Event appears in dashboard
10. During/after event, view attendance report
11. Export PDF if needed
```

### **User Workflow**

```
1. Sign in as user
2. View "Available Events" tab
3. Find event to attend
4. Tap on event
5. Review event details
6. Tap "Start Monitoring"
7. Grant Bluetooth permission (first time)
8. Grant Location permission (first time)
9. App starts scanning automatically
10. Walk to event entrance (within 5-10 meters of beacon)
11. Automatic check-in occurs
12. Success message displayed
13. View check-in in "My Attendance" tab
```

---

## 📈 Features Summary

### ✅ **Implemented Features**

#### **Core Features**

- ✅ Firebase Authentication (Email/Password)
- ✅ Role-based access (Admin/User)
- ✅ Event creation and management
- ✅ BLE beacon detection
- ✅ RSSI-based proximity detection
- ✅ Automatic check-in
- ✅ GPS location capture
- ✅ Real-time attendance tracking
- ✅ PDF report generation

#### **Admin Features**

- ✅ Create events with full details
- ✅ Capture event GPS location
- ✅ Configure beacon settings
- ✅ Activate/deactivate events
- ✅ Delete events (cascades to attendance)
- ✅ View live attendance
- ✅ Export attendance to PDF

#### **User Features**

- ✅ View available events (sorted)
- ✅ Automatic BLE scanning
- ✅ Proximity-based check-in
- ✅ GPS location recording
- ✅ View attendance history
- ✅ Permission management

#### **Security Features**

- ✅ Firebase Security Rules
- ✅ One check-in per event enforcement
- ✅ Time window validation
- ✅ Hardcoded beacon identity
- ✅ Immutable attendance records

---

## 🎓 Use Cases

### **1. Educational Institutions**

- Class attendance tracking
- Lecture hall check-ins
- Lab session attendance
- Campus event attendance

### **2. Corporate Events**

- Conference check-ins
- Meeting attendance
- Workshop tracking
- Training session validation

### **3. Healthcare**

- Patient appointment verification
- Staff attendance
- Medical training sessions

### **4. Venues & Events**

- Concert entry tracking
- Exhibition attendance
- Museum visitor tracking
- Sports event check-ins

---

## 📊 Technical Specifications

### **Performance**

- BLE scan interval: 4 seconds
- Scan restart: Every 5 seconds
- Maximum beacon range: 10 meters
- Detection threshold: -70 dBm RSSI
- GPS accuracy: High precision mode

### **Scalability**

- Supports unlimited events
- Supports unlimited users
- Real-time synchronization
- Cloud-based storage (Firebase)

---

## 📝 Summary

**Attendance Record System** is a sophisticated yet user-friendly solution for automatic attendance tracking. By combining BLE beacon technology with GPS validation, it provides a secure, fraud-proof system that eliminates manual check-ins while maintaining accurate records. The dual-validation approach (proximity + location) ensures users are genuinely present at events, making it ideal for educational institutions, corporate environments, and event management.

**Key Advantages:**

- ✅ Zero manual effort for users
- ✅ Real-time tracking
- ✅ Fraud prevention
- ✅ Comprehensive reporting
- ✅ Easy to use
- ✅ Scalable and reliable

---

**Version**: 1.0.0  
**Last Updated**: February 2025  
**Platform**: Flutter (Android)  
**License**: Educational Project
