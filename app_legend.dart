import "package:flutter/material.dart";

import "models/models.dart";

class AppLegend extends StatelessWidget {
  const AppLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xfffe9923),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            const Expanded(
              child: Scrollbar(
                thumbVisibility: true,
                trackVisibility: true,
                child: SingleChildScrollView(
                  physics: BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      SquareTile(
                          imagePath: 'lib/assets/map_buildings.png',
                          label: 'Buildings'),
                      SquareTile(
                          imagePath: 'lib/assets/map_rural_area.png',
                          label: 'Rural areas'),
                      SquareTile(
                          imagePath: 'lib/assets/map_roads.png',
                          label: 'Road paths'),
                      SquareTile(
                          imagePath: 'lib/assets/water_bay.png',
                          label: 'Bodies of water'),
                      SquareTile(
                          imagePath: 'lib/assets/location_accuracy_circle.png',
                          label: 'Location accuracy proximation'),
                      SquareTile(
                          imagePath: 'lib/assets/geofence_circle.png',
                          label: 'Geofence Area'),
                      SquareTile(
                          imagePath: 'lib/assets/location_trail.png',
                          label: 'Friend trails'),
                      SquareTile(
                          imagePath: 'lib/assets/my_location.png',
                          label: 'Find your location'),
                      SquareTile(
                          imagePath: 'lib/assets/add_friend.png',
                          label: 'Add friend'),
                      SquareTile(
                          imagePath: 'lib/assets/set_geofence.png',
                          label: 'Set friend\'s geofence'),
                      SquareTile(
                          imagePath: 'lib/assets/friend_visibilty.png',
                          label: 'Hide/Unhide friend on Map view'),
                      SquareTile(
                          imagePath: 'lib/assets/import_image.png',
                          label: 'Import QR image'),
                      SquareTile(
                          imagePath: 'lib/assets/cancel_action.png',
                          label: 'Cancel action'),
                      SquareTile(
                          imagePath: 'lib/assets/add_image.png',
                          label: 'Change profile picture'),
                    ],
                  ),
                ),
              ),
            ),
            ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff6054a4),
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
                child:
                    const Text('Close', style: TextStyle(color: Colors.white))),
          ],
        ),
      ),
    );
  }
}
