import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BookingScreen extends StatefulWidget {
  final String propertyId;
  final String title;
  final int rent;
  final String ownerId;

  const BookingScreen({
    super.key,
    required this.propertyId,
    required this.title,
    required this.rent,
    required this.ownerId,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {

  DateTime? startDate;
  DateTime? endDate;

  final TextEditingController peopleController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  bool isLoading = false;

  /// 🎨 COMMON INPUT STYLE
  InputDecoration inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.grey.shade100,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  /// 📅 PICK DATE
  Future<void> pickDate(bool isStart) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          startDate = picked;
        } else {
          endDate = picked;
        }
      });
    }
  }

  /// 🚀 BOOKING FUNCTION
  Future<void> confirmBooking() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null ||
        peopleController.text.isEmpty ||
        phoneController.text.isEmpty) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill required fields")),
      );
      return;
    }

    try {
      setState(() => isLoading = true);

      await FirebaseFirestore.instance.collection("bookings").add({

        "propertyId": widget.propertyId,
        "title": widget.title,

        "ownerId": widget.ownerId,
        "userId": user.uid,

        "tenantName": user.email ?? "User",
        "tenantPhone": phoneController.text,
        "people": peopleController.text,

        "startDate": startDate != null
            ? "${startDate!.day}/${startDate!.month}/${startDate!.year}"
            : "",

        "endDate": endDate != null
            ? "${endDate!.day}/${endDate!.month}/${endDate!.year}"
            : "",

        "status": "pending",
        "paymentStatus": "pending",
        "timestamp": FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Booking Sent ✅")),
      );

      Navigator.pop(context);

    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => isLoading = false);
    }
  }

  /// 📅 DATE BUTTON UI
  Widget dateButton(String text, DateTime? date, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue),
          ),
          child: Center(
            child: Text(
              date == null
                  ? text
                  : "${date.day}/${date.month}/${date.year}",
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.grey[100],

      appBar: AppBar(
        title: const Text("Book Property"),
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),

        child: Card(
          elevation: 5,
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
                  widget.title,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 8),

                /// 💰 RENT
                Text(
                  "₹${widget.rent}",
                  style: const TextStyle(
                      fontSize: 18, color: Colors.green),
                ),

                const Divider(height: 30),

                /// 👥 PEOPLE
                TextField(
                  controller: peopleController,
                  keyboardType: TextInputType.number,
                  decoration: inputDecoration("Number of People", Icons.group),
                ),

                const SizedBox(height: 15),

                /// 📞 PHONE
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: inputDecoration("Phone Number", Icons.phone),
                ),

                const SizedBox(height: 20),

                /// 📅 DATE PICKERS
                const Text(
                  "Select Dates (Optional)",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 10),

                Row(
                  children: [
                    dateButton("Start Date", startDate, () => pickDate(true)),
                    const SizedBox(width: 10),
                    dateButton("End Date", endDate, () => pickDate(false)),
                  ],
                ),

                const SizedBox(height: 30),

                /// 🚀 BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: isLoading ? null : confirmBooking,
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                      "Confirm Booking",
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}