import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:url_launcher/url_launcher.dart';
import '../models/place_model.dart';
import '../services/notification_service.dart';
import '../services/place_service.dart';
import 'brujola_page.dart';

class DetallePlacePage extends StatefulWidget {
  final Place place;
  final Position? miPosicion;

  const DetallePlacePage({
    super.key,
    required this.place,
    this.miPosicion,
  });

  @override
  State<DetallePlacePage> createState() => _DetallePlacePageState();
}

class _DetallePlacePageState extends State<DetallePlacePage> {
  late Place _place;
  Position? _miPos;
  bool _cargandoUbicacion = false;

  @override
  void initState() {
    super.initState();
    _place = widget.place;
    _miPos = widget.miPosicion;
    if (_miPos == null) _obtenerUbicacion();
  }

  Future<void> _obtenerUbicacion() async {
    setState(() => _cargandoUbicacion = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
        if (perm == LocationPermission.denied) return;
      }
      if (perm == LocationPermission.deniedForever) return;
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (mounted) setState(() => _miPos = pos);
    } catch (_) {}
    if (mounted) setState(() => _cargandoUbicacion = false);
  }

  double? _calcularDistancia() {
    if (_miPos == null) return null;
    const R = 6371.0;
    final lat1 = _miPos!.latitude * pi / 180;
    final lat2 = _place.latitude * pi / 180;
    final dLat = (_place.latitude - _miPos!.latitude) * pi / 180;
    final dLon = (_place.longitude - _miPos!.longitude) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  String _formatDistance(double km) {
    if (km < 1) return '${(km * 1000).toStringAsFixed(0)} m';
    return '${km.toStringAsFixed(2)} km';
  }

  // ── Integración con apps externas ──────────────────────
  Future<void> _abrirEnGoogleMaps() async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${_place.latitude},${_place.longitude}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _abrirWhatsApp() async {
    final texto = Uri.encodeComponent(
      '¡Mira este lugar! ${_place.name}\n${_place.description.isNotEmpty ? _place.description + '\n' : ''}📍 https://www.google.com/maps?q=${_place.latitude},${_place.longitude}',
    );
    final uri = Uri.parse('https://wa.me/?text=$texto');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _mostrarSnack('WhatsApp no está instalado', false);
    }
  }

  Future<void> _llamar() async {
    // Número de ejemplo - en una app real el usuario lo ingresaría
    final uri = Uri.parse('tel:+593000000000');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      _mostrarSnack('No se puede realizar la llamada', false);
    }
  }

  Future<void> _abrirNavegador() async {
    final uri = Uri.parse(
      'https://es.wikipedia.org/wiki/${Uri.encodeComponent(_place.name)}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<File?> _seleccionarImagen() async {
    final picker = ImagePicker();
    File? imageFile;

    await showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.white24, borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Cambiar imagen',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _BtnFuente(
                    icon: Icons.camera_alt_rounded,
                    label: 'Cámara',
                    color: const Color(0xFF7C3AED),
                    onTap: () async {
                      Navigator.pop(ctx);
                      final p = await picker.pickImage(source: ImageSource.camera, imageQuality: 80);
                      if (p != null) imageFile = File(p.path);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _BtnFuente(
                    icon: Icons.photo_library_rounded,
                    label: 'Galería',
                    color: const Color(0xFF10B981),
                    onTap: () async {
                      Navigator.pop(ctx);
                      final p = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
                      if (p != null) imageFile = File(p.path);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    return imageFile;
  }

  void _mostrarSnack(String msg, bool ok) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(ok ? Icons.check_circle_outline : Icons.error_outline,
            color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(msg)),
      ]),
      backgroundColor: ok ? const Color(0xFF7C3AED) : const Color(0xFFDC2626),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  void _mostrarModalEdicion() {
    final nameCtrl = TextEditingController(text: _place.name);
    final descCtrl = TextEditingController(text: _place.description);
    File? nuevaImagen;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Editar lugar',
                    style: TextStyle(
                        color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),

                // Preview de imagen actual / nueva
                GestureDetector(
                  onTap: () async {
                    final f = await _seleccionarImagen();
                    if (f != null) setModal(() => nuevaImagen = f);
                  },
                  child: Container(
                    width: double.infinity,
                    height: 120,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A3E),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: nuevaImagen != null
                            ? const Color(0xFF7C3AED)
                            : Colors.white.withOpacity(0.1),
                      ),
                    ),
                    child: nuevaImagen != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(11),
                            child: Image.file(nuevaImagen!, fit: BoxFit.cover))
                        : _place.imageUrl != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(11),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.network(_place.imageUrl!, fit: BoxFit.cover),
                                    Container(
                                      color: Colors.black45,
                                      child: const Center(
                                        child: Text('Toca para cambiar',
                                            style: TextStyle(color: Colors.white70)),
                                      ),
                                    ),
                                  ],
                                ))
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_a_photo_rounded,
                                      color: Colors.white.withOpacity(0.4), size: 28),
                                  const SizedBox(height: 6),
                                  Text('Agregar foto',
                                      style: TextStyle(
                                          color: Colors.white.withOpacity(0.4), fontSize: 13)),
                                ],
                              ),
                  ),
                ),
                const SizedBox(height: 14),

                TextField(
                  controller: nameCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Nombre del lugar',
                    labelStyle: const TextStyle(color: Colors.white60),
                    filled: true,
                    fillColor: const Color(0xFF2A2A3E),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                    prefixIcon: const Icon(Icons.edit_location_alt,
                        color: Color(0xFF7C3AED)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Descripción',
                    labelStyle: const TextStyle(color: Colors.white60),
                    filled: true,
                    fillColor: const Color(0xFF2A2A3E),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                    prefixIcon:
                        const Icon(Icons.notes, color: Color(0xFF7C3AED)),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      if (nameCtrl.text.trim().isEmpty) return;
                      final actualizado = await PlaceService.updatePlace(
                        id: _place.id,
                        name: nameCtrl.text.trim(),
                        description: descCtrl.text.trim(),
                        latitude: _place.latitude,
                        longitude: _place.longitude,
                        imageFile: nuevaImagen,
                      );
                      if (actualizado != null && ctx.mounted) {
                        Navigator.pop(ctx);
                        setState(() => _place = actualizado);
                        await NotificationService.mostrarLugarActualizado(
                            actualizado.name);
                        if (mounted) _mostrarSnack('Lugar actualizado ✓', true);
                      }
                    },
                    icon: const Icon(Icons.save_rounded),
                    label: const Text('Guardar cambios'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C3AED),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final distancia = _calcularDistancia();
    final placeLatLng = LatLng(_place.latitude, _place.longitude);

    return Scaffold(
      backgroundColor: const Color(0xFF12121E),
      body: CustomScrollView(
        slivers: [
          // ── AppBar con mapa ──────────────────────────────
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: const Color(0xFF1E1E2E),
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E2E).withOpacity(0.8),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back, color: Colors.white, size: 18),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E2E).withOpacity(0.8),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.edit_outlined,
                      color: Color(0xFF7C3AED), size: 18),
                ),
                onPressed: _mostrarModalEdicion,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: ClipRect(
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: placeLatLng,
                    initialZoom: 15,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.none,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.flutter.laravel',
                    ),
                    if (_miPos != null)
                      MarkerLayer(markers: [
                        Marker(
                          point: LatLng(_miPos!.latitude, _miPos!.longitude),
                          width: 40, height: 40,
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF3B82F6).withOpacity(0.25),
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFF3B82F6), width: 2),
                            ),
                            child: Center(
                              child: Container(
                                width: 12, height: 12,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF3B82F6), shape: BoxShape.circle),
                              ),
                            ),
                          ),
                        ),
                      ]),
                    MarkerLayer(markers: [
                      Marker(
                        point: placeLatLng,
                        width: 48, height: 48,
                        child: const Icon(Icons.location_on,
                            color: Color(0xFF7C3AED), size: 48),
                      ),
                    ]),
                    if (_miPos != null)
                      PolylineLayer(
                        polylines: <Polyline<Object>>[
                          Polyline<Object>(
                            points: [
                              LatLng(_miPos!.latitude, _miPos!.longitude),
                              placeLatLng,
                            ],
                            color: const Color(0xFF7C3AED).withOpacity(0.6),
                            strokeWidth: 2,
                            pattern: StrokePattern.dotted(),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Imagen del lugar ───────────────────
                  if (_place.imageUrl != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        _place.imageUrl!,
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 200,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E2E),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Center(
                            child: Icon(Icons.image_not_supported,
                                color: Colors.white24, size: 48),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // ── Nombre y descripción ───────────────
                  Text(
                    _place.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_place.description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      _place.description,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 15,
                        height: 1.5,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),

                  // ── Info Cards ─────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: _InfoCard(
                          icon: Icons.explore,
                          label: 'Distancia',
                          value: _cargandoUbicacion
                              ? 'Calculando...'
                              : distancia != null
                                  ? _formatDistance(distancia)
                                  : 'Sin GPS',
                          color: const Color(0xFF7C3AED),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _InfoCard(
                          icon: Icons.gps_fixed,
                          label: 'Latitud',
                          value: _place.latitude.toStringAsFixed(5),
                          color: const Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _InfoCard(
                          icon: Icons.gps_not_fixed,
                          label: 'Longitud',
                          value: _place.longitude.toStringAsFixed(5),
                          color: const Color(0xFF10B981),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _InfoCard(
                          icon: Icons.tag,
                          label: 'ID del lugar',
                          value: '#${_place.id}',
                          color: const Color(0xFFF59E0B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ── Coordenadas completas ──────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E2E),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: const Color(0xFF7C3AED).withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Coordenadas completas',
                            style: TextStyle(
                                color: Colors.white60,
                                fontSize: 12,
                                letterSpacing: 1)),
                        const SizedBox(height: 8),
                        Text(
                          '${_place.latitude.toStringAsFixed(7)}, ${_place.longitude.toStringAsFixed(7)}',
                          style: const TextStyle(
                            color: Color(0xFF7C3AED),
                            fontSize: 14,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Acciones externas ──────────────────
                  const Text(
                    'Acciones',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Google Maps
                  _AccionBtn(
                    icon: Icons.map_rounded,
                    label: 'Abrir en Google Maps',
                    color: const Color(0xFF7C3AED),
                    onTap: _abrirEnGoogleMaps,
                  ),
                  const SizedBox(height: 10),

                  // WhatsApp
                  _AccionBtn(
                    icon: Icons.chat_rounded,
                    label: 'Compartir por WhatsApp',
                    color: const Color(0xFF25D366),
                    onTap: _abrirWhatsApp,
                  ),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child: _AccionBtn(
                          icon: Icons.phone_rounded,
                          label: 'Llamar',
                          color: const Color(0xFF3B82F6),
                          onTap: _llamar,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _AccionBtn(
                          icon: Icons.language_rounded,
                          label: 'Buscar web',
                          color: const Color(0xFFF59E0B),
                          onTap: _abrirNavegador,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Brújula
                  _AccionBtn(
                    icon: Icons.explore_rounded,
                    label: 'Abrir brújula → este lugar',
                    color: const Color(0xFFEC4899),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BrujolaPage(destino: _place),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Editar
                  OutlinedButton.icon(
                    onPressed: _mostrarModalEdicion,
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Editar lugar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF7C3AED),
                      side: const BorderSide(color: Color(0xFF7C3AED)),
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 16),
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Botón de fuente de imagen ─────────────────────────
class _BtnFuente extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _BtnFuente(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 8),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

// ── Botón de acción externa ───────────────────────────
class _AccionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _AccionBtn(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.white.withOpacity(0.3), size: 14),
          ],
        ),
      ),
    );
  }
}

// ── Info Card ─────────────────────────────────────────
class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _InfoCard(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(label,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 11,
                  letterSpacing: 0.5)),
          const SizedBox(height: 2),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
