import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:life_replay/core/services/location_service.dart';

class LocationData {
  final double latitude;
  final double longitude;
  final String? locationName;
  final bool isLoading;
  final String? error;

  LocationData({
    required this.latitude,
    required this.longitude,
    this.locationName,
    this.isLoading = false,
    this.error,
  });

  LocationData copyWith({
    double? latitude,
    double? longitude,
    String? locationName,
    bool? isLoading,
    String? error,
  }) {
    return LocationData(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationName: locationName ?? this.locationName,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class LocationNotifier extends StateNotifier<LocationData?> {
  LocationNotifier() : super(null);

  Future<void> captureCurrentLocation() async {
    try {
      state = state?.copyWith(isLoading: true) ?? LocationData(
        latitude: 0,
        longitude: 0,
        isLoading: true,
      );

      final position = await LocationService.getCurrentLocation();
      if (position != null) {
        final locationName =
            await LocationService.getLocationName(position.latitude, position.longitude);
        state = LocationData(
          latitude: position.latitude,
          longitude: position.longitude,
          locationName: locationName,
          isLoading: false,
        );
      } else {
        state = state?.copyWith(
          isLoading: false,
          error: 'Unable to get location. Check permissions and try again.',
        );
      }
    } catch (e) {
      state = state?.copyWith(
        isLoading: false,
        error: 'Error capturing location: ${e.toString()}',
      );
    }
  }

  Future<void> setLocation(double latitude, double longitude) async {
    try {
      state = LocationData(
        latitude: latitude,
        longitude: longitude,
        isLoading: true,
      );

      final locationName = await LocationService.getLocationName(latitude, longitude);
      state = LocationData(
        latitude: latitude,
        longitude: longitude,
        locationName: locationName,
        isLoading: false,
      );
    } catch (e) {
      state = LocationData(
        latitude: latitude,
        longitude: longitude,
        isLoading: false,
        error: 'Error resolving location name: ${e.toString()}',
      );
    }
  }

  void clearLocation() {
    state = null;
  }

  Future<LocationPermission> checkAndRequestPermission() async {
    final permission = await LocationService.checkPermission();
    if (permission == LocationPermission.denied) {
      return await LocationService.requestPermission();
    }
    return permission;
  }
}

final locationProvider = StateNotifierProvider<LocationNotifier, LocationData?>(
  (ref) => LocationNotifier(),
);

