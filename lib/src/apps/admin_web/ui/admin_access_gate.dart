import 'package:firebase_auth/firebase_auth.dart';
import 'package:first_protection/src/apps/admin_web/ui/admin_dashboard_web.dart';
import 'package:first_protection/src/apps/admin_web/ui/admin_web_login_screen.dart';
import 'package:first_protection/core/services/auth_service.dart';
import 'package:first_protection/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class AdminAccessGate extends StatefulWidget {
  const AdminAccessGate({super.key});

  @override
  State<AdminAccessGate> createState() => _AdminAccessGateState();
}

class _AdminAccessGateState extends State<AdminAccessGate> {
  final AuthService _authService = AuthService();
  String? _checkedUid;
  Future<bool>? _accessFuture;

  Future<bool> _canAccessAdmin(String uid) {
    if (_checkedUid != uid || _accessFuture == null) {
      _checkedUid = uid;
      _accessFuture = _authService.currentProfile().then(
        (profile) => profile?.canAccessAdmin ?? false,
      );
    }
    return _accessFuture!;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _AdminLoadingScreen();
        }

        final user = snapshot.data;
        if (user == null) return const AdminLoginScreen();

        return FutureBuilder<bool>(
          future: _canAccessAdmin(user.uid),
          builder: (context, roleSnapshot) {
            if (roleSnapshot.connectionState == ConnectionState.waiting) {
              return const _AdminLoadingScreen();
            }

            if (roleSnapshot.data == true) {
              return const AdminDashboardWeb();
            }

            FirebaseAuth.instance.signOut();
            return const AdminLoginScreen(
              initialError:
                  'Tu cuenta no tiene permisos para acceder al panel administrativo',
            );
          },
        );
      },
    );
  }
}

class _AdminLoadingScreen extends StatelessWidget {
  const _AdminLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.backgroundBlack,
      body: Center(
        child: CircularProgressIndicator(color: AppColors.primaryOrange),
      ),
    );
  }
}
