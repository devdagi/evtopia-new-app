// Alternative login implementations to test
// Copy one of these into your auth_service.dart login method to test

// Option 1: Use 'login' field for both email and phone
final response = await _api.dio.post<Map<String, dynamic>>(
  ApiConstants.loginPath,
  data: {
    'login': trimmed,  // Single field for both
    'password': password,
  },
);

// Option 2: Always send both email and phone fields
final response = await _api.dio.post<Map<String, dynamic>>(
  ApiConstants.loginPath,
  data: {
    'email': isEmail ? trimmed : '',
    'phone': !isEmail ? trimmed : '',
    'password': password,
  },
);

// Option 3: Use 'username' field
final response = await _api.dio.post<Map<String, dynamic>>(
  ApiConstants.loginPath,
  data: {
    'username': trimmed,
    'password': password,
  },
);

// Option 4: Check if password needs confirmation
final response = await _api.dio.post<Map<String, dynamic>>(
  ApiConstants.loginPath,
  data: {
    if (isEmail) 'email': trimmed,
    if (!isEmail) 'phone': trimmed,
    'password': password,
    'password_confirmation': password,  // Some APIs need this
  },
);
