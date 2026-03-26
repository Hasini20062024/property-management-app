import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {

  final user = FirebaseAuth.instance.currentUser;

  /// 📅 FORMAT DATE
  String formatDate(String? date) {
    if (date == null || date.isEmpty) return "";
    if (date.contains(" ")) {
      return date.split(" ")[0];
    }
    return date;
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

  /// ❌ CANCEL BOOKING
  Future<void> cancelBooking(String bookingId, String propertyId) async {
    await FirebaseFirestore.instance
        .collection('bookings')
        .doc(bookingId)
        .delete();

    await FirebaseFirestore.instance
        .collection('properties')
        .doc(propertyId)
        .update({"status": "available"});

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Booking Cancelled ❌")),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.grey[100],

      appBar: AppBar(
        title: const Text("My Bookings"),
        centerTitle: true,
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            /// ✅ FIXED HERE 🔥
            .where('tenantName', isEqualTo: user!.email)
            .snapshots(),

        builder: (context, snapshot) {

          if (snapshot.hasError) {
            return Center(
              child: Text("Error: ${snapshot.error}"),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final bookings = snapshot.data!.docs;

          if (bookings.isEmpty) {
            return const Center(
              child: Text("No bookings yet 🏠"),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: bookings.length,
            itemBuilder: (context, index) {

              final booking = bookings[index];
              final data = booking.data() as Map<String, dynamic>;

              final status = data["status"] ?? "pending";
              final startDate = data["startDate"];
              final endDate = data["endDate"];

              return Card(
                elevation: 5,
                margin: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),

                child: Padding(
                  padding: const EdgeInsets.all(15),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      /// 🏠 TITLE
                      Text(
                        data["title"] ?? "",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      /// 📅 DATE
                      if ((startDate == null || startDate == "") &&
                          (endDate == null || endDate == ""))
                        const Text(
                          "Stay: Long Term 🏠",
                          style: TextStyle(
                            color: Colors.purple,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      else ...[
                        Text("From: ${formatDate(startDate)}"),
                        Text("To: ${formatDate(endDate)}"),
                      ],

                      const SizedBox(height: 10),

                      /// STATUS
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

                      const SizedBox(height: 12),

                      /// CANCEL
                      if (status == "pending")
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            onPressed: () {
                              cancelBooking(
                                  booking.id, data["propertyId"]);
                            },
                            child: const Text("Cancel Booking"),
                          ),
                        ),

                      /// PAY
                      if (status == "approved" &&
                          data["paymentStatus"] == "pending")
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {

                              await FirebaseFirestore.instance
                                  .collection("bookings")
                                  .doc(booking.id)
                                  .update({
                                "paymentStatus": "paid",
                                "status": "confirmed",
                              });

                              await FirebaseFirestore.instance
                                  .collection("properties")
                                  .doc(data["propertyId"])
                                  .update({
                                "status": "booked",
                              });

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text("Payment Successful 🎉")),
                              );
                            },
                            child: const Text("Pay Now"),
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
    );
  }
}