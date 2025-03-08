import 'package:ev_charging_app/core/services/firestore_service.dart';

import '../models/station.dart';

class StationService {
  final FirestoreService _firestoreService;

  StationService({FirestoreService? firestoreService}) 
      : _firestoreService = firestoreService ?? FirestoreService();

  // Add station to favorites
  Future<void> addToFavorites(String stationId) async {
    try {
      await _firestoreService.addToFavorites(stationId);
    } catch (e) {
      print('Error in StationService.addToFavorites: $e');
      rethrow;
    }
  }

  // Remove station from favorites
  Future<void> removeFromFavorites(String stationId) async {
    try {
      await _firestoreService.removeFromFavorites(stationId);
    } catch (e) {
      print('Error in StationService.removeFromFavorites: $e');
      rethrow;
    }
  }

  // Check if station is in favorites
  Future<bool> isFavorite(String stationId) async {
    try {
      return await _firestoreService.isFavoriteStation(stationId);
    } catch (e) {
      print('Error in StationService.isFavorite: $e');
      return false;
    }
  }

  // Get all favorite station IDs
  Future<List<String>> getFavoriteStationIds() async {
    try {
      var list = await _firestoreService.getFavoriteStationIds();
      return list;
    } catch (e) {
      print('Error in StationService.getFavoriteStationIds: $e');
      return [];
    }
  }

  // Get station details by ID
  Future<Map<String, dynamic>?> getStationDetails(String id) async {
    try {
      var stationJson =  await _firestoreService.getStationDetails(id);
      print('list getStationDetails: $stationJson');
      return stationJson;
    } catch (e) {
      print('Error in StationService.getStationDetails: $e');
      return null;
    }
  }

  // Get nearby stations within a radius
  Future<List<Station>> getNearbyStations(double latitude, double longitude, {double radius = 10}) async {
    try {
      final snapshot = await _firestoreService.getNearbyStations(latitude, longitude, radius: radius);
      return snapshot.map((data) => Station.fromJson(data['id'] as String, data)).toList();
    } catch (e) {
      print('Error in StationService.getNearbyStations: $e');
      return [];
    }
  }

}
