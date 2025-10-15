class FirebaseConfig {
  // Replace with your actual API key from Firebase Console
  static const String apiKey = 'AIzaSyAttyS8c3dT0eN0vNZXbbamtoqetIMcGp0';
  static const String projectId = 'dary-a74c8';
  
  // Firebase Auth REST API endpoints
  static const String signUpUrl = 'https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$apiKey';
  static const String signInUrl = 'https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=$apiKey';
  static const String getUserUrl = 'https://identitytoolkit.googleapis.com/v1/accounts:lookup?key=$apiKey';
}