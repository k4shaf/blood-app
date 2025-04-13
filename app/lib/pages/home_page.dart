import 'package:app/core/enums/app_routes.dart';
import 'package:app/core/storage/secure_storage.dart';
import 'package:app/services/auth_services.dart';
import 'package:app/services/listing_service.dart';
import 'package:app/widgets/create_request_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class HomePage extends StatelessWidget {
  final _storage = GetIt.instance.get<SecureStorage>();

  HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        toolbarHeight: 70,
        backgroundColor: Colors.red[600],
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "DonorX",
              style: GoogleFonts.dmSans(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            FutureBuilder<User?>(
              future: _storage.getUser(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Text(
                    "Loading...",
                    style: GoogleFonts.dmSans(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                }
                if (!snapshot.hasData || snapshot.data == null) {
                  return Text(
                    "Guest",
                    style: GoogleFonts.dmSans(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                }
                return Text(
                  snapshot.data!.username,
                  style: GoogleFonts.dmSans(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                );
              },
            ),
          ],
        ),
      ),

      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            HomeHeader(),
            Banner(),

            // Quick Actions Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Quick Actions",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child:
                            FindDonorsButton(screenWidth: screenWidth / 2 - 24),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: CreateRequestButton(
                            screenWidth: screenWidth / 2 - 24),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Emergency Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: EmergencyRequestCard(),
            ),

            // My Requests Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "My Blood Requests",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          // Navigate to all requests
                          context.push('/user-listings');
                        },
                        child: Text(
                          "View All",
                          style: TextStyle(
                            color: Colors.red[600],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  MyRequestsList(),
                ],
              ),
            ),

            StatsBar(),
            const SizedBox(height: 12),

            // Nearby Donors Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Nearby Donors",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 12),
                  // NearbyDonorsMap(),
                ],
              ),
            ),

            SizedBox(height: 60), // Space for FAB
          ],
        ),
      ),

      // FLOATING BUTTON
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.red,
        onPressed: () {
          // Show dialog to create new request with proper handling
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return CreateRequestDialog(
                onRequestCreated: (dynamic result) {
                  // Handle the result of creating a request
                  if (result is Map &&
                      result['action'] == 'navigate_to_listings') {
                    Navigator.of(context).pop();
                    context.push('/user-listings');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content:
                            Text("Please manage your existing listings first"),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
              );
            },
          );
        },
        shape: CircleBorder(),
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.miniCenterDocked,

      // BOTTOM BAR
      bottomNavigationBar: BottomAppBar(
        color: Colors.grey[300],
        shape: CircularNotchedRectangle(),
        child: IconTheme(
          data: IconThemeData(color: Colors.black),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                tooltip: 'Profile',
                icon: const Icon(Icons.person),
                onPressed: () {
                  context.push(AppRoutes.profile.path);
                },
              ),
              IconButton(
                tooltip: 'Settings',
                icon: const Icon(Icons.settings),
                onPressed: () {
                  context.push(AppRoutes.settings.path);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Existing buttons
class FindDonorsButton extends StatelessWidget {
  const FindDonorsButton({super.key, required this.screenWidth});

  final double screenWidth;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        minimumSize: Size(screenWidth, 50),
        backgroundColor: Colors.red[600],
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: Colors.black, width: 0.1),
          borderRadius: BorderRadius.circular(12.0),
        ),
      ),
      onPressed: () {
        context.push(AppRoutes.donors.path);
      },
      icon: Icon(Icons.search),
      label: const Text(
        "Find Donors",
        style: TextStyle(fontSize: 16),
      ),
    );
  }
}

// New button for creating blood requests
class CreateRequestButton extends StatelessWidget {
  const CreateRequestButton({super.key, required this.screenWidth});

  final double screenWidth;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        minimumSize: Size(screenWidth, 50),
        backgroundColor: Colors.white,
        foregroundColor: Colors.red[600],
        side: BorderSide(color: Colors.red.shade600, width: 1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
      ),
      onPressed: () {
        // Navigate to create request page or show dialog
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return CreateRequestDialog(
              onRequestCreated: (dynamic result) {
                // Handle the result same as in UserListingsPage
                if (result is Map &&
                    result['action'] == 'navigate_to_listings') {
                  Navigator.of(context).pop();
                  context.push('/user-listings');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                          Text("Please manage your existing listings first"),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
            );
          },
        );
      },
      icon: Icon(Icons.add_circle_outline),
      label: const Text(
        "New Request",
        style: TextStyle(fontSize: 16),
      ),
    );
  }
}

