import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:sr_hub/core/theme/app_theme.dart';
import 'package:sr_hub/features/library_reservation/presentation/widgets/seat_availability_legend.dart';
import 'package:sr_hub/features/library_reservation/presentation/widgets/floor_selector.dart';

class LibraryMapScreen extends StatefulWidget {
  const LibraryMapScreen({super.key});

  @override
  State<LibraryMapScreen> createState() => _LibraryMapScreenState();
}

class _LibraryMapScreenState extends State<LibraryMapScreen> {
  int _selectedFloor = 1;
  final MapController _mapController = MapController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Library Map'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () {
              // TODO: Navigate to reservations screen
            },
          ),
        ],
      ),
      body: Column(
        children: [
          FloorSelector(
            selectedFloor: _selectedFloor,
            onFloorSelected: (floor) {
              setState(() {
                _selectedFloor = floor;
              });
            },
          ),
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    center: const LatLng(0, 0), // TODO: Set actual library coordinates
                    zoom: 18.0,
                    onTap: (_, point) {
                      // TODO: Handle seat selection
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.sr_hub',
                    ),
                    MarkerLayer(
                      markers: [
                        // TODO: Add seat markers based on availability
                      ],
                    ),
                  ],
                ),
                const Positioned(
                  bottom: 16,
                  right: 16,
                  child: SeatAvailabilityLegend(),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Implement zoom to user's location
        },
        child: const Icon(Icons.my_location),
      ),
    );
  }
} 