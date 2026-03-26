import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OwnerBookingsScreen extends StatelessWidget {
  const OwnerBookingsScreen({super.key});

  /// 👤 FORMAT NAME
  String formatTenantName(String? name) {
    if (name == null || name.isEmpty) return "No Name";
    if (name.contains("@")) return name.split("@")[0];
    return name;
  }

  /// 🎨 STATUS COLOR
  Color getStatusColor(String status) {
    switch (status) {
      case "pending":
        return Colors.orange;
      case "approved":
        return Colors.blue;
      case "confirmed":
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  /// ✅ APPROVE
  Future<void> approveBooking(String id, BuildContext context) async {
    await FirebaseFirestore.instance
        .collection("bookings")
        .doc(id)
        .update({"status": "approved"});

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Booking Approved ✅")),
    );
  }

  /// ❌ REJECT
  Future<void> rejectBooking(String id, BuildContext context) async {
    await FirebaseFirestore.instance
        .collection("bookings")
        .doc(id)
        .update({"status": "rejected"});

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Booking Rejected ❌")),
    );
  }

  /// 📦 BOOKING CARD
  Widget bookingCard(Map<String, dynamic> data, String id, BuildContext context) {

    final tenantName = formatTenantName(data["tenantName"]);
    final phone = data["tenantPhone"] ?? "";
    final startDate = data["startDate"];
    final endDate = data["endDate"];
    final status = data["status"] ?? "pending";

    return Card(
      elevation: 6,
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),

      child: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// 🏠 TITLE
            Text(
              data["title"] ?? "",
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            /// 👤 TENANT INFO
            Row(
              children: [
                const Icon(Icons.person, size: 18),
                const SizedBox(width: 5),
                Text("Tenant: $tenantName"),
              ],
            ),

            const SizedBox(height: 5),

            Row(
              children: [
                const Icon(Icons.phone, size: 18),
                const SizedBox(width: 5),
                Text(phone),
              ],
            ),

            const SizedBox(height: 10),

            /// 📅 DATES
            if ((startDate == null || startDate == "") &&
                (endDate == null || endDate == ""))
              const Text(
                "Stay: Long Term 🏠",
                style: TextStyle(
                    color: Colors.purple,
                    fontWeight: FontWeight.bold),
              )
            else ...[
              Text("From: $startDate"),
              Text("To: $endDate"),
            ],

            const SizedBox(height: 12),

            /// 📌 STATUS BADGE
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 5),
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

            const SizedBox(height: 15),

            /// 🔘 ACTION BUTTONS
            if (status == "pending")
              Row(
                children: [

                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      onPressed: () => approveBooking(id, context),
                      child: const Text("Approve"),
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      onPressed: () => rejectBooking(id, context),
                      child: const Text("Reject"),
                    ),
                  ),
                ],
              ),

            if (status == "approved")
              const Text(
                "Waiting for payment 💳",
                style: TextStyle(color: Colors.blue),
              ),

            if (status == "confirmed")
              const Text(
                "Booking Completed ✅",
                style: TextStyle(color: Colors.green),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    final owner = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey[100],

      appBar: AppBar(
        title: const Text("Tenant Bookings"),
        centerTitle: true,
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('ownerId', isEqualTo: owner!.uid)
            .snapshots(),

        builder: (context, snapshot) {

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "No bookings yet 🏠",
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          final bookings = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: bookings.length,
            itemBuilder: (context, index) {

              final booking = bookings[index];
              final data = booking.data() as Map<String, dynamic>;

              return bookingCard(data, booking.id, context);
            },
          );
        },
      ),
    );
  }
}