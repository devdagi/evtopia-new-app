/// API configuration constants.
/// Base URL can be overridden via --dart-define=API_BASE_URL=https://example.com
class ApiConstants {
  ApiConstants._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://evtopia.co',
  );

  static const String registerPath = '/api/registration';
  static const String loginPath = '/api/login';
  static const String sendOtpPath = '/api/send-otp';
  static const String verifyOtpPath = '/api/verify-otp';
  static const String resetPasswordPath = '/api/reset-password';
  
  static const String logoutPath = '/api/logout';
  static const String mePath = '/api/me';
  static const String refreshPath = '/api/refresh';
  static const String updateProfilePath = '/api/update-profile';
  static const String changePasswordPath = '/api/change-password';

  static const String homePath = '/api/home';
  static const String bannersPath = '/api/banners';
  static const String servicesPath = '/api/services';
  static const String serviceDetailsPath = '/api/service-details';
  static const String blogsPath = '/api/mobile_blogs';
  static const String blogDetailsPath = '/api/blog-details';
  static const String latestEvsPath = '/api/latest-evs';
  static const String latestProductsPath = '/api/latest-products';
  static const String serviceRequestsPath = '/api/service-requests';
  static const String productsPath = '/api/products';
  static const String productDetailsPath = '/api/product-details';
  static const String favoriteAddOrRemovePath = '/api/favorite-add-or-remove';
  static const String favoriteProductsPath = '/api/favorite-products';
  static const String shopsPath = '/api/shops';
  static const String contactUsPath = '/api/contact-us';

  // Notifications (backend: user_id query param)
  static const String mobileNotificationsPath = '/api/mobile-notifications';
  static const String countNotificationPath = '/api/count_notification';
  static const String notificationReadAllPath = '/api/notification/read-all';
  static String notificationReadPath(int id) => '/api/notification/$id/read';
  static String notificationDestroyPath(int id) => '/api/notification/$id/destroy';

  static const String tokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';

  // User publish product (sell your car)
  static const String userProductStatsPath = '/api/user/product/stats';
  static const String userProductMyProductsPath = '/api/user/product/my-products';
  static const String userProductCreateDataPath = '/api/user/product/create-data';
  static const String userProductStorePath = '/api/user/product/store';
  static String userProductDeletePath(int id) => '/api/user/product/$id';
}
