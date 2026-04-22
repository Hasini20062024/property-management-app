import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class OwnerBookingsScreen extends StatelessWidget {
  const OwnerBookingsScreen({super.key});

  String formatTenantName(String? name) {
    if (name == null || name.isEmpty) return 'No Name';
    if (name.contains('@')) return name.split('@')[0];
    return name;
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return AppPalette.warning;
      case 'approved':
        return AppPalette.primary;
      case 'confirmed':
        return AppPalette.success;
      default:
        return Colors.grey;
    }
  }

  Future<void> approveBooking(String id, BuildContext context) async {
    await FirebaseFirestore.instance.collection('bookings').doc(id).update({'status': 'approved'});

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Booking approved')),
    );
  }

  Future<void> rejectBooking(String id, BuildContext context) async {
    await FirebaseFirestore.instance.collection('bookings').doc(id).update({'status': 'rejected'});

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Booking rejected')),
    );
  }

  Widget bookingCard(Map<String, dynamic> data, String id, BuildContext context) {
    final tenantName = formatTenantName(data['tenantName']);
    final phone = data['tenantPhone'] ?? '';
    final startDate = data['startDate'];
    final endDate = data['endDate'];
    final status = data['status'] ?? 'pending';
    final statusColor = getStatusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Color(0x0F0F172A),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  data['title'] ?? '',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(31),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: TextStyle(color: statusColor, fontWeight: FontWeight.w700, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('Tenant: $tenantName', style: const TextStyle(color: AppPalette.mutedText)),
          const SizedBox(height: 4),
          Text('Phone: $phone', style: const TextStyle(color: AppPalette.mutedText)),
          const SizedBox(height: 4),
          if ((startDate == null || startDate == '') && (endDate == null || endDate == ''))
            const Text('Stay: Long Term', style: TextStyle(fontWeight: FontWeight.w600, color: AppPalette.primary))
          else ...[
            Text('From: $startDate', style: const TextStyle(color: AppPalette.mutedText)),
            Text('To: $endDate', style: const TextStyle(color: AppPalette.mutedText)),
          ],
          const SizedBox(height: 12),
          if (status == 'pending')
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppPalette.success),
                    onPressed: () => approveBooking(id, context),
                    child: const Text('Approve'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppPalette.danger),
                    onPressed: () => rejectBooking(id, context),
                    child: const Text('Reject'),
                  ),
                ),
              ],
            ),
          if (status == 'approved')
            const Text('Waiting for payment', style: TextStyle(color: AppPalette.primary, fontWeight: FontWeight.w600)),
          if (status == 'confirmed')
            const Text('Booking completed', style: TextStyle(color: AppPalette.success, fontWeight: FontWeight.w600)),
        ],
      ),
    );
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
    final owner = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Tenant Bookings')),
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
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('bookings').where('ownerId', isEqualTo: owner!.uid).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text('No bookings yet', style: TextStyle(fontSize: 16, color: AppPalette.mutedText)),
                );
              }

              final bookings = snapshot.data!.docs;

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                itemCount: bookings.length,
                itemBuilder: (context, index) {
                  final booking = bookings[index];
                  final data = booking.data() as Map<String, dynamic>;

                  return bookingCard(data, booking.id, context);
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
