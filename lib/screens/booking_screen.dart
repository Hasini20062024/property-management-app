import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

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

  Future<void> pickDate(bool isStart) async {
    final picked = await showDatePicker(
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

  Future<void> confirmBooking() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null || peopleController.text.isEmpty || phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill required fields')),
      );
      return;
    }

    try {
      setState(() => isLoading = true);

      await FirebaseFirestore.instance.collection('bookings').add({
        'propertyId': widget.propertyId,
        'title': widget.title,
        'ownerId': widget.ownerId,
        'userId': user.uid,
        'tenantName': user.email ?? 'User',
        'tenantPhone': phoneController.text,
        'people': peopleController.text,
        'startDate': startDate != null ? '${startDate!.day}/${startDate!.month}/${startDate!.year}' : '',
        'endDate': endDate != null ? '${endDate!.day}/${endDate!.month}/${endDate!.year}' : '',
        'status': 'pending',
        'paymentStatus': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking sent')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Widget dateButton(String text, DateTime? date, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFBFDBFE)),
          ),
          child: Center(
            child: Text(
              date == null ? text : '${date.day}/${date.month}/${date.year}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    peopleController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  Widget _glassOrb({
    required double size,
    required List<Color> colors,
    required double top,
    required double right,
  }) {
    return Positioned(
      top: top,
      right: right,
      child: IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: colors,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Book Property')),
      body: Stack(
        children: [
          _glassOrb(
            size: 220,
            top: -90,
            right: -60,
            colors: [
              Color(0x4D38BDF8),
              Color(0x242563EB),
            ],
          ),
          _glassOrb(
            size: 180,
            top: 220,
            right: -80,
            colors: [
              Color(0x3814B8A6),
              Color(0x190EA5E9),
            ],
          ),
          Container(
            decoration: const BoxDecoration(
              color: AppPalette.background,
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            color: const Color(0xFFEFF6FF),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                              const SizedBox(height: 4),
                              Text('Rs ${widget.rent}', style: const TextStyle(fontSize: 17, color: AppPalette.success, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        TextField(
                          controller: peopleController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Number of People',
                            prefixIcon: Icon(Icons.group_outlined),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Phone Number',
                            prefixIcon: Icon(Icons.phone_outlined),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text('Select Dates (Optional)', style: TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            dateButton('Start Date', startDate, () => pickDate(true)),
                            const SizedBox(width: 10),
                            dateButton('End Date', endDate, () => pickDate(false)),
                          ],
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : confirmBooking,
                            child: isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                                  )
                                : const Text('Confirm Booking', style: TextStyle(fontSize: 16)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
