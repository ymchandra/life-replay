import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:iconsax/iconsax.dart';

class LocationPickerDialog extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;

  const LocationPickerDialog({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
  });

  @override
  State<LocationPickerDialog> createState() => _LocationPickerDialogState();
}

class _LocationPickerDialogState extends State<LocationPickerDialog> {
  late GoogleMapController mapController;
  LatLng? selectedLocation;
  Set<Marker> markers = {};

  @override
  void initState() {
    super.initState();
    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      selectedLocation = LatLng(widget.initialLatitude!, widget.initialLongitude!);
      markers.add(
        Marker(
          markerId: const MarkerId('selected'),
          position: selectedLocation!,
        ),
      );
    }
  }

  void _onMapTap(LatLng location) {
    setState(() {
      selectedLocation = location;
      markers.clear();
      markers.add(
        Marker(
          markerId: const MarkerId('selected'),
          position: location,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final initialPosition = selectedLocation ??
        const LatLng(37.7749, -122.4194); // Default to San Francisco

    return Dialog(
      child: Column(
        children: [
          AppBar(
            title: const Text('Select Location'),
            leading: IconButton(
              icon: const Icon(Iconsax.close_circle),
              onPressed: () => Navigator.pop(context),
            ),
            elevation: 0,
          ),
          Expanded(
            child: GoogleMap(
              onMapCreated: (controller) {
                mapController = controller;
              },
              initialCameraPosition: CameraPosition(
                target: initialPosition,
                zoom: 15,
              ),
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              onTap: _onMapTap,
              markers: markers,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Iconsax.close_circle),
                  label: const Text('Cancel'),
                  onPressed: () => Navigator.pop(context),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Iconsax.tick_circle),
                  label: const Text('Select'),
                  onPressed: selectedLocation != null
                      ? () {
                          Navigator.pop(context, selectedLocation);
                        }
                      : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