// Emergency Request Card
class EmergencyRequestCard extends StatelessWidget {
  const EmergencyRequestCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.red.shade200, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.emergency, color: Colors.red, size: 24),
                SizedBox(width: 8),
                Text(
                  "Emergency Request",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[800],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              "Need blood urgently? Create an emergency request that will be prioritized and shown to nearby donors immediately.",
              style: TextStyle(fontSize: 14, color: Colors.black87),
            ),
            SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                // Show dialog with emergency checkbox checked
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return CreateRequestDialog(
                      isEmergencyChecked: true, // Pre-check emergency option
                      onRequestCreated: (dynamic result) {
                        // Handle the result same as in UserListingsPage
                        if (result is Map &&
                            result['action'] == 'navigate_to_listings') {
                          Navigator.of(context).pop();
                          context.push('/user-listings');
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  "Please manage your existing listings first"),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                    );
                  },
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[800],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text("Create Emergency Request"),
            ),
          ],
        ),
      ),
    );
  }
}

// Update MyRequestsList to fetch and display actual data with priority sorting
class MyRequestsList extends StatelessWidget {
  const MyRequestsList({super.key});

  @override
  Widget build(BuildContext context) {
    final listingService = ListingService();
    final _storage = GetIt.instance.get<SecureStorage>();

    return FutureBuilder<User?>(
      future: _storage.getUser(),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!userSnapshot.hasData || userSnapshot.data == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                "Please log in to view your requests",
                style: TextStyle(color: Colors.grey),
              ),
            ),
          );
        }

        return FutureBuilder<List<Listing>>(
          // For testing use getDummyListings instead of actual API
          // future: listingService.getDummyListings(),
          future: listingService.getListings(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  "Error: ${snapshot.error}",
                  style: TextStyle(color: Colors.red),
                ),
              );
            }

            final listings = snapshot.data ?? [];

            if (listings.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    "You haven't created any requests yet",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              );
            }

            // Sort listings by priority (emergency first)
            final sortedListings = [...listings]..sort((a, b) {
                // Emergency requests first
                if (a.isEmergency && !b.isEmergency) return -1;
                if (!a.isEmergency && b.isEmergency) return 1;
                // Then sort by creation date (newest first)
                return b.createdAt.compareTo(a.createdAt);
              });

            return ListView.builder(
              physics: NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: sortedListings.length > 2
                  ? 2
                  : sortedListings.length, // Show only 2 items in home
              itemBuilder: (context, index) {
                final listing = sortedListings[index];
                final bool isEmergency =
                    listing.isEmergency && listing.status == 'active';

                return Card(
                  margin: EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    side: isEmergency
                        ? BorderSide(color: Colors.red.shade600, width: 1.5)
                        : BorderSide.none,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.all(12),
                    leading: CircleAvatar(
                      backgroundColor:
                          isEmergency ? Colors.red[100] : Colors.blue[100],
                      child: Text(
                        listing.groupRequired,
                        style: TextStyle(
                          color:
                              isEmergency ? Colors.red[700] : Colors.blue[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            "${listing.bagsRequired} units needed at ${listing.hospitalName ?? 'Not specified'}",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        if (isEmergency)
                          Icon(Icons.priority_high,
                              color: Colors.red[600], size: 18),
                      ],
                    ),
                    subtitle: Text(
                        "Created on: ${listing.createdAt.toLocal().toString().split(' ')[0]}"),
                    trailing: Chip(
                      label: Text(
                        isEmergency ? "Emergency" : "Active",
                        style: TextStyle(
                          color: isEmergency ? Colors.white : Colors.blue[700],
                          fontSize: 12,
                        ),
                      ),
                      backgroundColor:
                          isEmergency ? Colors.red[600] : Colors.blue[100],
                    ),
                    onTap: () {
                      // Navigate to request details
                    },
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Expanded(child: SearchField()),
          const SizedBox(width: 16),
          IconBtnWithCounter(
            svgSrc: filterIcon,
            press: () {},
          ),
          const SizedBox(width: 8),
          IconBtnWithCounter(
            svgSrc: bellIcon,
            numOfItem: 3,
            press: () {},
          ),
        ],
      ),
    );
  }
}

class SearchField extends StatelessWidget {
  const SearchField({super.key});

  @override
  Widget build(BuildContext context) {
    return Form(
      child: TextFormField(
        onChanged: (value) {},
        decoration: InputDecoration(
          filled: true,
          hintStyle: const TextStyle(color: Color(0xFF757575)),
          fillColor: const Color(0xFF979797).withOpacity(0.1),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide.none,
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide.none,
          ),
          enabledBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide.none,
          ),
          hintText: "Search donors",
          prefixIcon: const Icon(Icons.search),
        ),
      ),
    );
  }
}

class IconBtnWithCounter extends StatelessWidget {
  const IconBtnWithCounter({
    super.key,
    required this.svgSrc,
    this.numOfItem = 0,
    required this.press,
  });

  final String svgSrc;
  final int numOfItem;
  final GestureTapCallback press;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(100),
      onTap: press,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            height: 46,
            width: 46,
            decoration: BoxDecoration(
              color: const Color(0xFF979797).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: SvgPicture.string(svgSrc),
          ),
          if (numOfItem != 0)
            Positioned(
              top: -3,
              right: 0,
              child: Container(
                height: 20,
                width: 20,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF4848),
                  shape: BoxShape.circle,
                  border: Border.all(width: 1.5, color: Colors.white),
                ),
                child: Center(
                  child: Text(
                    "$numOfItem",
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            )
        ],
      ),
    );
  }
}

