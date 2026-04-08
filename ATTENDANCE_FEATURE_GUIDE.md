# Attendance & Unit Exemption Feature

## Overview

This feature allows administrators to mark members as **in attendance** on specific dates. When a member is marked as in attendance, their meal units for that date are **automatically disabled and not charged** in the billing system.

**Key Benefit:** Members who are present in the hostel but not consuming meals (or are exempted) won't have meal charges applied to their bill.

---

## How It Works

### 1. **Schema Design**

A new `Attendance` model has been added to track member attendance:

```prisma
model Attendance {
  id              Int       @id @default(autoincrement())
  userId          Int
  attendanceDate  DateTime
  isPresent       Boolean   @default(true)
  remarks         String?
  createdAt       DateTime  @default(now())
  updatedAt       DateTime  @updatedAt

  user            User      @relation(fields: [userId], references: [id], onDelete: Cascade)

  @@unique([userId, attendanceDate])
}
```

### 2. **Billing Logic Change**

During bill generation, the system now checks for attendance records:

**Before (Old Logic):**
```
For each meal:
  - If member is on MessOff → Skip (no units)
  - Else → Count units for billing
```

**After (New Logic):**
```
For each meal:
  - If member is on MessOff → Skip (no units)
  - If member is marked in attendance → Skip (no units) ✅ NEW
  - Else → Count units for billing
```

### 3. **API Endpoints**

#### Mark Attendance (Single Member)
```
POST /api/attendance
Content-Type: application/json

{
  "userId": 5,
  "attendanceDate": "2026-04-08",
  "isPresent": true,
  "remarks": "Member present in hostel"
}

Response (201 Created):
{
  "success": true,
  "message": "Attendance marked successfully",
  "data": {
    "id": 1,
    "userId": 5,
    "attendanceDate": "2026-04-08T00:00:00.000Z",
    "isPresent": true,
    "remarks": "Member present in hostel",
    "createdAt": "2026-04-08T10:30:00.000Z"
  }
}
```

#### Bulk Mark Attendance (Multiple Members)
```
POST /api/attendance/bulk
Content-Type: application/json

{
  "attendanceDate": "2026-04-08",
  "memberIds": [1, 2, 3, 4, 5],
  "isPresent": true
}

Response (200 OK):
{
  "success": true,
  "message": "Attendance marked for 5 members",
  "data": [
    { "id": 1, "userId": 1, "attendanceDate": "2026-04-08", "isPresent": true },
    { "id": 2, "userId": 2, "attendanceDate": "2026-04-08", "isPresent": true },
    ...
  ]
}
```

#### Get Member Attendance
```
GET /api/attendance/member/5

Response (200 OK):
{
  "success": true,
  "message": "Attendance records fetched successfully",
  "data": [
    {
      "id": 1,
      "userId": 5,
      "attendanceDate": "2026-04-08",
      "isPresent": true,
      "remarks": null
    }
  ]
}
```

#### Get Attendance by Date Range
```
GET /api/attendance/range?fromDate=2026-04-01&toDate=2026-04-30

Response (200 OK):
{
  "success": true,
  "message": "Attendance records fetched successfully",
  "data": [
    {
      "id": 1,
      "userId": 5,
      "attendanceDate": "2026-04-08",
      "isPresent": true,
      "user": {
        "id": 5,
        "fullName": "Ahmed Hassan",
        "email": "ahmed@example.com"
      }
    }
  ]
}
```

#### Get All Attendance Records
```
GET /api/attendance

Response (200 OK):
{
  "success": true,
  "message": "All attendance records fetched successfully",
  "data": [...]
}
```

#### Delete Attendance Record
```
DELETE /api/attendance/1

Response (200 OK):
{
  "success": true,
  "message": "Attendance record deleted successfully",
  "data": { "id": 1, "userId": 5, "attendanceDate": "2026-04-08" }
}
```

---

## Access Control

### Permissions

| Operation | Required Role | Description |
|-----------|--------------|-------------|
| Mark attendance | ADMIN | Only admins can mark members as in attendance |
| Bulk mark attendance | ADMIN | Only admins can mark multiple members |
| View all attendance | ADMIN | Only admins can view all records |
| View date range | ADMIN | Only admins can filter by date range |
| View member attendance | MEMBER or ADMIN | Members can view their own, admins can view all |
| Delete attendance | ADMIN | Only admins can delete records |

---

## Practical Example

### Scenario: Annual Hostel Meeting

**Date:** April 10, 2026  
**Event:** Annual Hostel Meeting (all members must attend, no meals provided)

**Step 1: Mark All Members as In Attendance**
```bash
POST /api/attendance/bulk
{
  "attendanceDate": "2026-04-10",
  "memberIds": [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
  "isPresent": true
}
```

**Step 2: Members Record Meals (if any)**
- Admin or members mark that they took meals on that date
- Meals are recorded as usual in MealEntry

**Step 3: Bill Generation (April)**
```bash
POST /api/bills/generate
{
  "month": 4,
  "year": 2026
}
```

**Result:**
- Even though members have meal entries for April 10
- Their attendance record marks them as present
- **Billing system skips these meals** (units = 0)
- No charges applied for April 10

---

## Database Changes

### Migration: `add_attendance_model`

**New Table:** `attendance`

```sql
CREATE TABLE `attendance` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `userId` INT NOT NULL,
  `attendanceDate` DATETIME NOT NULL,
  `isPresent` BOOLEAN DEFAULT true,
  `remarks` VARCHAR(255),
  `createdAt` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `updatedAt` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE (`userId`, `attendanceDate`),
  FOREIGN KEY (`userId`) REFERENCES `user`(`id`) ON DELETE CASCADE
);
```

