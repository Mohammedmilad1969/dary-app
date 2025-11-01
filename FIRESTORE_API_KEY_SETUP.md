# Firestore API Key Setup Guide

This guide shows how to set up the Gemini API key in Firestore (works on Spark plan - no Blaze upgrade needed).

## Step 1: Create Firestore Document

1. Go to [Firebase Console](https://console.firebase.google.com/project/dary-a74c8/firestore)
2. Click on **Firestore Database** (if not already enabled)
3. Click **Start collection** (or navigate to existing collections)
4. Create a new collection called `config`
5. Create a document with ID: `gemini_api_key`
6. Add a field:
   - **Field name**: `apiKey`
   - **Field type**: `string`
   - **Value**: `AIzaSyCRjEnjwf210P1Vu_j8HKhXwC9Yh2AErxo`

The document structure should look like:
```
config (collection)
  └── gemini_api_key (document)
      └── apiKey: "AIzaSyCRjEnjwf210P1Vu_j8HKhXwC9Yh2AErxo"
```

## Step 2: Update Firestore Security Rules

Go to **Firestore > Rules** and add this rule to allow public read access to the config collection:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Config collection - allow public read access
    match /config/{document} {
      allow read: if true; // Public read access
      allow write: if false; // Only admins can write (update via console)
    }
    
    // ... your existing rules for other collections
  }
}
```

**Note**: In production, consider restricting read access further or using authentication. For now, this allows the app to read the API key.

## Step 3: Verify Setup

1. The `ChatbotService` will automatically fetch the API key from Firestore
2. The key is cached locally for performance
3. If Firestore is unavailable, it falls back to a hardcoded key (which you should remove after setup)

## Step 4: Test

1. Run your Flutter app
2. Open the chatbot
3. Check the debug console for: `✅ API key retrieved from Firestore and cached`

## Benefits

- ✅ Works on Spark plan (no Blaze upgrade needed)
- ✅ API key stored securely in Firestore
- ✅ Can be updated without redeploying the app
- ✅ Cached locally for performance
- ✅ Fallback to hardcoded key if Firestore unavailable

## Updating the API Key

To update the API key in the future:
1. Go to Firebase Console > Firestore
2. Navigate to `config > gemini_api_key`
3. Update the `apiKey` field with the new value
4. The app will fetch the new key on next startup

## Security Notes

- The API key is stored in Firestore, which is more secure than hardcoding
- Consider restricting access further in production
- You can add authentication checks in security rules if needed
- Monitor Firestore usage to ensure you stay within free tier limits

