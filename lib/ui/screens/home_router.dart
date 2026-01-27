import 'package:first_protection/src/apps/client_mobile/ui/home/client_home_screen.dart';
import 'package:first_protection/ui/screens/client/no_device_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/controllers/vehiculo_controller.dart';
import 'package:provider/provider.dart';

class HomeRouter extends StatefulWidget {
  const HomeRouter({super.key});

  @override
  State<HomeRouter> createState() => _HomeRouterState();
}

class _HomeRouterState extends State<HomeRouter> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        Provider.of<VehiculoController>(
          context,
          listen: false,
        ).cargarFlota(user.uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final vCtrl = Provider.of<VehiculoController>(context);

    if (vCtrl.cargando) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.orange)),
      );
    }

    if (!vCtrl.tieneVehiculos) {
      return const NoDeviceScreen();
    }

    return const ClientHomeScreen();
  }
}
