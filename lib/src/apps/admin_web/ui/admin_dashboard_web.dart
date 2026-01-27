// ignore_for_file: deprecated_member_use, unused_field, empty_catches

import 'dart:async';
import 'package:first_protection/src/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:provider/provider.dart';
import '../../../../core/controllers/vehiculo_controller.dart';

class AdminDashboardWeb extends StatefulWidget {
  const AdminDashboardWeb({super.key});

  @override
  State<AdminDashboardWeb> createState() => _AdminDashboardWebState();
}

class _AdminDashboardWebState extends State<AdminDashboardWeb> {
  bool _isSimulating = false;
  Timer? _simulationTimer;
  GoogleMapController? _mapController;
  Map<String, dynamic>? _vehiculoSeleccionado; 

  List<Map<String, dynamic>> _listaVehiculos = [];

  double _currentLat = -36.82699; 
  double _currentLng = -73.04977;

  bool _isFollowing = false;
  Set<Marker> _markers = {};
  StreamSubscription<DatabaseEvent>? _usuariosSubscription;
  
  @override
  void initState() {
    super.initState();
    _escucharUsuarios();
  }

  void _escucharUsuarios() {
    final ref = FirebaseDatabase.instance.ref().child('dispositivos');
    
    _usuariosSubscription = ref.onValue.listen((event) {
      try {
        final data = event.snapshot.value as Map?; 
        if (data == null) {
          if(mounted) setState(() => _listaVehiculos = []);
          return;
        }

        Set<Marker> nuevosMarkers = {};
        List<Map<String, dynamic>> nuevaLista = [];
        
        data.forEach((id, info) {
          if (info is Map) {
            final String deviceId = id.toString(); 
            
            final double? lat = double.tryParse(info['latitud']?.toString() ?? '');
            final double? lng = double.tryParse(info['longitud']?.toString() ?? '');

            final vData = Map<String, dynamic>.from(info);
            vData['id'] = deviceId;
            vData['latitud'] = lat;
            vData['longitud'] = lng;
            
            nuevaLista.add(vData);

            if (lat != null && lng != null) {
              final position = LatLng(lat, lng);

              if (_isFollowing && _vehiculoSeleccionado?['id'] == deviceId) {
                _mapController?.animateCamera(CameraUpdate.newLatLng(position));
              }

              nuevosMarkers.add(
                Marker(
                  markerId: MarkerId(deviceId),
                  position: position,
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                    info['humo'] == true ? BitmapDescriptor.hueRed : BitmapDescriptor.hueOrange
                  ),
                  onTap: () => _seleccionarVehiculo(vData),
                ),
              );
            }
          }
        });

        if (mounted) {
          setState(() {
            _markers = nuevosMarkers;
            _listaVehiculos = nuevaLista;
          });
        }
      } catch (e) {
        debugPrint("Error en Dashboard: $e");
      }
    });
  }

  void _seleccionarVehiculo(Map<String, dynamic> vData) {
    setState(() {
      _vehiculoSeleccionado = vData;
      _isFollowing = true;
    });
    
    if (vData['latitud'] != null && vData['longitud'] != null) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(vData['latitud'], vData['longitud']), 16)
      );
    }
  }

  @override
  void dispose() {
    _usuariosSubscription?.cancel();
    _simulationTimer?.cancel();
    super.dispose();
  }

  static const CameraPosition _kInitialPosition = CameraPosition(
    target: LatLng(-36.82699, -73.04977), 
    zoom: 14.0,
  );

  @override
  Widget build(BuildContext context) {

    Map<String, dynamic>? vehiculoActualizado;
    if (_vehiculoSeleccionado != null) {
      try {
        vehiculoActualizado = _listaVehiculos.firstWhere(
          (v) => v['id'].toString() == _vehiculoSeleccionado!['id'].toString(),
        );
      } catch (e) {
        vehiculoActualizado = _vehiculoSeleccionado;
      }
    }
      
    Provider.of<VehiculoController>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0a0a0a),
      body: Row(
        children: [
          Container(
            width: 320,
            height: double.infinity,
            color: const Color(0xFF141414),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSidebarHeader(),
                
                Expanded(
                  child: _listaVehiculos.isEmpty 
                    ? _buildEmptyState() 
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: _listaVehiculos.length,
                        itemBuilder: (context, index) => _buildPremiumVehicleCard(_listaVehiculos[index]),
                      ),
                ),

                Padding(
                  padding: const EdgeInsets.all(20),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: Stack(
              children: [
                Container(
                  margin: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: GoogleMap(
                      initialCameraPosition: _kInitialPosition,
                      onMapCreated: (controller) => _mapController = controller,
                      markers: _markers, 
                      mapType: MapType.normal,
                      zoomControlsEnabled: false,
                    ),
                  ),
                ),

                if (vehiculoActualizado != null)
                  Positioned(
                    top: 40,
                    right: 40,
                    child: _buildPremiumPanel(vehiculoActualizado), 
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(25, 40, 25, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('FIRST PROTECTION', 
            style: GoogleFonts.oswald(color: AppColors.primaryOrange, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const Text('COMMAND CENTER', 
            style: TextStyle(color: Colors.white24, fontSize: 10, letterSpacing: 2)),
        ],
      ),
    );
  }

  Widget _buildPremiumVehicleCard(Map<String, dynamic> v) {
    final bool estaSeleccionado = _vehiculoSeleccionado?['id'] == v['id'];
    
    final bool humoActivo = v['humo'] == true;
    final bool sirenaActiva = v['protocoloActivo'] == true;
    final bool cortaCorrienteActivo = v['cortaCorriente'] == true;

    return GestureDetector(
      onTap: () => _seleccionarVehiculo(v),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: estaSeleccionado ? AppColors.primaryOrange.withOpacity(0.1) : Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: (humoActivo || sirenaActiva) ? Colors.redAccent : (estaSeleccionado ? AppColors.primaryOrange : Colors.white10),
            width: (humoActivo || sirenaActiva) ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    v['alias'] ?? "Unidad", 
                    style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Row(
                  children: [
                    _statusIcon(Icons.smoke_free, humoActivo, Colors.orange),
                    const SizedBox(width: 8),
                    _statusIcon(Icons.notifications_active, sirenaActiva, Colors.redAccent),
                    const SizedBox(width: 8),
                    _statusIcon(Icons.power_settings_new, cortaCorrienteActivo, Colors.blueAccent),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(v['patente'] ?? "S/P", style: const TextStyle(color: Colors.white38, fontSize: 11)),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.speed, color: AppColors.primaryOrange, size: 12),
                const SizedBox(width: 5),
                Text("${v['velocidad']?.toStringAsFixed(1) ?? '0'} km/h", 
                  style: const TextStyle(color: Colors.white70, fontSize: 11)),
                const Spacer(),
                Text(
                  v['latitud'] != null ? "ONLINE" : "OFFLINE", 
                  style: TextStyle(
                    color: v['latitud'] != null ? Colors.blueAccent : Colors.white24, 
                    fontSize: 9, 
                    fontWeight: FontWeight.bold
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _statusIcon(IconData icon, bool isActive, Color activeColor) {
    return Icon(
      icon,
      size: 16,
      color: isActive ? activeColor : Colors.white10,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.directions_car_filled_outlined, color: Colors.white10, size: 50),
          SizedBox(height: 10),
          Text("Buscando dispositivos...", style: TextStyle(color: Colors.white24)),
        ],
      ),
    );
  }

  Widget _buildPremiumPanel(Map<String, dynamic> info) {
    final String deviceId = info['id'].toString();
  
    final dbRef = FirebaseDatabase.instance.ref().child('dispositivos').child(deviceId);
    
    final bool humo = info['humo'] == true;
    final bool protocolo = info['protocoloActivo'] == true;
    final bool cortaCorriente = info['cortaCorriente'] == true;

    return Container(
      width: 300,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF141414).withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (humo || protocolo) ? Colors.redAccent : AppColors.primaryOrange, 
          width: 1.5
        ),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("MONITOREO EN VIVO", 
                    style: GoogleFonts.oswald(color: AppColors.primaryOrange, fontSize: 10, letterSpacing: 1.5)),
                  Text(info['alias'] ?? "Unidad", 
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white38, size: 20),
                onPressed: () => setState(() {
                  _vehiculoSeleccionado = null;
                  _isFollowing = false;
                }),
              )
            ],
          ),
          const Divider(color: Colors.white10, height: 30),

          Text("ESTADO DE SUBSISTEMAS", 
            style: TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _statusSquare(
                icon: Icons.smoke_free, 
                label: "HUMO", 
                isActive: humo, 
                activeColor: Colors.orange,
                onTap: () => dbRef.update({'humo': !humo}), 
              ),
              _statusSquare(
                icon: Icons.notifications_active, 
                label: "PROTOCOLO", 
                isActive: protocolo, 
                activeColor: Colors.redAccent,
                onTap: () => dbRef.update({'protocoloActivo': !protocolo}),
              ),
              _statusSquare(
                icon: Icons.power_settings_new, 
                label: "CORTE", 
                isActive: cortaCorriente, 
                activeColor: Colors.blueAccent,
                onTap: () => dbRef.update({'cortaCorriente': !cortaCorriente}),
              ),
            ],
          ),

          const SizedBox(height: 25),
          
          _rowDetail(Icons.speed, "VELOCIDAD", "${info['velocidad']?.toStringAsFixed(1) ?? '0'} km/h"),
          const SizedBox(height: 12),
          _rowDetail(Icons.location_on_outlined, "UBICACIÓN", 
            "${info['latitud']?.toStringAsFixed(4) ?? '0'}, ${info['longitud']?.toStringAsFixed(4) ?? '0'}"),
          
          const SizedBox(height: 25),

          SizedBox(
            width: double.infinity,
            height: 45,
            child: ElevatedButton.icon(
              onPressed: () => setState(() => _isFollowing = !_isFollowing),
              icon: Icon(_isFollowing ? Icons.gps_fixed : Icons.gps_not_fixed, size: 16),
              label: Text(_isFollowing ? "SIGUIENDO..." : "RASTREAR UNIDAD", 
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isFollowing ? AppColors.primaryOrange : Colors.white.withOpacity(0.05),
                foregroundColor: _isFollowing ? Colors.black : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusSquare({
    required IconData icon, 
    required String label, 
    required bool isActive, 
    required Color activeColor,
    required VoidCallback onTap, 
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 80,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? activeColor.withOpacity(0.15) : Colors.white.withOpacity(0.02),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? activeColor : Colors.white10,
            width: isActive ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isActive ? activeColor : Colors.white10, size: 20),
            const SizedBox(height: 8),
            Text(
              label, 
              style: TextStyle(
                color: isActive ? activeColor : Colors.white24, 
                fontSize: 8, 
                fontWeight: FontWeight.bold
              )
            ),
          ],
        ),
      ),
    );
  }

  Widget _rowDetail(IconData icon, String label, String value, {Color color = Colors.white}) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primaryOrange, size: 16),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.white38, fontSize: 9)),
            Text(value, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w500)),
          ],
        )
      ],
    );
  }

}