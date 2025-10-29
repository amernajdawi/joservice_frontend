class ApiConfig {
  // Production backend URL - Render
  static const String productionBaseUrl = 'https://joservice-backend.onrender.com';
  
  // API endpoints
  static const String apiBaseUrl = '$productionBaseUrl/api';
  
  // WebSocket endpoints
  static const String wsBaseUrl = 'wss://joservice-backend.onrender.com';
  
  // File uploads
  static const String uploadsBaseUrl = '$productionBaseUrl/uploads';
  
  // Profile pictures
  static const String profilePicturesBaseUrl = '$productionBaseUrl/uploads/profile-pictures';
}
