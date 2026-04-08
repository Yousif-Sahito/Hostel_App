# Notification Scenarios

This document outlines all the scenarios where push notifications are sent in the Mess App.

## 1. Mess Off Alert (Admin Receives)

**When:** Member marks their mess off or cancels it

**Recipient:** All Admins with FCM token

**Notification:**
- **Title:** "Mess Off Alert"
- **Body:** "{MemberName} has marked their mess off" or "{MemberName} has cancelled their mess off"
- **Data:**
  - `type`: "MESS_OFF"
  - `userId`: member's user ID
  - `messOffStatus`: "ACTIVE" or "CANCELLED"
  - `timestamp`: ISO timestamp

**Trigger Points:**
- `POST /api/messoff` - When new mess off is created
- `PUT /api/messoff/:id` - When mess off status is changed to CANCELLED

---

## 2. Unpaid Bill Reminder (Member Receives)

**When:** Member has not paid bill for 30+ days

**Recipient:** The member with unpaid bill

**Notification:**
- **Title:** "Unpaid Bill Reminder"
- **Body:** "Your bill of PKR {amount} is {daysOverdue} days overdue. Please pay as soon as possible."
- **Data:**
  - `type`: "UNPAID_BILL"
  - `userId`: member's user ID
  - `amount`: bill amount
  - `daysOverdue`: number of days overdue
  - `timestamp`: ISO timestamp

**Schedule:** Runs daily at 8 AM (server time)

**Trigger:**
- Automatically checks all UNPAID bills older than 30 days
- Called by: `node-cron` scheduler in `scheduleUnpaidBillNotifications()`

---

## 3. Future Notifications (Can be Added)

### 3.1 Payment Received (Admin Receives)
```
Title: "Payment Received"
Body: "{MemberName} has paid PKR {amount}"
Data: { type: "PAYMENT_RECEIVED", amount, timestamp }
```

### 3.2 Low Meal Balance Warning (Member Receives)
```
Title: "Low Meal Balance"
Body: "Your meal balance is PKR {balance}. Please add funds."
Data: { type: "LOW_BALANCE", balance, timestamp }
```

### 3.3 Room Assignment (Member Receives)
```
Title: "Room Assignment"
Body: "You have been assigned to Room {roomNumber}"
Data: { type: "ROOM_ASSIGNMENT", roomNumber, timestamp }
```

---

## Configuration

### Daily Scheduler Configuration

File: `src/config/scheduler.js`

```javascript
// Current: Runs at 8 AM daily
cron.schedule('0 8 * * *', async () => {
  await sendBatchUnpaidBillNotifications(30);
});
```

**Cron Pattern Explanation:**
- `0` = minute (0)
- `8` = hour (8 AM)
- `*` = day of month (any)
- `*` = month (any)
- `*` = day of week (any)

**To change the time:**
- `0 9 * * *` → 9 AM
- `0 18 * * *` → 6 PM
- `0 */6 * * *` → Every 6 hours

### Unpaid Bill Threshold

File: `src/services/notification.service.js`

```javascript
export const sendBatchUnpaidBillNotifications = async (daysThreshold = 30) => {
  // Change 30 to any number of days
}
```

Called with default 30 days from scheduler. To change, update:
```javascript
await sendBatchUnpaidBillNotifications(45); // 45 days instead
```

---

## Missing FCM Token Handling

If a user doesn't have an FCM token:
- Notifications are silently skipped (no error)
- `console.log` will show: "User FCM token not found"
- User can update token by logging in again

---

## Database Field

### User Model Addition

```prisma
model User {
  ...
  fcmToken         String?
  ...
}
```

The field is **optional** (`?`), so existing users won't have issues.

To see all users with tokens:
```sql
SELECT id, fullName, email, fcmToken FROM User WHERE fcmToken IS NOT NULL;
```

---

## Notification Persistence

Currently, notifications are **NOT stored** in the database. They are:
- Sent directly to Firebase Cloud Messaging
- Displayed on the user's device
- Can be intercepted/logged in the app

**To add persistence, create a `Notification` model:**
```prisma
model Notification {
  id          Int     @id @default(autoincrement())
  userId      Int
  title       String
  body        String
  type        String
  data        Json?
  read        Boolean @default(false)
  sentAt      DateTime @default(now())
  user        User    @relation(fields: [userId], references: [id])
}
```

---

## Error Handling

### Firebase Send Fails

If Firebase cannot send a notification:
1. Error is logged: `console.error('Error sending notification:', error.message)`
2. Request to backend still succeeds
3. User is not notified of the notification failure
4. Operation continues normally

### Network Issues

If device cannot receive notifications:
1. Firebase automatically retries for a period
2. User sees notification when network is restored
3. Old notifications are not shown

---

## Testing Notifications

### Manual Test on Backend

Create a test endpoint to send notifications:

```javascript
router.post('/test-notification', protect, async (req, res) => {
  const { userId, title, body } = req.body;
  await sendUnpaidBillNotification(userId, title, body, 35);
  res.json({ success: true });
});
```

Then call:
```bash
curl -X POST http://localhost:5000/api/auth/test-notification \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"userId": 1, "title": "Test", "body": "Test message"}'
```

### Check Device FCM Token

In Flutter Debug Console:
```
I: FCM Token: <token_string_here>
```

---

## Notification Delivery Performance

- **Mess Off**: Immediate (when mess off is created/updated)
- **Unpaid Bill**: Daily check at 8 AM (batched to all eligible members)
- **Firebase Delivery**: Usually < 1 second
- **Device Reception**: Depends on network/Firebase queue

---

## Compliance Notes

- ✅ Users can disable notifications in device settings
- ✅ FCM token is only stored if user logs in
- ✅ Token is deleted on logout (optional, currently commented)
- ❓ Consider adding opt-in notification preferences to app settings

