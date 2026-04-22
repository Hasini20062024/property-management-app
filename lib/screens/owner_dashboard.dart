import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'add_property_screen.dart';
import 'app_state.dart';
import 'edit_property_screen.dart';
import 'login_screen.dart';
import 'owner_bookings_screen.dart';
import 'tenant_home.dart';

class OwnerDashboard extends StatelessWidget {
  const OwnerDashboard({super.key});

  Future<void> logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> deleteProperty(String id) async {
    await FirebaseFirestore.instance.collection('properties').doc(id).delete();
  }

  Future<void> toggleStatus(String id, String currentStatus) async {
    final newStatus = currentStatus == 'available' ? 'booked' : 'available';

    await FirebaseFirestore.instance.collection('properties').doc(id).update({'status': newStatus});
  }

  Color getStatusColor(String status) {
    return status == 'available' ? AppPalette.success : AppPalette.danger;
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

  Future<void> approveBooking(String id) async {
    await FirebaseFirestore.instance.collection('bookings').doc(id).update({'status': 'approved'});
  }

  Future<void> rejectBooking(String id) async {
    await FirebaseFirestore.instance.collection('bookings').doc(id).update({'status': 'rejected'});
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Owner Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz_rounded),
            tooltip: 'Switch to Tenant',
            onPressed: () {
              AppState.currentRole = 'tenant';
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const TenantHome()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.list_alt_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OwnerBookingsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => logout(context),
          ),
        ],
      ),
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
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.fromLTRB(14, 2, 14, 10),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(
                colors: [Color(0xFF0EA5E9), Color(0xFF0F62FE)],
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.dashboard_customize_rounded, color: Colors.white),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Manage listings, review requests, and control availability.',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('bookings')
                  .where('ownerId', isEqualTo: user!.uid)
                  .where('status', isEqualTo: 'pending')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final bookings = snapshot.data!.docs;

                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 14),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: bookings.isEmpty
                      ? const Center(child: Text('No new booking requests'))
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Booking Requests', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
                            const SizedBox(height: 8),
                            Expanded(
                              child: ListView.builder(
                                itemCount: bookings.length,
                                itemBuilder: (context, index) {
                                  final doc = bookings[index];
                                  final data = doc.data() as Map<String, dynamic>;

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: const Color(0xFFE2E8F0)),
                                    ),
                                    child: ListTile(
                                      title: Text(data['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700)),
                                      subtitle: Text(
                                        'Tenant: ${data['tenantName']}\nPhone: ${data['tenantPhone']}\nPeople: ${data['people']}',
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.check_circle_rounded, color: AppPalette.success),
                                            onPressed: () => approveBooking(doc.id),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.cancel_rounded, color: AppPalette.danger),
                                            onPressed: () => rejectBooking(doc.id),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            flex: 5,
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('properties').where('ownerId', isEqualTo: user.uid).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final properties = snapshot.data!.docs;

                if (properties.isEmpty) {
                  return const Center(child: Text('No properties yet'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
                  itemCount: properties.length,
                  itemBuilder: (context, index) {
                    final doc = properties[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final status = data['status'] ?? 'available';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0F172A).withOpacity(0.05),
                            blurRadius: 14,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: data['imageBase64'] != null && data['imageBase64'].toString().isNotEmpty
                                ? Image.memory(
                                    base64Decode(data['imageBase64']),
                                    width: 116,
                                    height: 125,
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    width: 116,
                                    height: 125,
                                    color: const Color(0xFFE2E8F0),
                                    child: const Icon(Icons.home_work_rounded),
                                  ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data['title'] ?? '',
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  data['rent'] != null
                                      ? 'Rs ${data['rent']} / ${data['rentType'] ?? ''}'
                                      : 'No rent',
                                  style: const TextStyle(color: AppPalette.primary, fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 4),
                                Text('City: ${data['location'] ?? ''}', style: const TextStyle(color: AppPalette.mutedText)),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: getStatusColor(status).withAlpha(33),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    status.toUpperCase(),
                                    style: TextStyle(color: getStatusColor(status), fontWeight: FontWeight.w700, fontSize: 12),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    IconButton(
                                      visualDensity: VisualDensity.compact,
                                      icon: const Icon(Icons.edit_rounded, color: AppPalette.primary),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => EditPropertyScreen(
                                              propertyId: doc.id,
                                              title: data['title'],
                                              rent: data['rent']?.toString() ?? '',
                                              description: data['description'],
                                              contact: data['contact'],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    IconButton(
                                      visualDensity: VisualDensity.compact,
                                      icon: const Icon(Icons.delete_outline_rounded, color: AppPalette.danger),
                                      onPressed: () => deleteProperty(doc.id),
                                    ),
                                  ],
                                ),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () => toggleStatus(doc.id, status),
                                    child: Text(status == 'available' ? 'Mark Booked' : 'Mark Available'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    ),
  ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddPropertyScreen()),
          );
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Property'),
      ),
    );
  }
}
