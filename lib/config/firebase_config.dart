class FirebaseConfig {
  // Replace with your actual API key from Firebase Console
  static const String apiKey = 'AIzaSyAttyS8c3dT0eN0vNZXbbamtoqetIMcGp0';
  static const String projectId = 'dary-a74c8';
  
  // Google OAuth 2.0 Client ID for Web Sign-In
  static const String googleWebClientId = '998511654081-v422n7lqn8hp7qhal7ie3amtjscl629s.apps.googleusercontent.com';
  
  // Firebase Auth REST API endpoints
  static const String signUpUrl = 'https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$apiKey';
  static const String signInUrl = 'https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=$apiKey';
  static const String getUserUrl = 'https://identitytoolkit.googleapis.com/v1/accounts:lookup?key=$apiKey';
}