### Schema Updates

**User Model Enhancement:**
```prisma
model User {
  // ... existing fields ...
  attendanceRecords Attendance[]  // ✅ NEW relation
}
```

---

## Implementation Details

### Billing Service Changes

**File:** `backend/src/services/billing.service.js`

**Added Code:**
```javascript
// Fetch attendance records for the month
const attendanceRecords = await prisma.attendance.findMany({
  where: {
    attendanceDate: {
      gte: new Date(year, month - 1, 1),
      lt: new Date(year, month, 1)
    }
  }
});

// In meal processing loop:
const isInAttendance = attendanceRecords.some(
  (record) =>
    record.userId === meal.userId &&
    record.attendanceDate.toDateString() === meal.mealDate.toDateString() &&
    record.isPresent === true
);

// Skip meals if member is marked in attendance
if (isMessOff || isInAttendance) continue;
```

### Controller Implementation

**File:** `backend/src/controllers/attendance.controller.js`

**Functions:**
- `markAttendance()` - Mark single member attendance
- `getMemberAttendance()` - Get member's attendance records
- `getAttendanceByDateRange()` - Get attendance for date range
- `getAllAttendance()` - Get all attendance records
- `deleteAttendance()` - Delete attendance record
- `bulkMarkAttendance()` - Mark multiple members at once

### Routes Setup

**File:** `backend/src/routes/attendance.routes.js`

All routes are protected with authentication and admin authorization (where applicable).

---

## Testing

### Test Case 1: Mark Attendance and Generate Bill

1. **Setup:**
   - Create 3 members
   - April 2026, Breakfast: 100/unit, Lunch: 150/unit, Dinner: 120/unit

2. **Day 1 (April 1):** Normal day
   - All members record meals (breakfast, lunch, dinner)
   - No attendance mark
   - **Expected units:** 3 each

3. **Day 2 (April 2):** Special event
   - All members record meals
   - Mark all as in attendance
   - **Expected units after bill:** 0 (attendance takes precedence)

4. **Bill Generation:**
   - Member 1: Should be charged only for April 1 meals
   - Member 2: Should be charged only for April 1 meals
   - Member 3: Should be charged only for April 1 meals

### Test Case 2: Attendance Priorities

**MessOff Period vs Attendance:**
- If a member has both MessOff and Attendance on same date
- **Result:** No units charged (both conditions skip the meal)
- **Priority:** Both conditions are checked independently (both skip)

---

## Best Practices

### ✅ DO

- ✅ Mark attendance **same day** for accurate tracking
- ✅ Use **bulk mark** for large groups at events
- ✅ Add **remarks** to explain why attendance is marked
- ✅ Review attendance records **before** generating bills
- ✅ Keep attendance records as **documentation**

### ❌ DON'T

- ❌ Use attendance to cancel bills retroactively
- ❌ Mark attendance without clear reason
- ❌ Create duplicate attendance records (unique constraint prevents this)
- ❌ Forget to sync with meal records (system handles this automatically)
- ❌ Delete attendance without verification (audit trail may be needed)

---

## Troubleshooting

### Issue: Meals still charged despite attendance mark

**Check:**
1. Is the date format correct? (`YYYY-MM-DD`)
2. Are attendance and meal dates exactly the same?
3. Is `isPresent` set to `true`?
4. Did you regenerate bills **after** marking attendance?

**Solution:**
```javascript
// Verify attendance was created
GET /api/attendance/range?fromDate=2026-04-08&toDate=2026-04-08

// Verify meal exists
GET /api/meals/member/5

// Regenerate bill
POST /api/bills/generate
```

### Issue: Can't mark attendance (403 Forbidden)

**Cause:** Only admins can mark attendance

**Solution:**
- Log in as admin user
- Verify JWT token in Authorization header
- Check user role in database

### Issue: Unique constraint violation

**Cause:** Trying to create duplicate attendance for same user + date

**Solution:**
```javascript
// Instead of creating, update existing
POST /api/attendance
{
  "userId": 5,
  "attendanceDate": "2026-04-08",
  "isPresent": false  // Change to mark as absent
}
```

---

## Future Enhancements

### Potential Features

1. **Attendance Dashboard**
   - Monthly attendance summary per member
   - Present/absent percentage
   - Trend analysis

2. **Auto-Attendance Rules**
   - Mark all members as present on Sundays
   - Skip attendance for MessOff periods automatically
   - Holiday calendar integration

3. **Bulk Operations**
   - Import attendance from CSV
   - Export attendance reports
   - Scheduled attendance cleanup

4. **Notifications**
   - Notify members when marked in attendance
   - Alert admins of excessive absenteeism
   - Reminder emails for pending attendance marking

5. **Integration with Meals**
   - Prevent meal recording if marked absent
   - Auto-calculate optimal meal count
   - Attendance-based meal recommendations

---

## Configuration

### Environment Variables

No new environment variables needed. Existing `.env` suffices.

### Database Connection

The attendance model automatically uses the configured MySQL connection.

---

## Summary

| Aspect | Details |
|--------|---------|
| **Model Added** | `Attendance` |
| **Routes Added** | 6 endpoints under `/api/attendance` |
| **Database Changes** | New `attendance` table with unique constraint |
| **Billing Impact** | Meals skipped if member marked in attendance |
| **Access Control** | Admin-only for write operations |
| **Backward Compatible** | Yes - existing bills unaffected |
| **Data Reset Required** | Yes - `prisma migrate reset` applied |

---

**Created:** April 8, 2026  
**Feature:** Attendance & Unit Exemption System  
**Status:** ✅ Implemented and Ready for Use
