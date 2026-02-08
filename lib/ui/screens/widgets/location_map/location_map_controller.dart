import 'dart:math';

import 'package:eClassify/app_config.dart';
import 'package:eClassify/data/model/location/leaf_location.dart';
import 'package:eClassify/ui/theme/theme.dart';
import 'package:eClassify/utils/app_session.dart';
import 'package:eClassify/utils/constant.dart';
import 'package:eClassify/utils/location_utility.dart';
import 'package:flutter/widgets.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapData {
  MapData({
    required this.location,
    required this.marker,
    required this.circle,
    required this.cameraPosition,
    required this.radius,
  });

  final LeafLocation location;
  final Marker marker;
  final Circle circle;
  final CameraPosition cameraPosition;
  final double radius;
}

class LocationMapController extends ChangeNotifier {
  LocationMapController({
    this.initialCoordinates,
    this.autoZoom = false,
    LeafLocation? initialLocation,
  }) : _location = initialLocation ?? LeafLocation();

  final LatLng? initialCoordinates;
  final bool autoZoom;

  GoogleMapController? _mapController;
  final LocationUtility _locationUtility = LocationUtility();

  late LeafLocation _location;
  late Marker _marker;
  late Circle _circle;
  late CameraPosition _cameraPosition;
  double _radius = Constant.minRadius;

  double get radius => _radius;

  MapData get data => MapData(
    location: _location.copyWith(radius: _radius),
    marker: _marker,
    circle: _circle,
    cameraPosition: _cameraPosition,
    radius: _radius,
  );

  bool isReady = false;

  static const double _zoom = 12;
  static const String _markerId = 'current_location';
  static const String _circleId = 'current_area';

  Future<String?> error() async {
    return await _mapController?.getStyleError();
  }

  void init() async {
    // This is only used in ad_details_screen and is statically written for that purpose only.
    // If needed to be used elsewhere, then it may require further modification or
    // a streamlined approach.
    if (initialCoordinates != null) {
      isReady = true;
      _radius = 1;
      _updatePosition(initialCoordinates!);
    } else {
      final location = AppSession.currentLocation;

      if (location == null || !location.hasCoordinates) {
        _location =
            await _locationUtility.getLocation() ?? AppConfig.defaultLocation;
      } else {
        _location = location;
      }
      _radius = _location.radius ?? Constant.minRadius;
      isReady = true;
      _updatePosition(
        LatLng(
          _location.latitude ?? AppConfig.defaultLatitude,
          _location.longitude ?? AppConfig.defaultLongitude,
        ),
      );
    }
  }

  void onMapCreated(GoogleMapController? controller) {
    _mapController = controller;

    if (isReady && _mapController != null) {
      if (autoZoom) {
        final radius = max(_radius * 1000, 1000);
        final bounds = _boundsFromCircle(_circle.center, radius.toDouble());
        _mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 10));
      } else {
        _mapController?.animateCamera(CameraUpdate.newLatLng(_circle.center));
      }
    }
  }

  void onTap(LatLng coordinates) async {
    _location = await _locationUtility.getLeafLocationFromLatLng(
      latitude: coordinates.latitude,
      longitude: coordinates.longitude,
    );
    _updatePosition(
      LatLng(
        _location.latitude ?? coordinates.latitude,
        _location.longitude ?? coordinates.longitude,
      ),
    );
  }

  void _updatePosition(LatLng coordinates) async {
    _marker = Marker(
      markerId: MarkerId(_markerId),
      position: coordinates,
      anchor: Offset(.5, .5),
    );
    _circle = Circle(
      circleId: CircleId(_circleId),
      center: coordinates,
      radius: _radius * 1000,
      fillColor: territoryColor_.withValues(alpha: .5),
      strokeWidth: 2,
      strokeColor: territoryColor_,
    );
    _cameraPosition = CameraPosition(target: coordinates, zoom: _zoom);
    if (isReady) {
      if (autoZoom) {
        final bounds = _boundsFromCircle(
          coordinates,
          max(_radius * 1000, 1000),
        );
        _mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 0));
      } else {
        _mapController?.animateCamera(CameraUpdate.newLatLng(coordinates));
      }
    }
    notifyListeners();
  }

  LatLngBounds _boundsFromCircle(LatLng center, double radiusInMeters) {
    // Radius of the Earth in meters (WGS84 standard)
    // Used to convert between meters and geographic degrees
    const double earthRadius = 6378137;

    // Convert center latitude & longitude from degrees to radians
    // Trig functions (cos, sin) only work with radians
    double lat = center.latitude * (pi / 180);
    double lng = center.longitude * (pi / 180);

    // How far north/south (in radians) the radius reaches
    // Latitude lines are evenly spaced, so this is straightforward
    double dLat = radiusInMeters / earthRadius;

    // How far east/west (in radians) the radius reaches
    // Longitude lines get closer together as you move away from the equator,
    // so we adjust using cos(latitude)
    double dLng = radiusInMeters / (earthRadius * cos(lat));

    // Calculate the bounding box in radians
    // This box fully contains the circle
    double minLat = lat - dLat; // southern edge
    double maxLat = lat + dLat; // northern edge
    double minLng = lng - dLng; // western edge
    double maxLng = lng + dLng; // eastern edge

    // Convert radians back to degrees (Google Maps expects degrees)
    // Return the southwest and northeast corners of the bounds
    return LatLngBounds(
      southwest: LatLng(minLat * 180 / pi, minLng * 180 / pi),
      northeast: LatLng(maxLat * 180 / pi, maxLng * 180 / pi),
    );
  }

  Future<void> getLocation({LocationDeniedCallback? onPermissionDenied}) async {
    final location = await _locationUtility.getLocation(
      onPermissionDenied: onPermissionDenied,
    );
    if (location == null) return;
    _location = location;
    _radius = _location.radius != null && _location.radius != 0
        ? _location.radius!
        : _radius;
    _updatePosition(LatLng(_location.latitude!, _location.longitude!));
  }

  void updateRadius(double value) {
    if (value == _radius) return;
    _radius = value;
    final radiusInMeters = _radius * 1000;
    _circle = _circle.copyWith(radiusParam: radiusInMeters);
    final bounds = _boundsFromCircle(_circle.center, max(radiusInMeters, 1000));
    _mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 10));
    notifyListeners();
  }

  void updateLocation(LeafLocation location) {
    if (_location == location) return;
    _location = location;
    if (_location.latitude != null && _location.longitude != null) {
      _updatePosition(LatLng(_location.latitude!, _location.longitude!));
    }
    notifyListeners();
  }
}
