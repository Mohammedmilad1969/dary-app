const functions = require("firebase-functions");

exports.getGeminiApiKey = functions.https.onCall(async (data, context) => {
  // Optional: Add authentication check
  // (uncomment if you want to restrict access)
  // if (!context.auth) {
  //   throw new functions.https.HttpsError(
  //     'unauthenticated',
  //     'User must be authenticated to get API key'
  //   );
  // }

  // Use environment variable (recommended) or fallback to config
  const config = functions.config();
  const apiKey = process.env.GEMINI_API_KEY ||
    (config.gemini && config.gemini.api_key ? config.gemini.api_key : null);

  if (!apiKey) {
    throw new functions.https.HttpsError(
        "internal",
        "API key not configured in Firebase Functions",
    );
  }

  return {apiKey: apiKey};
});
