import 'package:flutter/material.dart';
import 'theme.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Color(0xFF2F6DCF)),
          onPressed: () {
            Navigator.pop(context); // Navigate back to the previous screen;
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar
            Container(
              decoration: BoxDecoration(
                  color: Color.fromARGB(255, 234, 245, 255),
                  borderRadius: BorderRadius.circular(18.0),
                  border: Border.all(color: Color(0xFF2F6DCF), width: 1.5)),
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                children: [
                  // Hint Text
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.fromLTRB(15, 0, 0, 0),
                        hintText: "Search places",
                        hintStyle: TextStyle(color: Color(0xFF999999)),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  // Vertical Divider
                  Container(
                    height: 24.0, // Height of the divider
                    width: 1.0, // Thickness of the divider
                    color: Color(0xFF999999), // Divider color
                    margin: const EdgeInsets.symmetric(horizontal: 8.0),
                  ),
                  // Filter icon
                  IconButton(
                    icon: Icon(Icons.tune, color: Color(0xFF999999)),
                    onPressed: () {
                      // Add filter functionality here
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Filter buttons
            Center(
              child: Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                alignment: WrapAlignment.center,
                children: [
                  _buildRoundedChip("Parks", Icons.park),
                  _buildRoundedChip("Schools", Icons.school),
                  _buildRoundedChip("Landmarks", Icons.account_balance),
                  _buildRoundedChip(
                      "Shopping Centers", Icons.store_mall_directory),
                  _buildRoundedChip("Cultural Centers", Icons.theater_comedy),
                  _buildRoundedChip("Transit Hubs", Icons.directions_bus),
                  _buildRoundedChip("Plazas", Icons.apartment),
                  _buildRoundedChip("More", Icons.more_horiz),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Map section
            Expanded(
              child: Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    side: BorderSide(color: Color(0xFF2F6DCF), width: 1.5)),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Map View Placeholder",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            // Add map interaction functionality
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                          ),
                          child: Text(
                            "View Map",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildRoundedChip(String label, IconData icon) {
  return Chip(
    label: Text(label, style: TextStyle(color: Color(0xFF999999))),
    avatar: CircleAvatar(
      backgroundColor: Colors.transparent,
      child: Icon(
        icon,
        color: Color(0xFF999999),
      ),
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20.0),
      side: BorderSide(color: Color(0xFF2F6DCF), width: 1.5),
    ),
    backgroundColor: const Color.fromARGB(255, 234, 245, 255),
  );
}
