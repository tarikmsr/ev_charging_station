import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ev_charging_app/core/models/user.dart';
import 'dart:math';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  // Get user data
  Future<Map<String, dynamic>?> getUserData(String userId) async {
    try {
      final docSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .get();
      return docSnapshot.data();
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  // Update user data
  Future<void> updateUserData(Map<String, dynamic> data) async {
    if (currentUserId == null) throw 'user id not found in updateUserData';

    try {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .set(data, SetOptions(merge: true));
    } catch (e) {
      print('Error updating user data: $e');
      rethrow;
    }
  }

// Get favorite station IDs
  Future<List<String>> getFavoriteStationIds() async {
    if (currentUserId == null) throw 'User ID not found in getFavoriteStationIds';

    try {
      final snapshot = await _firestore.collection('users').doc(currentUserId).get();

      // Ensure data exists and contains the favoriteStations field
      final data = snapshot.data();
      if (data == null || !data.containsKey('favoriteStations')) return [];

      // Safely cast the list from Firestore
      return List<String>.from(data['favoriteStations'] ?? []);
    } catch (e) {
      print('Error getting favorite stations: $e');
      return [];
    }
  }

  // Add to favorites
  Future<void> addToFavorites(String stationId) async {
    if (currentUserId == null) throw 'user id not found in getFavoriteStationIds';

    try {
      await _firestore
          .collection('users')
          .doc(currentUserId).update(
        {
          'favoriteStations': FieldValue.arrayUnion([stationId]), // Append to list
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );
    } catch (e) {
      print('Error adding to favorites: $e');
      rethrow;
    }
  }

// Remove from favorites
  Future<void> removeFromFavorites(String stationId) async {
    if (currentUserId == null) return;

    try {
      await _firestore.collection('users').doc(currentUserId).update({
        'favoriteStations': FieldValue.arrayRemove([stationId]), // Remove from list
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error removing from favorites: $e');
      rethrow;
    }
  }

// Check if station is favorite
  Future<bool> isFavoriteStation(String stationId) async {
    if (currentUserId == null) return false;

    try {
      final docSnapshot = await _firestore.collection('users').doc(currentUserId).get();

      if (!docSnapshot.exists) return false;

      final data = docSnapshot.data();
      if (data == null || !data.containsKey('favoriteStations')) return false;

      final List<dynamic> favoriteStations = data['favoriteStations'];
      return favoriteStations.contains(stationId);
    } catch (e) {
      print('Error checking favorite status: $e');
      return false;
    }
  }


  // Initialize user data
  Future<void> initializeUserData({
    required String userId,
    required String email,
    String? firstName,
    String? lastName,
  }) async {
    try {
      final userDoc = _firestore.collection('users').doc(userId);
      final userSnapshot = await userDoc.get();

      if (!userSnapshot.exists) {
        await userDoc.set({
          'email': email,
          'firstName': firstName,
          'lastName': lastName,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error initializing user data: $e');
      throw 'Failed to initialize user data';
    }
  }

  // Get station details
  Future<Map<String, dynamic>?> getStationDetails(String id) async {
    try {
      final docSnapshot = await _firestore.collection('stations').doc(id).get();
      return docSnapshot.data();
    } catch (e) {
      print('Error getting station details: $e');
      return null;
    }
  }

  // Initialize demo stations
  Future<void> initializeDemoStations() async {
    try {
      final batch = _firestore.batch();
      final stationsRef = _firestore.collection('stations');

      // Demo station data
      final demoStations = [
        {
          'name': 'UIR Charging Station',
          'address': 'Université Internationale de Rabat',
          'latitude': 33.981535,
          'longitude': -6.716713,
          'available': true,
          'power': 50,
          'pricePerKwh': 2.5,
          'connectorTypes': ['Type 2', 'CCS'],
          'isDemoStation': true,
        },
        {
          'name': 'Hay Riad Station',
          'address': 'Hay Riad, Rabat',
          'latitude': 33.969774,
          'longitude': -6.728664,
          'available': true,
          'power': 150,
          'pricePerKwh': 3.0,
          'connectorTypes': ['Type 2', 'CHAdeMO', 'CCS'],
          'isDemoStation': true,
        },
        // Add more demo stations as needed
      ];

      // Add each demo station to the batch
      for (final station in demoStations) {
        final docRef = stationsRef.doc();
        batch.set(docRef, {
          ...station,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // Commit the batch
      await batch.commit();
      print('Demo stations initialized successfully');
    } catch (e) {
      print('Error initializing demo stations: $e');
      throw 'Failed to initialize demo stations';
    }
  }

  // Get nearby stations within a radius (in kilometers)
  Future<List<Map<String, dynamic>>> getNearbyStations(
    double latitude,
    double longitude, {
    double radius = 10,
  }) async {
    try {
      // Convert radius from km to degrees (approximate)
      final double latDegree = radius / 111.0; // 1 degree ≈ 111km
      final double lonDegree = radius / (111.0 * cos(latitude * pi / 180.0));

      final snapshot = await _firestore
          .collection('stations')
          .where('latitude', isGreaterThanOrEqualTo: latitude - latDegree)
          .where('latitude', isLessThanOrEqualTo: latitude + latDegree)
          .get();

      // Filter stations within longitude range and calculate actual distance
      final stations = snapshot.docs.where((doc) {
        final stationData = doc.data();
        final stationLat = stationData['latitude'] as double;
        final stationLon = stationData['longitude'] as double;

        // Check longitude range
        if (stationLon < longitude - lonDegree || stationLon > longitude + lonDegree) {
          return false;
        }

        // Calculate actual distance using Haversine formula
        final distance = _calculateDistance(
          latitude,
          longitude,
          stationLat,
          stationLon,
        );

        return distance <= radius;
      }).map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      return stations;
    } catch (e) {
      print('Error getting nearby stations: $e');
      return [];
    }
  }

  // Calculate distance between two points using Haversine formula
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371; // Earth's radius in kilometers

    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);

    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double degree) {
    return degree * pi / 180;
  }
}
