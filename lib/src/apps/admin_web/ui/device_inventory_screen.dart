import 'package:first_protection/core/utils/formatters.dart';
import 'package:first_protection/core/utils/vehicle_data.dart';
import 'package:first_protection/core/widgets/custom_dialog.dart';
import 'package:first_protection/core/services/database_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:first_protection/core/theme/app_colors.dart';

class DeviceInventoryScreen extends StatefulWidget {
  const DeviceInventoryScreen({super.key});

  @override
  State<DeviceInventoryScreen> createState() => _DeviceInventoryScreenState();
}

class _DeviceInventoryScreenState extends State<DeviceInventoryScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final _searchController = TextEditingController();

  final _nombreController = TextEditingController();
  final _rutController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _domicilioController = TextEditingController();

  final _aliasController = TextEditingController();
  final _patenteController = TextEditingController();
  final _marcaController = TextEditingController();
  final _modeloController = TextEditingController();
  final _anioController = TextEditingController();
  final _colorController = TextEditingController();
  final _vinculoController = TextEditingController();
  final _comentarioController = TextEditingController();

  final _nombreEmergenciaController = TextEditingController();
  final _telefonoEmergenciaController = TextEditingController();

  final _fechaInstalacionController = TextEditingController();
  final _ultimoMantenimientoController = TextEditingController();
  String _estadoSuscripcion = "ACTIVO";

  String _filterText = "";

  @override
  void dispose() {
    _searchController.dispose();
    _nombreController.dispose();
    _rutController.dispose();
    _emailController.dispose();
    _telefonoController.dispose();
    _domicilioController.dispose();
    _aliasController.dispose();
    _patenteController.dispose();
    _marcaController.dispose();
    _modeloController.dispose();
    _anioController.dispose();
    _colorController.dispose();
    _vinculoController.dispose();
    _comentarioController.dispose();
    _nombreEmergenciaController.dispose();
    _telefonoEmergenciaController.dispose();
    _fechaInstalacionController.dispose();
    _ultimoMantenimientoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0a0a0a),
      appBar: AppBar(
        backgroundColor: const Color(0xFF141414),
        toolbarHeight: 80,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "GESTIÓN DE INVENTARIO Y CLIENTES",
          style: GoogleFonts.oswald(
            color: Colors.white,
            fontSize: 24,
            letterSpacing: 3,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.primaryOrange,
            size: 28,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          _buildTopBar(),
          Expanded(child: _buildDeviceTable()),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
      color: const Color(0xFF141414),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 60,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha:0.03),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.white10),
              ),
              child: Center(
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _filterText = val),
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                  decoration: InputDecoration(
                    icon: Icon(
                      Icons.search,
                      color: AppColors.primaryOrange,
                      size: 28,
                    ),
                    hintText: "Buscar por ID, Patente, RUT o Nombre...",
                    hintStyle: const TextStyle(
                      color: Colors.white24,
                      fontSize: 18,
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 30),
          ElevatedButton.icon(
            onPressed: () => _openEditModal(null),
            icon: const Icon(Icons.add, size: 24),
            label: const Text(
              "AÑADIR DISPOSITIVO",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryOrange,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 22),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceTable() {
    return StreamBuilder(
      stream: _databaseService.escucharDispositivosAdmin(),
      builder: (context, AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primaryOrange),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) return _buildNoData();

        List<Map<String, dynamic>> items = [];
        for (final map in snapshot.data!) {
          final String searchContent =
              "${map['id']} ${map['patente']} ${map['alias']} ${map['nombrePropietario']}"
                  .toLowerCase();
          if (_filterText.isEmpty ||
              searchContent.contains(_filterText.toLowerCase())) {
            items.add(map);
          }
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(40),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF141414),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white10),
            ),
            child: DataTable(
              headingRowHeight: 70,
              dataRowMinHeight: 85,
              dataRowMaxHeight: 85,
              columns: _buildColumns(),
              rows: items.map((item) => _buildDataRow(item)).toList(),
            ),
          ),
        );
      },
    );
  }

  List<DataColumn> _buildColumns() {
    final style = GoogleFonts.poppins(
      color: AppColors.primaryOrange,
      fontSize: 14,
      fontWeight: FontWeight.bold,
    );
    return [
      DataColumn(label: Text("ID EQUIPO", style: style)),
      DataColumn(label: Text("PATENTE", style: style)),
      DataColumn(label: Text("ALIAS", style: style)),
      DataColumn(label: Text("PROPIETARIO", style: style)),
      DataColumn(label: Text("ESTADO", style: style)),
      DataColumn(label: Text("ACCIONES", style: style)),
    ];
  }

  DataRow _buildDataRow(Map<String, dynamic> item) {
    final estado = item['estadoSuscripcion'] ?? 'ACTIVO';
    final String patenteRaw = item['patente']?.toString() ?? '';
    final String patenteFormateada = ChileanFormatters.formatPatenteVisual(
      patenteRaw,
    );

    return DataRow(
      cells: [
        DataCell(
          Text(
            item['id'] ?? '---',
            style: const TextStyle(color: Colors.white38, fontSize: 14),
          ),
        ),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primaryOrange.withValues(alpha:0.05),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              patenteFormateada,
              style: GoogleFonts.robotoMono(
                color: AppColors.primaryOrange,
                fontWeight: FontWeight.bold,
                fontSize: 16,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ),
        DataCell(
          Text(
            item['alias'] ?? 'Sin Alias',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
              fontSize: 15,
            ),
          ),
        ),
        DataCell(
          Text(
            item['nombrePropietario']?.toString().toUpperCase() ?? 'SIN DATOS',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: estado == "ACTIVO"
                  ? Colors.green.withValues(alpha:0.1)
                  : Colors.orange.withValues(alpha:0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: estado == "ACTIVO"
                    ? Colors.green.withValues(alpha:0.5)
                    : Colors.orange.withValues(alpha:0.5),
              ),
            ),
            child: Text(
              estado,
              style: TextStyle(
                color: estado == "ACTIVO"
                    ? Colors.greenAccent
                    : Colors.orangeAccent,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.edit_note,
                  color: Colors.blueAccent,
                  size: 28,
                ),
                onPressed: () => _openEditModal(item),
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_sweep_rounded,
                  color: Colors.redAccent,
                  size: 24,
                ),
                onPressed: () => _confirmDelete(
                item['id'],
                item['idPropietario']?.toString(),
              ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _openEditModal(Map<String, dynamic>? item) {
    if (item != null) {
      _nombreController.text = item['nombrePropietario'] ?? '';
      _rutController.text = item['rutPropietario'] ?? '';
      _emailController.text = item['emailPropietario'] ?? '';

      String telData = item['telefonoPropietario'] ?? '';
      _telefonoController.text = telData.replaceFirst('+569', '');

      _domicilioController.text = item['domicilioPropietario'] ?? '';
      _aliasController.text = item['alias'] ?? '';
      _patenteController.text = (item['patente'] ?? '').toString().replaceAll(
        '-',
        '',
      );

      _marcaController.text = item['marca'] ?? '';
      _modeloController.text = item['modelo'] ?? '';
      _anioController.text = item['anio'] ?? '';
      _colorController.text = item['color'] ?? '';
      _vinculoController.text = item['vinculoFamiliar'] ?? '';
      _comentarioController.text = item['comentario'] ?? '';
      _nombreEmergenciaController.text = item['nombreEmergencia'] ?? '';
      _telefonoEmergenciaController.text = item['telefonoEmergencia'] ?? '';
      _fechaInstalacionController.text = item['fechaInstalacion'] ?? '';
      _ultimoMantenimientoController.text = item['ultimoMantenimiento'] ?? '';
      _estadoSuscripcion = item['estadoSuscripcion'] ?? 'ACTIVO';
    } else {
      _nombreController.clear();
      _rutController.clear();
      _emailController.clear();
      _telefonoController.clear();
      _domicilioController.clear();
      _aliasController.clear();
      _patenteController.clear();
      _marcaController.clear();
      _modeloController.clear();
      _anioController.clear();
      _colorController.clear();
      _vinculoController.clear();
      _comentarioController.clear();
      _nombreEmergenciaController.clear();
      _telefonoEmergenciaController.clear();
      _fechaInstalacionController.clear();
      _ultimoMantenimientoController.clear();
      _estadoSuscripcion = "ACTIVO";
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF141414),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
            title: _buildModalHeader(item?['id']),
            content: SizedBox(
              width: 1100,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildSectionHeader(Icons.person, "DATOS DEL PROPIETARIO"),
                    Row(
                      children: [
                        Expanded(
                          child: _buildModalField(
                            "Nombre Completo",
                            _nombreController,
                            Icons.badge,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: _buildModalField(
                            "RUT / ID",
                            _rutController,
                            Icons.fingerprint,
                            formatters: [ChileanFormatters.rut],
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: _buildModalField(
                            "Email del Usuario",
                            _emailController,
                            Icons.email,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _buildModalField(
                            "Teléfono Móvil",
                            _telefonoController,
                            Icons.phone_android,
                            placeholder: "12345678",
                            prefix: "+56 9 ",
                            formatters: [ChileanFormatters.telefonoCl],
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          flex: 2,
                          child: _buildModalField(
                            "Domicilio Completo",
                            _domicilioController,
                            Icons.home_work,
                          ),
                        ),
                      ],
                    ),
                    _buildSectionHeader(
                      Icons.directions_car,
                      "DETALLES DEL VEHÍCULO",
                    ),

                    SizedBox(
                      width: 1060,
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildDropdownField(
                              "Marca",
                              _marcaController.text,
                              Icons.apartment,
                              VehicleData.marcas,
                              (nuevaMarca) {
                                setModalState(() {
                                  _marcaController.text = nuevaMarca ?? "";
                                  _modeloController.clear();
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: _buildDropdownField(
                              "Modelo",
                              _modeloController.text,
                              Icons.model_training,
                              VehicleData.modelosPorMarca[_marcaController
                                      .text] ??
                                  [],
                              (nuevoModelo) {
                                setModalState(
                                  () => _modeloController.text =
                                      nuevoModelo ?? "",
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: _buildDropdownField(
                              "Año",
                              _anioController.text,
                              Icons.calendar_today,
                              VehicleData.getAnios(),
                              (val) => setModalState(
                                () => _anioController.text = val ?? "",
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(
                      width: 1060,
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildModalField(
                              "Patente",
                              _patenteController,
                              Icons.credit_card,
                              formatters: [ChileanFormatters.patente],
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: _buildDropdownField(
                              "Color",
                              _colorController.text,
                              Icons.palette,
                              VehicleData.colores,
                              (val) => setModalState(
                                () => _colorController.text = val ?? "",
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: _buildModalField(
                              "Vínculo Familiar",
                              _vinculoController,
                              Icons.family_restroom,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildModalField(
                      "Comentarios / Observaciones",
                      _comentarioController,
                      Icons.notes,
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: Column(
                            children: [
                              _buildSectionHeader(
                                Icons.emergency,
                                "EMERGENCIA",
                              ),
                              _buildModalField(
                                "Nombre Contacto",
                                _nombreEmergenciaController,
                                Icons.contact_phone,
                              ),
                              _buildModalField(
                                "Teléfono Emergencia",
                                _telefonoEmergenciaController,
                                Icons.call,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 40),
                        Expanded(
                          flex: 2,
                          child: Column(
                            children: [
                              _buildSectionHeader(
                                Icons.settings,
                                "CONFIGURACIÓN Y ESTADO",
                              ),
                              _buildModalField(
                                "Fecha Instalación",
                                _fechaInstalacionController,
                                Icons.date_range,
                              ),
                              _buildModalField(
                                "Último Mantenimiento",
                                _ultimoMantenimientoController,
                                Icons.build_circle,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: _buildModalActions(item?['id']),
          );
        },
      ),
    );
  }

  Widget _buildModalHeader(String? id) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              id == null ? "NUEVO REGISTRO" : "EXPEDIENTE: $id",
              style: GoogleFonts.oswald(
                color: AppColors.primaryOrange,
                fontSize: 26,
                letterSpacing: 1.5,
              ),
            ),
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close, color: Colors.white24, size: 30),
            ),
          ],
        ),
        const Divider(color: AppColors.primaryOrange, thickness: 2),
      ],
    );
  }

  List<Widget> _buildModalActions(String? id) {
    return [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text(
          "CANCELAR",
          style: TextStyle(color: Colors.white38, fontSize: 16),
        ),
      ),
      ElevatedButton(
        onPressed: () => _saveData(id),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryOrange,
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
        ),
        child: const Text(
          "GUARDAR REGISTRO",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    ];
  }

  void _saveData(String? id) async {
    final patenteLimpia = _patenteController.text
        .replaceAll('-', '')
        .trim()
        .toUpperCase();
    final telefonoLimpio = _telefonoController.text.trim();

    if (patenteLimpia.length != 6) {
      CustomDialogs.showModernStatus(
        context,
        title: "PATENTE INVÁLIDA",
        message: "Debe tener 6 caracteres (ej: ABCD12).",
        isError: true,
      );
      return;
    }
    if (telefonoLimpio.length != 8) {
      CustomDialogs.showModernStatus(
        context,
        title: "TELÉFONO INCOMPLETO",
        message: "Ingresa los 8 dígitos tras el +56 9.",
        isError: true,
      );
      return;
    }

    final targetId = id ?? patenteLimpia;
    String telefonoParaGuardar = "+569$telefonoLimpio";
    String patenteParaGuardar = ChileanFormatters.formatPatenteVisual(
      patenteLimpia,
    );

    try {
      await _databaseService.guardarDispositivoInventario(
        idDispositivo: targetId,
        data: {
          'nombrePropietario': _nombreController.text.trim(),
          'rutPropietario': _rutController.text.trim(),
          'emailPropietario': _emailController.text.trim(),
          'telefonoPropietario': telefonoParaGuardar,
          'domicilioPropietario': _domicilioController.text.trim(),
          'alias': _aliasController.text.trim(),
          'patente': patenteParaGuardar,
          'marca': _marcaController.text.trim(),
          'modelo': _modeloController.text.trim(),
          'anio': _anioController.text.trim(),
          'color': _colorController.text.trim(),
          'vinculoFamiliar': _vinculoController.text.trim(),
          'comentario': _comentarioController.text.trim(),
          'nombreEmergencia': _nombreEmergenciaController.text.trim(),
          'telefonoEmergencia': _telefonoEmergenciaController.text.trim(),
          'fechaInstalacion': _fechaInstalacionController.text.trim(),
          'ultimoMantenimiento': _ultimoMantenimientoController.text.trim(),
          'estadoSuscripcion': _estadoSuscripcion,
          'organizationId': DatabaseService.defaultOrganizationId,
        },
      );

      if (!mounted) return;
      Navigator.pop(context);
      CustomDialogs.showModernStatus(
        context,
        title: "¡ÉXITO!",
        message: "El vehículo $patenteParaGuardar fue actualizado.",
        isError: false,
      );
    } catch (e) {
      CustomDialogs.showModernStatus(
        context,
        title: "ERROR",
        message: "No se pudo guardar: $e",
        isError: true,
      );
    }
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15, top: 15),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryOrange, size: 22),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white38,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const Expanded(child: Divider(indent: 20, color: Colors.white10)),
        ],
      ),
    );
  }

  Widget _buildModalField(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool enabled = true,
    List<TextInputFormatter>? formatters,
    String? placeholder,
    String? prefix,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        enabled: enabled,
        inputFormatters: formatters,
        keyboardType: prefix != null
            ? TextInputType.number
            : TextInputType.text,
        style: TextStyle(
          color: enabled ? Colors.white : Colors.white24,
          fontSize: 16,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: placeholder,
          hintStyle: const TextStyle(color: Colors.white10),
          prefixText: prefix,
          prefixStyle: const TextStyle(
            color: AppColors.primaryOrange,
            fontWeight: FontWeight.bold,
          ),
          labelStyle: const TextStyle(color: Colors.white24, fontSize: 14),
          prefixIcon: Icon(
            icon,
            color: enabled ? AppColors.primaryOrange : Colors.white12,
            size: 22,
          ),
          filled: true,
          fillColor: Colors.white.withValues(alpha:0.02),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.white10),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: AppColors.primaryOrange,
              width: 2,
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(String id, String? idPropietario) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF141414),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.redAccent),
        ),
        title: Text(
          "¿ELIMINAR DISPOSITIVO?",
          style: GoogleFonts.oswald(color: Colors.redAccent),
        ),
        content: Text(
          "Esta acción borrará permanentemente el registro $id.",
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "CANCELAR",
              style: TextStyle(color: Colors.white38),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              _databaseService.eliminarDispositivo(id, idPropietario: idPropietario);
              Navigator.pop(context);
              CustomDialogs.showModernStatus(
                context,
                title: "ELIMINADO",
                message: "El registro ha sido borrado.",
                isError: false,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text(
              "ELIMINAR",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoData() {
    return const Center(
      child: Text(
        "No hay datos",
        style: TextStyle(color: Colors.white24, fontSize: 18),
      ),
    );
  }

  Widget _buildDropdownField(
    String label,
    String? value,
    IconData icon,
    List<String> items,
    Function(String?) onChanged,
  ) {
    final String? safeValue = items.contains(value) ? value : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: DropdownButtonFormField<String>(
        isExpanded: true,
        value: (safeValue == null || safeValue.isEmpty) ? null : safeValue,
        dropdownColor: const Color(0xFF1a1a1a),
        onChanged: items.isEmpty ? null : onChanged,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        icon: Icon(
          Icons.arrow_drop_down,
          color: items.isEmpty ? Colors.white10 : AppColors.primaryOrange,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white24, fontSize: 14),
          prefixIcon: Icon(
            icon,
            color: items.isEmpty ? Colors.white12 : AppColors.primaryOrange,
            size: 22,
          ),
          filled: true,
          fillColor: Colors.white.withValues(alpha:0.02),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.white10),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.white10),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: AppColors.primaryOrange,
              width: 2,
            ),
          ),
        ),
        items: items.map((String val) {
          return DropdownMenuItem<String>(
            value: val,
            child: Text(
              val,
              style: const TextStyle(color: Colors.white),
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList(),
        hint: items.isEmpty
            ? const Text(
                "Seleccione primero...",
                style: TextStyle(color: Colors.white10, fontSize: 14),
              )
            : null,
      ),
    );
  }
}
