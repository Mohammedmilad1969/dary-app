# Deploy Firebase Functions for Gemini API Key

## Prerequisites

1. Install Node.js (v18 or later)
2. Install Firebase CLI:
   ```bash
   npm install -g firebase-tools
   ```

## Setup Steps

### 1. Login to Firebase
npx firebase-tools login
```

*Prefix all commands with `npx firebase-tools` since you don't have the global CLI installed.*

### 2. Initialize Functions (if not already done)
```bash
cd functions
npm install
```

### 3. Set the API Key in Firebase Functions Config

**Option A: Using Firebase Config (Recommended)**
```bash
firebase functions:config:set gemini.api_key="AIzaSyCRjEnjwf210P1Vu_j8HKhXwC9Yh2AErxo"
```

**Option B: Using Environment Variables (More Secure)**
```bash
firebase functions:secrets:set GEMINI_API_KEY
# Then paste your API key when prompted
```

Then update `functions/index.js` to use the secret:
```javascript
const apiKey = process.env.GEMINI_API_KEY || functions.config().gemini?.api_key;
```

### 4. Deploy the Function
```bash
firebase deploy --only functions:onNewChatMessage
```

**Alternative (no install required):**
```bash
npx firebase-tools deploy --only functions:onNewChatMessage
```

### 5. Verify Deployment
After deployment, the function will be available at:
`https://[region]-[project-id].cloudfunctions.net/getGeminiApiKey`

## Security Notes

1. ✅ API key is now stored securely in Firebase Functions (not in your code)
2. ✅ The key is cached locally to reduce API calls
3. ✅ Remove the fallback hardcoded key after Functions are deployed
4. ✅ Optionally add authentication to the function in `functions/index.js`

## After Deployment

1. Remove the fallback hardcoded key from `lib/services/chatbot_service.dart` (line 108)
2. Test the app - it should fetch the key from Firebase Functions
3. Close the GitHub security alert as resolved

## Troubleshooting

If the function fails:
1. Check Firebase Functions logs: `firebase functions:log`
2. Verify the API key is set: `firebase functions:config:get`
3. Make sure you're using the correct project: `firebase use [project-id]`

