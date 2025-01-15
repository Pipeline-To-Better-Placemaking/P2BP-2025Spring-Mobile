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
  bool hasSearched = false; // Track whether the user has already hit Enter
  String searchText = "Search places"; // Default hint text
  double searchBarWidth = 0.0; // Search bar width (initialized dynamically)

  @override
  Widget build(BuildContext context) {
    searchBarWidth =
        hasSearched ? 200.0 : MediaQuery.of(context).size.width - 32;
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
            Row(
              mainAxisAlignment: hasSearched
                  ? MainAxisAlignment.start
                  : MainAxisAlignment.center, // Adjust alignment
              children: [
                AnimatedContainer(
                  duration:
                      const Duration(milliseconds: 300), // Animation speed
                  curve: Curves.easeInOut, // Animation curve
                  width: searchBarWidth, // Dynamic width
                  decoration: BoxDecoration(
                      color: Color.fromARGB(255, 234, 245, 255),
                      borderRadius: BorderRadius.circular(18.0),
                      border: Border.all(color: Color(0xFF2F6DCF), width: 1.5)),

                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: hasSearched
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              searchText, // Display the search term
                              style: TextStyle(color: Colors.black),
                            ),
                            IconButton(
                              icon: Icon(Icons.clear, color: Colors.grey),
                              onPressed: () {
                                setState(() {
                                  hasSearched = false; // Reset to default state
                                  isSearching = false;
                                  searchText = "";
                                });
                              },
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            const SizedBox(width: 8.0),
                            Expanded(
                              child: TextField(
                                onSubmitted: (value) {
                                  // Change state when search bar is tapped
                                  setState(() {
                                    hasSearched = true;
                                    searchText =
                                        value.isNotEmpty ? value : "Search";
                                  });
                                },
                                onTap: () {
                                  setState(() {
                                    isSearching = true;
                                  });
                                },
                                decoration: InputDecoration(
                                  contentPadding:
                                      EdgeInsets.fromLTRB(15, 0, 0, 0),
                                  hintText: "Search places",
                                  hintStyle:
                                      TextStyle(color: Color(0xFF999999)),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                            // Vertical Divider
                            Container(
                              height: 24.0, // Height of the divider
                              width: 1.0, // Thickness of the divider
                              color: Color(0xFF999999), // Divider color
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 8.0),
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
                if (hasSearched)
                  const SizedBox(
                      width: 8), // Space between search bar and filter button
                if (hasSearched)
                  //Filter Button
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        // Handle filter action
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color.fromARGB(
                            255, 234, 245, 255), // Background color
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15.0),
                          side:
                              BorderSide(color: Color(0xFF2F6DCF), width: 1.5),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                      ),
                      child: Icon(Icons.tune, color: Color(0xFF999999)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (!hasSearched)
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

  Widget _buildRoundedChip(String label, IconData icon) {
    return GestureDetector(
      onTap: () {
        setState(() {
          searchText = label;
          hasSearched = true; // Update hint text when chip is tapped
        });
      },
      child: Chip(
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
      ),
    );
  }
}


//  // Hint Text
//                       Flexible(
//                         child: 
//                       if (isSearching) ...[
//                         // Cancel button for when search bar has been tapped
//                         IconButton(
//                           icon: Icon(Icons.cancel_outlined, color: Colors.grey),
//                           onPressed: () {
//                             setState(() {
//                               isSearching = false; // Deactivate dropdown
//                               hintText = "Search places"; // Reset hint text
//                             });
//                           },
//                         ),
//                       ],
//                       // Filter buttons
//                       if (hasSearched) ...[
//                         IconButton(
//                             icon:
//                                 Icon(Icons.cancel_outlined, color: Colors.grey),
//                             onPressed: () {
//                               setState(() {
//                                 hasSearched = false;
//                                 hintText = "Search places";
//                               });
//                             })
//                       ],
//                     ],
//                   ),
//                 ),
//               ],
//               )
              


  //           const SizedBox(height: 16),

  //           if(!hasSearched)
  //           Center(

  //           )

  //           // Search results dropdown
  //           Positioned(
  //               top: 60,
  //               left: 16,
  //               right: 16,
  //               child: Material(
  //                 elevation: 4.0, // Adds shadow for "hovering" effect
  //                 borderRadius: BorderRadius.circular(12.0),
  //                 child: Container(
  //                   decoration: BoxDecoration(
  //                     color: Color.fromARGB(255, 234, 245,
  //                         255), // Background color for search results
  //                     borderRadius: BorderRadius.circular(12.0),
  //                   ),
  //                   child: ListView.separated(
  //                     shrinkWrap: true,
  //                     itemCount: 5,
  //                     separatorBuilder: (context, index) => Divider(
  //                       color: Color(0xFF2F6DCF), // Divider color
  //                       height: 5.0, // Space around the divider
  //                     ),
  //                     itemBuilder: (context, index) {
  //                       // Build each search result
  //                       return ListTile(
  //                           leading: Icon(
  //                             Icons.search,
  //                             color: Color(0xFF2F6DCF),
  //                           ),
  //                           title: Text("Recent Search ${index + 1}",
  //                               style: TextStyle(color: Color(0xFF2F6DCF))),
  //                           onTap: () {
  //                             // Handle recent search tap
  //                           });
  //                     },
  //                   ),
  //                 ),
  //               )),
          
  //       ],
  //     ),
  //   );
  // }