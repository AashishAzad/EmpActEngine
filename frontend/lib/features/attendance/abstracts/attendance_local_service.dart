import '../models/location_snapshot.dart';

abstract class AttendanceLocationService {
  Future<bool> hasPermission();
  Future<bool> isServiceEnabled();
  Future<LocationSnapshot> getCurrentLocation();
}
