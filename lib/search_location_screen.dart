import 'package:flutter/material.dart';
import 'theme.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  bool isSearching =
      false; // Track whether the user is typing in the search bar

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
      body: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Bar
              Center(
                child: Container(
                  width: MediaQuery.of(context).size.width - 32,
                  decoration: BoxDecoration(
                      color: Color.fromARGB(255, 234, 245, 255),
                      borderRadius: BorderRadius.circular(18.0),
                      border: Border.all(color: Color(0xFF2F6DCF), width: 1.5)),
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    children: [
                      // Hint Text
                      Flexible(
                        child: TextField(
                          onTap: () {
                            // Change state when search bar is tapped
                            setState(() {
                              isSearching = true; // Activate dropdown
                            });
                          },
                          decoration: InputDecoration(
                            contentPadding: EdgeInsets.fromLTRB(15, 0, 0, 0),
                            hintText: "Search places",
                            hintStyle: TextStyle(color: Color(0xFF999999)),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      if (!isSearching) ...[
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
                      if (isSearching) ...[
                        // Cancel button for when search bar has been tapped
                        IconButton(
                          icon: Icon(Icons.cancel_outlined, color: Colors.grey),
                          onPressed: () {
                            setState(() {
                              isSearching = false; // Deactivate dropdown
                            });
                          },
                        ),
                      ]
                    ],
                  ),
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
          if (isSearching) ...[
            const SizedBox(height: 16),

            // Search results dropdown
            Positioned(
                top: 60,
                left: 16,
                right: 16,
                child: Material(
                  elevation: 4.0, // Adds shadow for "hovering" effect
                  borderRadius: BorderRadius.circular(12.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Color.fromARGB(255, 234, 245,
                          255), // Background color for search results
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: 5,
                      separatorBuilder: (context, index) => Divider(
                        color: Color(0xFF2F6DCF), // Divider color
                        height: 5.0, // Space around the divider
                      ),
                      itemBuilder: (context, index) {
                        // Build each search result
                        return ListTile(
                            leading: Icon(
                              Icons.search,
                              color: Color(0xFF2F6DCF),
                            ),
                            title: Text("Recent Search ${index + 1}",
                                style: TextStyle(color: Color(0xFF2F6DCF))),
                            onTap: () {
                              // Handle recent search tap
                            });
                      },
                    ),
                  ),
                )),
          ]
        ],
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
