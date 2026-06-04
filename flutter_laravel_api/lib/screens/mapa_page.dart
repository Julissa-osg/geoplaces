import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
// ✅ FIX: Se oculta 'Path' de latlong2 para evitar conflicto con dart:ui Path
import 'package:latlong2/latlong.dart' hide Path;
import '../models/place_model.dart';
import '../services/place_service.dart';
import 'detalle_place_page.dart';

class MapaPage extends StatefulWidget {
  const MapaPage({super.key});

  @override
  State<MapaPage> createState() => _MapaPageState();
}

class _MapaPageState extends State<MapaPage> {
  final MapController _mapController = MapController();
  List<Place> _places = [];
  Position? _miPosicion;
  bool _loading = true;
  bool _centrandose = false;

  @override
  void initState() {
    super.initState();
    _inicializar();
  }

  Future<void> _inicializar() async {
    await Future.wait([_cargarPlaces(), _obtenerMiUbicacion()]);
    setState(() => _loading = false);
  }

  Future<void> _cargarPlaces() async {
    final data = await PlaceService.getPlaces();
    if (mounted) setState(() => _places = data);
  }

  Future<void> _obtenerMiUbicacion() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (mounted) setState(() => _miPosicion = pos);
    } catch (_) {}
  }

  void _centrarEnMiUbicacion() async {
    setState(() => _centrandose = true);
    await _obtenerMiUbicacion();
    if (_miPosicion != null) {
      _mapController.move(
        LatLng(_miPosicion!.latitude, _miPosicion!.longitude),
        15,
      );
    }
    if (mounted) setState(() => _centrandose = false);
  }

  LatLng _centroInicial() {
    if (_miPosicion != null) {
      return LatLng(_miPosicion!.latitude, _miPosicion!.longitude);
    }
    if (_places.isNotEmpty) {
      return LatLng(_places.first.latitude, _places.first.longitude);
    }
    return const LatLng(-1.8312, -78.1834);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF7C3AED)),
      );
    }

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _centroInicial(),
            initialZoom: _miPosicion != null ? 14 : 6,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.flutter.laravel',
            ),

            if (_miPosicion != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(
                      _miPosicion!.latitude,
                      _miPosicion!.longitude,
                    ),
                    width: 60,
                    height: 60,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF3B82F6),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: const BoxDecoration(
                            color: Color(0xFF3B82F6),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

            MarkerLayer(
              markers: _places.map((place) {
                return Marker(
                  point: LatLng(place.latitude, place.longitude),
                  width: 50,
                  height: 60,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DetallePlacePage(
                            place: place,
                            miPosicion: _miPosicion,
                          ),
                        ),
                      ).then((_) => _cargarPlaces());
                    },
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF7C3AED),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            place.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        CustomPaint(
                          size: const Size(12, 8),
                          painter: _TrianglePainter(
                            color: const Color(0xFF7C3AED),
                          ),
                        ),
                        const Icon(
                          Icons.location_on,
                          color: Color(0xFF7C3AED),
                          size: 32,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),

        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E2E).withOpacity(0.92),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF7C3AED).withOpacity(0.3),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.map_outlined,
                  color: Color(0xFF7C3AED),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  '${_places.length} ${_places.length == 1 ? 'lugar guardado' : 'lugares guardados'}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (_miPosicion != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF3B82F6),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'GPS activo',
                          style: TextStyle(
                            color: Color(0xFF3B82F6),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),

        Positioned(
          bottom: 24,
          right: 16,
          child: Column(
            children: [
              FloatingActionButton(
                heroTag: 'center_btn',
                mini: true,
                backgroundColor: const Color(0xFF1E1E2E),
                onPressed: _centrandose ? null : _centrarEnMiUbicacion,
                child: _centrandose
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Color(0xFF7C3AED),
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(
                        Icons.my_location,
                        color: Color(0xFF7C3AED),
                        size: 20,
                      ),
              ),
              const SizedBox(height: 8),
              FloatingActionButton(
                heroTag: 'reload_btn',
                mini: true,
                backgroundColor: const Color(0xFF1E1E2E),
                onPressed: _cargarPlaces,
                child: const Icon(
                  Icons.refresh,
                  color: Color(0xFF7C3AED),
                  size: 20,
                ),
              ),
            ],
          ),
        ),

        Positioned(
          bottom: 24,
          left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E2E).withOpacity(0.9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF7C3AED).withOpacity(0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _LegendItem(
                  color: const Color(0xFF7C3AED),
                  label: 'Mis lugares',
                  icon: Icons.location_on,
                ),
                const SizedBox(height: 4),
                _LegendItem(
                  color: const Color(0xFF3B82F6),
                  label: 'Yo estoy aquí',
                  icon: Icons.person_pin_circle,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final IconData icon;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;
  const _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    // ✅ FIX: Ahora usa dart:ui Path correctamente (latlong2 Path está oculto)
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
