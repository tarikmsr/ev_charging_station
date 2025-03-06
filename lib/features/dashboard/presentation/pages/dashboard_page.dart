import 'package:flutter/material.dart';
import 'package:ev_charging_app/core/models/notification.dart';
import 'package:ev_charging_app/core/services/notification_service.dart';
import 'package:ev_charging_app/core/services/station_service.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ev_charging_app/features/profile/presentation/pages/profile_page.dart';
import 'package:ev_charging_app/features/charging_stations/presentation/pages/favorite_stations_page.dart';
import 'package:ev_charging_app/features/charging_stations/presentation/pages/qr_scanner_page.dart';
import 'package:ev_charging_app/core/models/station.dart';

import '../../../../core/app_assets/app_assets.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _notificationService = NotificationService();
  final _stationService = StationService();
  final _searchController = TextEditingController();
  late List<EVNotification> _notifications;
  bool _showNotifications = false;
  int _currentIndex = 0;
  late GoogleMapController _mapController;
  final Set<Marker> _markers = {};
  Position? _currentPosition;
  List<Station> _nearbyStations = [];
  bool _isSearching = false;

  // Initial camera position (you can set this to user's location)
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(33.984290063570626, -6.727111828376072), // Rabat UIR coordinates
    zoom: 14.0,
  );

  @override
  void initState() {
    super.initState();
    _notifications = _notificationService.getDemoNotifications();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      setState(() => _currentPosition = position);
      _searchNearbyStations();
    } catch (e) {
      print('Error getting current location: $e');
    }
  }

  Future<void> _searchNearbyStations() async {
    if (_currentPosition == null) return;

    setState(() => _isSearching = true);
    try {
      final stations = await _stationService.getNearbyStations(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        radius: 10, // 10km radius
      );

      setState(() {
        _nearbyStations = stations;
        _updateMarkers();
      });
    } catch (e) {
      print('Error searching nearby stations: $e');
    } finally {
      setState(() => _isSearching = false);
    }
  }

  void _updateMarkers() {
    _markers.clear();
    
    // Add station markers
    for (final station in _nearbyStations) {
      _markers.add(
        Marker(
          markerId: MarkerId(station.id),
          position: LatLng(station.latitude, station.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            station.available ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueRed,
          ),
          infoWindow: InfoWindow(
            title: station.name,
            snippet: '${station.power}kW • ${station.pricePerKwh}MAD/kWh',
          ),
        ),
      );
    }

    // Add current location marker
    if (_currentPosition != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: LatLng(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(title: 'Your Location'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () {
                  setState(() {
                    _showNotifications = !_showNotifications;
                  });
                },
              ),
              if (_notificationService.getUnreadCount() > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${_notificationService.getUnreadCount()}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: [
              Column(
                children: [
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Theme.of(context).primaryColor,
                          Theme.of(context).primaryColor.withOpacity(0.8),
                        ],
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Image.asset(
                            AppAssets.evCharging,
                            fit: BoxFit.contain,
                            opacity: const AlwaysStoppedAnimation(0.3),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Welcome Back!',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Find the nearest charging station for your EV',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 16),

                              Row(
                                children: [
                                  _buildStatCard(
                                    'Battery Level',
                                    '75%',
                                    Icons.battery_charging_full,
                                  ),
                                  const SizedBox(width: 16),
                                  _buildStatCard(
                                    'Range',
                                    '150 km',
                                    Icons.speed,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Stack(
                      children: [
                        GoogleMap(
                          initialCameraPosition: _initialPosition,
                          onMapCreated: (controller) => _mapController = controller,
                          markers: _markers,
                          myLocationEnabled: true,
                          myLocationButtonEnabled: true,
                        ),
                        if (_isSearching)
                          const Center(
                            child: Card(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: CircularProgressIndicator(),
                              ),
                            ),
                          ),

                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Search nearby stations...',
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: _isSearching
                                  ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                                  : IconButton(
                                icon: const Icon(Icons.my_location),
                                onPressed: _searchNearbyStations,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            onSubmitted: (_) => _searchNearbyStations(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const FavoriteStationsPage(),
              const ProfilePage(),
            ],
          ),
          if (_showNotifications)
            Positioned(
              top: 0,
              right: 0,
              child: Card(
                margin: const EdgeInsets.only(top: 8, right: 8),
                elevation: 8,
                child: Container(
                  width: 300,
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.6,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.grey.withOpacity(0.2),
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Notifications',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                // Mark all as read
                              },
                              child: const Text('Mark all as read'),
                            ),
                          ],
                        ),
                      ),
                      Flexible(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: _notifications.length,
                          itemBuilder: (context, index) {
                            final notification = _notifications[index];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _getNotificationColor(notification.type),
                                child: Icon(
                                  _getNotificationIcon(notification.type),
                                  color: Colors.white,
                                ),
                              ),
                              title: Text(
                                notification.title,
                                style: TextStyle(
                                  fontWeight: notification.isRead
                                      ? FontWeight.normal
                                      : FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(notification.message),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatTimestamp(notification.timestamp),
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              tileColor: notification.isRead
                                  ? null
                                  : Colors.blue.withOpacity(0.1),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const QRScannerPage()),
          );
        },
        child: const Icon(Icons.qr_code_scanner),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Favorites',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'warning':
        return Colors.orange;
      case 'success':
        return Colors.green;
      case 'info':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'warning':
        return Icons.warning;
      case 'success':
        return Icons.check_circle;
      case 'info':
        return Icons.info;
      default:
        return Icons.notifications;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
