import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'add_property_screen.dart';
import 'edit_property_screen.dart';
import 'login_screen.dart';
import 'owner_bookings_screen.dart';
import 'app_state.dart';
import 'tenant_home.dart';

class OwnerDashboard extends StatelessWidget {
  const OwnerDashboard({super.key});

  /// 🔐 LOGOUT
  Future<void> logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  /// ❌ DELETE
  Future<void> deleteProperty(String id) async {
    await FirebaseFirestore.instance
        .collection("properties")
        .doc(id)
        .delete();
  }

  /// 🔄 STATUS
  Future<void> toggleStatus(String id, String currentStatus) async {
    String newStatus =
        currentStatus == "available" ? "booked" : "available";

    await FirebaseFirestore.instance
        .collection("properties")
        .doc(id)
        .update({"status": newStatus});
  }

  /// 🎨 STATUS COLOR
  Color getStatusColor(String status) {
    return status == "available" ? Colors.green : Colors.red;
  }

  /// ✅ APPROVE
  Future<void> approveBooking(String id) async {
    await FirebaseFirestore.instance
        .collection("bookings")
        .doc(id)
        .update({"status": "approved"});
  }

  /// ❌ REJECT
  Future<void> rejectBooking(String id) async {
    await FirebaseFirestore.instance
        .collection("bookings")
        .doc(id)
        .update({"status": "rejected"});
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey[100],

      appBar: AppBar(
        title: const Text("Owner Dashboard"),
        centerTitle: true,

        /// 🔥 UPDATED ACTIONS
        actions: [

          /// 🔁 SWITCH TO TENANT
          IconButton(
            icon: const Icon(Icons.swap_horiz),
            tooltip: "Switch to Tenant",
            onPressed: () {
              AppState.currentRole = "tenant";

              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const TenantHome(),
                ),
              );
            },
          ),

          /// 📋 BOOKINGS
          IconButton(
            icon: const Icon(Icons.list_alt),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const OwnerBookingsScreen(),
                ),
              );
            },
          ),

          /// 🔐 LOGOUT
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => logout(context),
          ),
        ],
      ),

      body: Column(
        children: [

          /// 🔔 BOOKING REQUESTS
          Expanded(
            flex: 2,
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("bookings")
                  .where("ownerId", isEqualTo: user!.uid)
                  .where("status", isEqualTo: "pending")
                  .snapshots(),
              builder: (context, snapshot) {

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final bookings = snapshot.data!.docs;

                if (bookings.isEmpty) {
                  return const Center(
                    child: Text("No new booking requests 🔔"),
                  );
                }

                return ListView(
                  children: [

                    const Padding(
                      padding: EdgeInsets.all(10),
                      child: Text(
                        "Booking Requests",
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                      ),
                    ),

                    ...bookings.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;

                      return Card(
                        elevation: 4,
                        margin: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),

                        child: ListTile(
                          title: Text(
                            data["title"] ?? "",
                            style: const TextStyle(
                                fontWeight: FontWeight.bold),
                          ),

                          subtitle: Text(
                            "👤 ${data["tenantName"]}\n"
                            "📞 ${data["tenantPhone"]}\n"
                            "👥 ${data["people"]}",
                          ),

                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.check,
                                    color: Colors.green),
                                onPressed: () => approveBooking(doc.id),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close,
                                    color: Colors.red),
                                onPressed: () => rejectBooking(doc.id),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
          ),

          const Divider(),

          /// 🏠 PROPERTIES
          Expanded(
            flex: 5,
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("properties")
                  .where("ownerId", isEqualTo: user.uid)
                  .snapshots(),
              builder: (context, snapshot) {

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final properties = snapshot.data!.docs;

                if (properties.isEmpty) {
                  return const Center(
                    child: Text("No properties yet 🏠"),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: properties.length,
                  itemBuilder: (context, index) {

                    final doc = properties[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final status = data["status"] ?? "available";

                    return Card(
                      elevation: 6,
                      margin: const EdgeInsets.symmetric(vertical: 8),
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
                                      data["imageBase64"]
                                          .toString()
                                          .isNotEmpty
                                  ? Image.memory(
                                      base64Decode(
                                          data["imageBase64"]),
                                      width: 110,
                                      height: 110,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      width: 110,
                                      height: 110,
                                      color: Colors.grey[300],
                                      child: const Icon(Icons.home),
                                    ),
                            ),

                            const SizedBox(width: 10),

                            /// DETAILS
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [

                                  Text(
                                    data["title"] ?? "",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),

                                  const SizedBox(height: 5),

                                  Text(
                                    data["rent"] != null
                                        ? "₹${data["rent"]} / ${data["rentType"] ?? ""}"
                                        : "No rent",
                                  ),

                                  Text("📍 ${data["location"] ?? ""}"),

                                  const SizedBox(height: 5),

                                  /// STATUS
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: getStatusColor(status)
                                          .withOpacity(0.15),
                                      borderRadius:
                                          BorderRadius.circular(20),
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

                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit,
                                            color: Colors.blue),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  EditPropertyScreen(
                                                propertyId: doc.id,
                                                title: data["title"],
                                                rent: data["rent"]
                                                        ?.toString() ?? "",
                                                description:
                                                    data["description"],
                                                contact:
                                                    data["contact"],
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete,
                                            color: Colors.red),
                                        onPressed: () =>
                                            deleteProperty(doc.id),
                                      ),
                                    ],
                                  ),

                                  ElevatedButton(
                                    onPressed: () =>
                                        toggleStatus(doc.id, status),
                                    child: Text(
                                      status == "available"
                                          ? "Mark Booked"
                                          : "Mark Available",
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddPropertyScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}