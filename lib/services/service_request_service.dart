import 'package:dio/dio.dart';

import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';

/// Service request payload matching evtopia-ecom ServiceRequestController store().
class ServiceRequestPayload {
  const ServiceRequestPayload({
    required this.name,
    required this.phone,
    required this.carModel,
    required this.requestedDate,
    required this.requestedTime,
    this.description,
    this.serviceId,
  });

  final String name;
  final String phone;
  final String carModel;
  final String requestedDate; // YYYY-MM-DD
  final String requestedTime;
  final String? description;
  final int? serviceId;

  Map<String, dynamic> toJson() => {
        'name': name,
        'phone': phone,
        'car_model': carModel,
        'requested_date': requestedDate,
        'requested_time': requestedTime,
        if (description != null && description!.isNotEmpty) 'description': description,
        if (serviceId != null) 'service_id': serviceId,
      };
}

/// Response from POST /api/service-requests (auth required).
class ServiceRequestResponse {
  const ServiceRequestResponse({
    required this.success,
    this.message,
  });

  final bool success;
  final String? message;

  factory ServiceRequestResponse.fromJson(Map<String, dynamic> json) {
    return ServiceRequestResponse(
      success: json['success'] == true,
      message: json['message']?.toString(),
    );
  }
}

/// Calls evtopia-ecom POST /api/service-requests (requires auth).
class ServiceRequestService {
  ServiceRequestService(this._api);

  final ApiClient _api;

  /// Submit a service request. Requires authenticated user (Bearer token).
  Future<ServiceRequestResponse?> submitRequest(ServiceRequestPayload payload) async {
    try {
      final response = await _api.dio.post<Map<String, dynamic>>(
        ApiConstants.serviceRequestsPath,
        data: payload.toJson(),
      );
      if (response.statusCode != 200 && response.statusCode != 201) return null;
      final data = response.data;
      if (data == null) return null;
      return ServiceRequestResponse.fromJson(data);
    } on DioException {
      rethrow;
    }
  }
}
