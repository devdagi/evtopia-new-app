import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_provider.dart';
import '../services/service_request_service.dart';

final serviceRequestServiceProvider = Provider<ServiceRequestService>((ref) {
  return ServiceRequestService(ref.watch(apiClientProvider));
});
