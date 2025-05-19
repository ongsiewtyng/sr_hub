// lib/screens/library/library_map_screen.dart
import 'package:flutter/material.dart';
import '../../models/seat_model.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/seat_map_widget.dart';
import '../../data/sample_data.dart';

class LibraryMapScreen extends StatefulWidget {
  const LibraryMapScreen({Key? key}) : super(key: key);

  @override
  State<LibraryMapScreen> createState() => _LibraryMapScreenState();
}

class _LibraryMapScreenState extends State<LibraryMapScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedSeatId;
  final floors = SampleData.getFloors();
  final seats = SampleData.getSeats();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: floors.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Library Map',
        bottom: TabBar(
          controller: _tabController,
          tabs: floors.map((floor) => Tab(text: floor.name)).toList(),
        ),
      ),
      body: Column(
        children: [
          // Filter options
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Seat Type',
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    value: 'all',
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('All Types')),
                      DropdownMenuItem(value: 'individual', child: Text('Individual')),
                      DropdownMenuItem(value: 'group', child: Text('Group Study')),
                      DropdownMenuItem(value: 'quiet', child: Text('Quiet Zone')),
                      DropdownMenuItem(value: 'computer', child: Text('Computer')),
                    ],
                    onChanged: (value) {},
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Availability',
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    value: 'available',
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('All Status')),
                      DropdownMenuItem(value: 'available', child: Text('Available')),
                      DropdownMenuItem(value: 'occupied', child: Text('Occupied')),
                      DropdownMenuItem(value: 'reserved', child: Text('Reserved')),
                    ],
                    onChanged: (value) {},
                  ),
                ),
              ],
            ),
          ),

          // Map view
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: floors.map((floor) {
                final floorSeats = seats.where((seat) => seat.floorId == floor.id).toList();

                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Floor map
                      Expanded(
                        child: SeatMapWidget(
                          seats: floorSeats,
                          selectedSeatId: _selectedSeatId,
                          onSeatTap: (seat) {
                            setState(() {
                              _selectedSeatId = seat.id;
                            });
                            _showSeatDetails(seat);
                          },
                          mapWidth: double.infinity,
                          mapHeight: double.infinity,
                          mapImageUrl: floor.mapImageUrl,
                        ),
                      ),

                      // Legend
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildLegendItem(Colors.green.shade100, 'Available'),
                            _buildLegendItem(Colors.red.shade100, 'Occupied'),
                            _buildLegendItem(Colors.orange.shade100, 'Reserved'),
                            _buildLegendItem(Colors.grey.shade300, 'Maintenance'),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.grey.shade300),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  void _showSeatDetails(seat) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: _getSeatTypeColor(seat.type),
                    child: Icon(
                      _getSeatTypeIcon(seat.type),
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        seat.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        seat.typeDisplayName,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getSeatStatusColor(seat.status),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      seat.statusDisplayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Details',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildDetailItem(
                      icon: Icons.location_on,
                      label: 'Location',
                      value: seat.floorName,
                    ),
                  ),
                  Expanded(
                    child: _buildDetailItem(
                      icon: Icons.people,
                      label: 'Capacity',
                      value: '${seat.capacity} ${seat.capacity > 1 ? 'people' : 'person'}',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Amenities',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: seat.amenities.map((amenity) {
                  return Chip(
                    label: Text(_formatAmenity(amenity)),
                    avatar: Icon(
                      _getAmenityIcon(amenity),
                      size: 16,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: seat.isAvailable ? () {} : null,
                  child: const Text('Reserve Seat'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getSeatTypeColor(type) {
    switch (type) {
      case SeatType.individual:
        return Colors.blue;
      case SeatType.group:
        return Colors.green;
      case SeatType.quiet:
        return Colors.purple;
      case SeatType.computer:
        return Colors.orange;
      case SeatType.accessible:
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  IconData _getSeatTypeIcon(type) {
    switch (type) {
      case SeatType.individual:
        return Icons.person;
      case SeatType.group:
        return Icons.people;
      case SeatType.quiet:
        return Icons.volume_off;
      case SeatType.computer:
        return Icons.computer;
      case SeatType.accessible:
        return Icons.accessible;
      default:
        return Icons.chair;
    }
  }

  Color _getSeatStatusColor(status) {
    switch (status) {
      case SeatStatus.available:
        return Colors.green;
      case SeatStatus.occupied:
        return Colors.red;
      case SeatStatus.reserved:
        return Colors.orange;
      case SeatStatus.maintenance:
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey.shade700,
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 12,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatAmenity(String amenity) {
    return amenity.split('_').map((word) => word.substring(0, 1).toUpperCase() + word.substring(1)).join(' ');
  }

  IconData _getAmenityIcon(String amenity) {
    switch (amenity) {
      case 'power_outlet':
        return Icons.power;
      case 'usb_port':
        return Icons.usb;
      case 'whiteboard':
        return Icons.edit;
      case 'projector':
        return Icons.connected_tv;
      case 'desktop_computer':
        return Icons.computer;
      case 'scanner':
        return Icons.scanner;
      default:
        return Icons.check;
    }
  }
}