import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'app_state.dart';
import 'booking_screen.dart';
import 'login_screen.dart';
import 'my_bookings_screen.dart';
import 'owner_dashboard.dart';

class TenantHome extends StatefulWidget {
  const TenantHome({super.key});

  @override
  State<TenantHome> createState() => _TenantHomeState();
}

class _TenantHomeState extends State<TenantHome> {
  String selectedCity = 'All';

  Color getStatusColor(String status) {
    return status == 'available' ? AppPalette.success : AppPalette.danger;
  }

  Future<void> updateExpiredBookings() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('bookings')
        .where('status', isEqualTo: 'confirmed')
        .get();

    for (var doc in snapshot.docs) {
      final data = doc.data();

      if (data['endDate'] == null || data['endDate'] == '') continue;

      final endDate = DateTime.tryParse(data['endDate']) ?? DateTime.now();

      if (DateTime.now().isAfter(endDate)) {
        await doc.reference.update({'status': 'completed'});

        await FirebaseFirestore.instance
            .collection('properties')
            .doc(data['propertyId'])
            .update({'status': 'available'});
      }
    }
  }

  @override
  void initState() {
    super.initState();
    updateExpiredBookings();
  }

  void logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();

    if (!mounted) return;
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              logout(context);
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  Widget propertyCard(Map<String, dynamic> data, String id) {
    final status = data['status'] ?? 'available';
    final rent = data['rent'] as num?;
    final rentType = data['rentType'] ?? '';
    final canBook = status == 'available' && rent != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x0F0F172A),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: data['imageBase64'] != null && data['imageBase64'].toString().isNotEmpty
                  ? Image.memory(
                      base64Decode(data['imageBase64']),
                      width: 120,
                      height: 132,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 120,
                      height: 132,
                      color: const Color(0xFFE2E8F0),
                      child: const Icon(Icons.home_work_outlined, size: 42, color: AppPalette.mutedText),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['title'] ?? '',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppPalette.text),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    rent != null ? 'Rs $rent ${rentType != '' ? '/ $rentType' : ''}' : 'Rent not set',
                    style: const TextStyle(fontWeight: FontWeight.w700, color: AppPalette.primary),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_city_outlined, size: 16, color: AppPalette.mutedText),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          data['location'] ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AppPalette.mutedText),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    data['address'] ?? 'No address',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppPalette.mutedText, fontSize: 12.5),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: getStatusColor(status).withAlpha(36),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(color: getStatusColor(status), fontWeight: FontWeight.w700, fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 10),
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
                                    title: data['title'],
                                    rent: rent.toInt(),
                                    ownerId: data['ownerId'],
                                  ),
                                ),
                              );
                            }
                          : null,
                      child: Text(rent == null ? 'Unavailable' : 'Book Now'),
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
    Query query = FirebaseFirestore.instance.collection('properties');

    if (selectedCity != 'All') {
      query = query.where('location', isEqualTo: selectedCity);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Explore Properties'),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz_rounded),
            tooltip: 'Switch to Owner',
            onPressed: () {
              AppState.currentRole = 'owner';
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const OwnerDashboard()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.book_online_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MyBookingsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => confirmLogout(context),
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
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x380F62FE),
                          blurRadius: 14,
                          offset: const Offset(0, 8),
                        )
                      ],
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.apartment_rounded, color: Colors.white),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Find the right place and send your booking in minutes.',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('properties').snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const LinearProgressIndicator(minHeight: 2);
                        }

                        final cities = snapshot.data!.docs.map((doc) => doc['location'] as String).toSet().toList();
                        cities.sort();
                        cities.insert(0, 'All');

                        return DropdownButtonFormField<String>(
                          initialValue: selectedCity,
                          decoration: const InputDecoration(
                            labelText: 'Filter by City',
                            prefixIcon: Icon(Icons.location_city_outlined),
                          ),
                          items: cities
                              .map((city) => DropdownMenuItem<String>(value: city, child: Text(city)))
                              .toList(),
                          onChanged: (value) {
                            setState(() => selectedCity = value!);
                          },
                        );
                      },
                    ),
                  ),
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
                            child: Text('No properties found', style: TextStyle(color: AppPalette.mutedText)),
                          );
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
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
            ),
          ),
        ],
      ),
    );
  }
}
