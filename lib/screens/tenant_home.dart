import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'booking_screen.dart';
import 'my_bookings_screen.dart';
import 'login_screen.dart';
import 'owner_dashboard.dart';
import 'app_state.dart';

class TenantHome extends StatefulWidget {
  const TenantHome({super.key});

  @override
  State<TenantHome> createState() => _TenantHomeState();
}

class _TenantHomeState extends State<TenantHome> {
  String selectedCity = "All";

  /// 🎨 STATUS COLOR
  Color getStatusColor(String status) {
    return status == "available" ? Colors.green : Colors.red;
  }

  /// 🔄 AUTO UPDATE EXPIRED BOOKINGS
  Future<void> updateExpiredBookings() async {
    final snapshot = await FirebaseFirestore.instance
        .collection("bookings")
        .where("status", isEqualTo: "confirmed")
        .get();

    for (var doc in snapshot.docs) {
      final data = doc.data();

      if (data["endDate"] == null || data["endDate"] == "") continue;

      DateTime endDate =
          DateTime.tryParse(data["endDate"]) ?? DateTime.now();

      if (DateTime.now().isAfter(endDate)) {
        await doc.reference.update({"status": "completed"});

        await FirebaseFirestore.instance
            .collection("properties")
            .doc(data["propertyId"])
            .update({"status": "available"});
      }
    }
  }

  @override
  void initState() {
    super.initState();
    updateExpiredBookings();
  }

  /// 🔐 LOGOUT
  void logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text("Logout"),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              logout(context);
            },
            child: const Text("Logout"),
          ),
        ],
      ),
    );
  }

  /// 📦 PROPERTY CARD
  Widget propertyCard(Map<String, dynamic> data, String id) {

    final status = data["status"] ?? "available";
    final rent = data["rent"] as num?;
    final rentType = data["rentType"] ?? "";
    final canBook = status == "available" && rent != null;

    return Card(
      elevation: 6,
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),

      child: Padding(
        padding: const EdgeInsets.all(10),

        child: Row(
          children: [

            /// IMAGE
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: data["imageBase64"] != null &&
                      data["imageBase64"].toString().isNotEmpty
                  ? Image.memory(
                      base64Decode(data["imageBase64"]),
                      width: 110,
                      height: 110,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 110,
                      height: 110,
                      color: Colors.grey[300],
                      child: const Icon(Icons.home, size: 40),
                    ),
            ),

            const SizedBox(width: 10),

            /// DETAILS
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Text(
                    data["title"] ?? "",
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    rent != null
                        ? "₹$rent ${rentType != "" ? "/ $rentType" : ""}"
                        : "Rent not set",
                  ),

                  const SizedBox(height: 5),

                  Text("📍 ${data["location"] ?? ""}"),

                  const SizedBox(height: 3),

                  Text(
                    "🏡 ${data["address"] ?? "No address"}",
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 5),

                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: getStatusColor(status).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        color: getStatusColor(status),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    data["description"] ?? "",
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 5),

                  Text(
                    "📞 ${data["contact"] ?? ""}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 8),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: canBook
                          ? () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => BookingScreen(
                                    propertyId: id,
                                    title: data["title"],
                                    rent: rent.toInt(),
                                    ownerId: data["ownerId"],
                                  ),
                                ),
                              );
                            }
                          : null,
                      child: Text(
                        rent == null ? "Unavailable" : "Book Now",
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    Query query =
        FirebaseFirestore.instance.collection("properties");

    if (selectedCity != "All") {
      query = query.where("location", isEqualTo: selectedCity);
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],

      appBar: AppBar(
        title: const Text("Explore Properties"),
        centerTitle: true,

        /// 🔥 UPDATED ACTIONS
        actions: [

          /// 🔁 SWITCH TO OWNER
          IconButton(
            icon: const Icon(Icons.swap_horiz),
            tooltip: "Switch to Owner",
            onPressed: () {
              AppState.currentRole = "owner";

              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const OwnerDashboard(),
                ),
              );
            },
          ),

          /// 📋 BOOKINGS
          IconButton(
            icon: const Icon(Icons.book_online),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const MyBookingsScreen(),
                ),
              );
            },
          ),

          /// 🔐 LOGOUT
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => confirmLogout(context),
          ),
        ],
      ),

      body: Column(
        children: [

          /// CITY FILTER
          Padding(
            padding: const EdgeInsets.all(10),
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("properties")
                  .snapshots(),
              builder: (context, snapshot) {

                if (!snapshot.hasData) {
                  return const CircularProgressIndicator();
                }

                final cities = snapshot.data!.docs
                    .map((doc) => doc["location"] as String)
                    .toSet()
                    .toList();

                cities.sort();
                cities.insert(0, "All");

                return DropdownButtonFormField<String>(
                  value: selectedCity,
                  decoration: InputDecoration(
                    labelText: "Filter by City",
                    prefixIcon: const Icon(Icons.location_city),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: cities.map((city) {
                    return DropdownMenuItem(
                      value: city,
                      child: Text(city),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => selectedCity = value!);
                  },
                );
              },
            ),
          ),

          /// PROPERTY LIST
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: query.snapshots(),
              builder: (context, snapshot) {

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final properties = snapshot.data!.docs;

                if (properties.isEmpty) {
                  return const Center(
                    child: Text("No properties found 🏠"),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: properties.length,
                  itemBuilder: (context, index) {

                    final doc = properties[index];
                    final data = doc.data() as Map<String, dynamic>;

                    return propertyCard(data, doc.id);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}