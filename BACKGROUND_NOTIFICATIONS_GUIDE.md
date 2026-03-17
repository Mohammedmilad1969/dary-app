# Detailed Guide: Enbaling Background Notifications

To make notifications show up when your app is **closed (killed)** or in the **background**, follow these 3 critical steps.

---

**1. Sync Dependencies (Do this once):**
```bash
cd functions && npm install && cd ..
```

**2. Fix "EACCES" or Permission Errors (If they happen):**
```bash
chmod +x functions/node_modules/.bin/firebase-functions
```

**3. Deploy the Trigger:**
```bash
npx firebase-tools deploy --only functions:onNewChatMessage
```

**4. ⚠ Important for First-Time Users:**
If your deployment fails with a "Permission denied while using the Eventarc Service Agent" error:
*   **Wait 5-10 minutes.** Google is still enabling APIs in the background.
*   **Run the deploy command again.** It will work after the background setup finishes.

---

### Step 2: Get the "Key" from Apple (iOS Only)
Firebase needs "permission" from Apple to talk to your iPhone.

1.  Log in to the [Apple Developer Portal](https://developer.apple.com/account/resources/authkeys/list).
2.  Go to **Certificates, Identifiers & Profiles** > **Keys**.
3.  Click the **+** (Plus) button.
4.  Name it: `Dary Push Key`.
5.  Check the box for **Apple Push Notifications service (APNs)**.
6.  Click **Continue** -> **Register**.
7.  **IMPORTANT:** Download the `.p8` file. Move it to a safe place.
    *   *Note: You can only download this file ONCE.*
8.  Copy the **Key ID** (10 characters) and your **Team ID** (visible in the top right of the portal).

---

### Step 3: Link Apple to Firebase
Now, give that key to Firebase.

1.  Open the [Firebase Console](https://console.firebase.google.com/).
2.  Go to your Project: `dary-a74c8`.
3.  Click the **Gear Icon** (Project Settings) > **Cloud Messaging**.
4.  Scroll down to **Apple app configuration**.
5.  Under your iOS app (`com.example.dary`), find **APNs Authentication Key**.
6.  Click **Upload**.
7.  Upload the `.p8` file you downloaded.
8.  Enter the **Key ID** and **Team ID** from Step 2.
9.  Click **Upload**.

---

### Step 4: Verify on device
1.  Uninstall the app from your physical iPhone.
2.  Install it again using `flutter run --release`.
3.  Log in (this saves your current FCM Token to the database).
4.  **Close the app completely** (swipe it away).
5.  Send a message from another account.
6.  **Success:** You should see a notification on your lock screen!

---

### Troubleshooting Checklist
*   **Physical Device:** Simulators **never** receive background push notifications.
*   **Release Mode:** Use `--release` for the most accurate testing.
*   **Bundle ID:** Ensure `com.example.dary` matches exactly in Firebase and Apple.
*   **FCM Token:** Check Firestore > `users` > `[your-id]`. Ensure the `fcmToken` field exists and is updated.
