import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'app_state.dart';
import 'owner_dashboard.dart';
import 'tenant_home.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  Widget _modeCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      elevation: 8,
      shadowColor: gradient.last.withAlpha(72),
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradient,
            ),
            boxShadow: [
              BoxShadow(
                color: gradient.last.withAlpha(66),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: Colors.white.withAlpha(51),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white),
            ],
          ),
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
    return Scaffold(
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
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    const Text(
                      'Choose Your Mode',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        color: AppPalette.text,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Switch between owner and tenant experiences anytime.',
                      style: TextStyle(
                        color: AppPalette.mutedText,
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 28),
                    _modeCard(
                      context: context,
                      title: 'Owner Mode',
                      subtitle: 'Manage your properties and booking requests',
                      icon: Icons.manage_accounts_rounded,
                      gradient: const [Color(0xFF2563EB), Color(0xFF0C4A9B)],
                      onTap: () {
                        AppState.currentRole = 'owner';
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const OwnerDashboard()),
                        );
                      },
                    ),
                    const SizedBox(height: 18),
                    _modeCard(
                      context: context,
                      title: 'Tenant Mode',
                      subtitle: 'Discover homes and complete bookings quickly',
                      icon: Icons.travel_explore_rounded,
                      gradient: const [Color(0xFF0EA5E9), Color(0xFF0F766E)],
                      onTap: () {
                        AppState.currentRole = 'tenant';
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const TenantHome()),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