class Banner extends StatelessWidget {
  const Banner({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, "requests");
      },
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF000000),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              "Donate Blood,\nSave Lives",
              style: TextStyle(
                  height: 1.1,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            SizedBox(height: 8),
            Text(
              "20 minutes is all that is \nneeded to save someone's life.",
              style: TextStyle(color: Colors.white, height: 1.1),
            ),
          ],
        ),
      ),
    );
  }
}

class StatsBar extends StatelessWidget {
  const StatsBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            StatItem(title: "Donations", count: 120),
            StatItem(title: "Donors", count: 85),
            StatItem(title: "Requests", count: 150),
          ],
        ),
      ),
    );
  }
}

class StatItem extends StatelessWidget {
  final String title;
  final int count;

  const StatItem({super.key, required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          "$count+",
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.bold,
            color: Colors.red[700],
          ),
        ),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}

const bellIcon =
    '''<svg width="15" height="20" viewBox="0 0 15 20" fill="none" xmlns="http://www.w3.org/2000/svg">
<path fill-rule="evenodd" clip-rule="evenodd" d="M13.9645 15.8912C13.9645 16.1628 13.7495 16.3832 13.4844 16.3832H9.22765H9.21987H1.51477C1.2505 16.3832 1.03633 16.1628 1.03633 15.8912V10.7327C1.03633 7.08053 3.93546 4.10885 7.50043 4.10885C11.0645 4.10885 13.9645 7.08053 13.9645 10.7327V15.8912ZM7.50043 18.9381C6.77414 18.9381 6.18343 18.3327 6.18343 17.5885C6.18343 17.5398 6.18602 17.492 6.19034 17.4442H8.81052C8.81484 17.492 8.81743 17.5398 8.81743 17.5885C8.81743 18.3327 8.22586 18.9381 7.50043 18.9381ZM9.12488 3.2292C9.35805 2.89469 9.49537 2.48673 9.49537 2.04425C9.49537 0.915044 8.6024 0 7.50043 0C6.39847 0 5.5055 0.915044 5.5055 2.04425C5.5055 2.48673 5.64281 2.89469 5.87512 3.2292C2.51828 3.99204 0 7.06549 0 10.7327V15.8912C0 16.7478 0.679659 17.4442 1.51477 17.4442H5.15142C5.14883 17.492 5.1471 17.5398 5.1471 17.5885C5.1471 18.9186 6.20243 20 7.50043 20C8.79843 20 9.8529 18.9186 9.8529 17.5885C9.8529 17.5398 9.85117 17.492 9.84858 17.4442H13.4844C14.3203 17.4442 15 16.7478 15 15.8912V10.7327C15 7.06549 12.4826 3.99204 9.12488 3.2292Z" fill="#626262"/>
</svg>
''';
const filterIcon =
    '''<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" stroke="#525252"><g id="SVGRepo_bgCarrier" stroke-width="0"></g><g id="SVGRepo_tracerCarrier" stroke-linecap="round" stroke-linejoin="round"></g><g id="SVGRepo_iconCarrier"> <g id="style=linear"> <g id="filter-circle"> <path id="vector" d="M2 17.5H7" stroke="#525252" stroke-width="1.5" stroke-miterlimit="10" stroke-linecap="round" stroke-linejoin="round"></path> <path id="vector_2" d="M22 6.5H17" stroke="#525252" stroke-width="1.5" stroke-miterlimit="10" stroke-linecap="round" stroke-linejoin="round"></path> <path id="vector_3" d="M13 17.5H22" stroke="#525252" stroke-width="1.5" stroke-miterlimit="10" stroke-linecap="round" stroke-linejoin="round"></path> <path id="vector_4" d="M11 6.5H2" stroke="#525252" stroke-width="1.5" stroke-miterlimit="10" stroke-linecap="round" stroke-linejoin="round"></path> <path id="vector_5" d="M10 20.3999C8.34315 20.3999 7 19.0568 7 17.3999C7 15.743 8.34315 14.3999 10 14.3999C11.6569 14.3999 13 15.743 13 17.3999C13 19.0568 11.6569 20.3999 10 20.3999Z" stroke="#525252" stroke-width="1.5" stroke-miterlimit="10" stroke-linecap="round" stroke-linejoin="round"></path> <path id="vector_6" d="M14 9.3999C15.6569 9.3999 17 8.05676 17 6.3999C17 4.74305 15.6569 3.3999 14 3.3999C12.3431 3.3999 11 4.74305 11 6.3999C11 8.05676 12.3431 9.3999 14 9.3999Z" stroke="#525252" stroke-width="1.5" stroke-miterlimit="10" stroke-linecap="round" stroke-linejoin="round"></path> </g> </g> </g></svg>''';
