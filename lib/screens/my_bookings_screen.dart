import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  final user = FirebaseAuth.instance.currentUser;
  static const Map<String, String> _paymentLinks = {
    'PhonePe': 'https://www.phonepe.com/',
    'Google Pay': 'https://pay.google.com/',
    'Paytm': 'https://paytm.com/',
  };

  String formatDate(String? date) {
    if (date == null || date.isEmpty) return '';
    if (date.contains(' ')) return date.split(' ')[0];
    return date;
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return const Color(0xFFF59E0B);
      case 'approved':
        return const Color(0xFF2563EB);
      case 'confirmed':
        return const Color(0xFF059669);
      default:
        return Colors.grey;
    }
  }

  Future<void> cancelBooking(String bookingId, String propertyId) async {
    await FirebaseFirestore.instance.collection('bookings').doc(bookingId).delete();

    await FirebaseFirestore.instance.collection('properties').doc(propertyId).update({'status': 'available'});

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Booking cancelled')),
    );
  }

  Future<void> payBooking(String bookingId, String propertyId, String method) async {
    final redirectUrl = _paymentLinks[method];
    if (redirectUrl == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unsupported payment method')),
      );
      return;
    }

    final uri = Uri.parse(redirectUrl);
    final launched = await launchUrl(uri, mode: LaunchMode.platformDefault);

    if (!launched) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open $method')),
      );
      return;
    }

    await FirebaseFirestore.instance.collection('bookings').doc(bookingId).update({
      'status': 'confirmed',
      'paymentStatus': 'successful',
      'paymentMethod': method,
      'paymentRedirectUrl': redirectUrl,
    });

    await FirebaseFirestore.instance.collection('properties').doc(propertyId).update({'status': 'booked'});

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Payment successful! Booking confirmed.')),
    );
  }

  Future<void> _showPaymentOptions(String bookingId, String propertyId) async {
    final selectedMethod = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Choose payment app',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Select where you want to continue payment.',
                  style: TextStyle(color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 16),
                ..._paymentLinks.keys.map(
                  (method) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      tileColor: const Color(0xFFF8FAFC),
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFE0F2FE),
                        child: Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF0369A1)),
                      ),
                      title: Text(method),
                      trailing: const Icon(Icons.open_in_new_rounded),
                      onTap: () => Navigator.pop(context, method),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selectedMethod == null) return;
    await payBooking(bookingId, propertyId, selectedMethod);
  }

  String _statusLabel(String status) {
    if (status.isEmpty) return 'PENDING';
    return status.toUpperCase();
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

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF334155)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFF1E293B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _emptyState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Color(0x0F0F172A),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.calendar_month_rounded, size: 42, color: Color(0xFF64748B)),
            SizedBox(height: 12),
            Text(
              'No bookings yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Your upcoming and active bookings will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bookingCard(DocumentSnapshot booking) {
    final data = booking.data() as Map<String, dynamic>;

    final status = (data['status'] ?? 'pending').toString();
    final startDate = data['startDate'] as String?;
    final endDate = data['endDate'] as String?;
    final isLongTerm = (startDate == null || startDate.isEmpty) && (endDate == null || endDate.isEmpty);

    final statusColor = getStatusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFFFF), Color(0xFFF8FBFF)],
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x0F0F172A),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: const Color(0xFFE0F2FE),
                  ),
                  child: const Icon(
                    Icons.home_work_outlined,
                    color: Color(0xFF0369A1),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    (data['title'] ?? '').toString(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(31),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: statusColor.withAlpha(89)),
                  ),
                  child: Text(
                    _statusLabel(status),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF6FF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: isLongTerm
                  ? _infoRow(Icons.schedule_rounded, 'Stay type: Long term')
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _infoRow(Icons.calendar_today_rounded, 'From: ${formatDate(startDate)}'),
                        const SizedBox(height: 6),
                        _infoRow(Icons.event_available_rounded, 'To: ${formatDate(endDate)}'),
                      ],
                    )
            ),
            const SizedBox(height: 12),
            if (status == 'pending')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => cancelBooking(booking.id, (data['propertyId'] ?? '').toString()),
                  icon: const Icon(Icons.close_rounded, size: 18),
                  label: const Text('Cancel Booking'),
                ),
              ),
            if (status == 'approved')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => _showPaymentOptions(
                    booking.id,
                    (data['propertyId'] ?? '').toString(),
                  ),
                  icon: const Icon(Icons.payment_rounded, size: 18),
                  label: const Text('Pay Now'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Bookings',
        ),
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
          Column(
            children: [
              Container(
                margin: const EdgeInsets.fromLTRB(14, 2, 14, 10),
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0EA5E9), Color(0xFF2563EB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2563EB).withOpacity(0.22),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Row(
                  children: [
                    Icon(Icons.bookmark_rounded, color: Colors.white),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Track your booking status and complete payment when approved.',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('bookings')
                      .where('tenantName', isEqualTo: user!.email)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            'Error: ${snapshot.error}',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final bookings = snapshot.data?.docs ?? [];

                    if (bookings.isEmpty) {
                      return _emptyState();
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                      itemCount: bookings.length,
                      itemBuilder: (context, index) => _bookingCard(bookings[index]),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
