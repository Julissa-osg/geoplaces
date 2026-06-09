import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import '../models/place_model.dart';
import '../services/notification_service.dart';
import '../services/place_service.dart';
import '../services/firestore_service.dart';
import 'detalle_place_page.dart';

class PlacesPage extends StatefulWidget {
  const PlacesPage({super.key});

  @override
  State<PlacesPage> createState() => _PlacesPageState();
}

class _PlacesPageState extends State<PlacesPage> {
  List<Place> places = [];
  bool loading = true;
  Position? _miPosicion;

  @override
  void initState() {
    super.initState();
    _cargarPlaces();
    _obtenerMiUbicacionSilenciosa();
  }

  Future<void> _obtenerMiUbicacionSilenciosa() async {
    try {
      bool ok = await Geolocator.isLocationServiceEnabled();
      if (!ok) return;
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
        if (perm == LocationPermission.denied) return;
      }
      if (perm == LocationPermission.deniedForever) return;
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (mounted) setState(() => _miPosicion = pos);
    } catch (_) {}
  }

  Future<void> _cargarPlaces() async {
    setState(() => loading = true);
    final data = await PlaceService.getPlaces();
    setState(() {
      places = data;
      loading = false;
    });
  }

  Future<void> _eliminarPlace(Place place) async {
    final ok = await PlaceService.deletePlace(place.id);
    if (ok) {
      await FirestoreService.deletePlace(place.id);
      setState(() => places.removeWhere((p) => p.id == place.id));
      await NotificationService.mostrarLugarEliminado(place.name);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lugar "${place.name}" eliminado'),
            backgroundColor: const Color(0xFF4CAF50),
          ),
        );
      }
    }
  }

  Future<void> _mostrarFormulario({Position? posActual}) async {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    double? lat = posActual?.latitude;
    double? lng = posActual?.longitude;
    File? imagenSeleccionada;
    final picker = ImagePicker();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          // ── Selector de imagen CORREGIDO ──
          Future<void> seleccionarImagen() async {
            ImageSource? source;

            // Usamos context del Scaffold (no ctx) para evitar
            // que Flutter cierre ambos sheets al mismo tiempo
            await showModalBottomSheet(
              context: context,
              backgroundColor: const Color(0xFF1E1E2E),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              builder: (innerCtx) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Seleccionar imagen',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _OpcionImagen(
                            icon: Icons.camera_alt_rounded,
                            label: 'Cámara',
                            color: const Color(0xFF7C3AED),
                            onTap: () {
                              source = ImageSource.camera; // solo guarda la fuente
                              Navigator.pop(innerCtx);     // cierra solo este sheet
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _OpcionImagen(
                            icon: Icons.photo_library_rounded,
                            label: 'Galería',
                            color: const Color(0xFF10B981),
                            onTap: () {
                              source = ImageSource.gallery; // solo guarda la fuente
                              Navigator.pop(innerCtx);      // cierra solo este sheet
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            );

            // El sheet ya cerró completamente antes de llegar aquí
            if (source == null) return;

            final picked = await picker.pickImage(
              source: source!,
              imageQuality: 80,
            );

            if (picked != null) {
              print('IMAGEN SELECCIONADA: ${picked.path}');
              setModalState(() => imagenSeleccionada = File(picked.path));
            }
          }

          return Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Guardar nuevo lugar',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Coordenadas
                  if (lat != null && lng != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7C3AED).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: const Color(0xFF7C3AED).withOpacity(0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on,
                              color: Color(0xFF7C3AED), size: 16),
                          const SizedBox(width: 8),
                          Text(
                            '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 14),

                  // Selector de imagen
                  GestureDetector(
                    onTap: seleccionarImagen,
                    child: Container(
                      width: double.infinity,
                      height: 130,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A2A3E),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: imagenSeleccionada != null
                              ? const Color(0xFF7C3AED)
                              : Colors.white.withOpacity(0.1),
                          width: imagenSeleccionada != null ? 2 : 1,
                        ),
                      ),
                      child: imagenSeleccionada != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(11),
                              child: Image.file(
                                imagenSeleccionada!,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_a_photo_rounded,
                                  color: Colors.white.withOpacity(0.4),
                                  size: 32,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Toca para agregar foto',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.4),
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  'Cámara o galería',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.25),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Nombre
                  TextField(
                    controller: nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Nombre del lugar',
                      labelStyle: const TextStyle(color: Colors.white60),
                      filled: true,
                      fillColor: const Color(0xFF2A2A3E),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon:
                          const Icon(Icons.place, color: Color(0xFF7C3AED)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Descripción
                  TextField(
                    controller: descController,
                    style: const TextStyle(color: Colors.white),
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Descripción (opcional)',
                      labelStyle: const TextStyle(color: Colors.white60),
                      filled: true,
                      fillColor: const Color(0xFF2A2A3E),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(Icons.description,
                          color: Color(0xFF7C3AED)),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Botón guardar
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        if (nameController.text.trim().isEmpty) return;
                        if (lat == null || lng == null) return;
                        final nuevo = await PlaceService.createPlace(
                          name: nameController.text.trim(),
                          description: descController.text.trim(),
                          latitude: lat!,
                          longitude: lng!,
                          imageFile: imagenSeleccionada,
                        );
                        if (nuevo != null && ctx.mounted) {
                          await FirestoreService.savePlace(
                            id: nuevo.id,
                            name: nuevo.name,
                            description: nuevo.description,
                            latitude: nuevo.latitude,
                            longitude: nuevo.longitude,
                            imageUrl: nuevo.imageUrl,
                            userId: nuevo.userId,
                          );
                          Navigator.pop(ctx);
                          await NotificationService.mostrarLugarGuardado(nuevo.name);
                          await _cargarPlaces();
                        }
                      },
                      icon: const Icon(Icons.save),
                      label: const Text('Guardar lugar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C3AED),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _obtenerUbicacionYGuardar() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Activa el GPS para continuar'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Permiso de ubicación denegado'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) return;

    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    if (mounted) await _mostrarFormulario(posActual: pos);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF12121E),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF7C3AED)),
            )
          : places.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.location_off,
                          size: 80, color: Colors.white.withOpacity(0.2)),
                      const SizedBox(height: 16),
                      Text(
                        'No tienes lugares guardados',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Toca el botón + para agregar tu ubicación actual',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.3),
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _cargarPlaces,
                  color: const Color(0xFF7C3AED),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: places.length,
                    itemBuilder: (ctx, i) {
                      final place = places[i];
                      return _PlaceCard(
                        place: place,
                        miPosicion: _miPosicion,
                        onDelete: () => _eliminarPlace(place),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DetallePlacePage(
                                place: place,
                                miPosicion: _miPosicion,
                              ),
                            ),
                          );
                          _cargarPlaces();
                        },
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _obtenerUbicacionYGuardar,
        backgroundColor: const Color(0xFF7C3AED),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_location_alt),
        label: const Text('Marcar aquí'),
      ),
    );
  }
}

// ── Widget para seleccionar fuente de imagen ─────────
class _OpcionImagen extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _OpcionImagen({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tarjeta de lugar ─────────────────────────────────
class _PlaceCard extends StatelessWidget {
  final Place place;
  final Position? miPosicion;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const _PlaceCard({
    required this.place,
    required this.miPosicion,
    required this.onDelete,
    required this.onTap,
  });

  double? _distancia() {
    if (miPosicion == null) return null;
    return Geolocator.distanceBetween(
          miPosicion!.latitude,
          miPosicion!.longitude,
          place.latitude,
          place.longitude,
        ) /
        1000;
  }

  String _formatDist(double km) {
    if (km < 1) return '${(km * 1000).toStringAsFixed(0)} m';
    return '${km.toStringAsFixed(1)} km';
  }

  @override
  Widget build(BuildContext context) {
    final dist = _distancia();
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1E1E2E), Color(0xFF2A2A3E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF7C3AED).withOpacity(0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7C3AED).withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen si existe
            if (place.imageUrl != null)
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(15)),
                child: Image.network(
                  place.imageUrl!,
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 140,
                    color: const Color(0xFF2A2A3E),
                    child: const Icon(Icons.image_not_supported,
                        color: Colors.white24, size: 40),
                  ),
                ),
              ),
            ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFF9D4EDD)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.location_on,
                    color: Colors.white, size: 24),
              ),
              title: Text(
                place.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (place.description.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        place.description,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.my_location,
                          size: 12,
                          color: const Color(0xFF7C3AED).withOpacity(0.8)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${place.latitude.toStringAsFixed(5)}, ${place.longitude.toStringAsFixed(5)}',
                          style: TextStyle(
                            color: const Color(0xFF7C3AED).withOpacity(0.8),
                            fontSize: 11,
                            fontFamily: 'monospace',
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (dist != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF7C3AED).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _formatDist(dist),
                            style: const TextStyle(
                              color: Color(0xFF7C3AED),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: const Color(0xFF1E1E2E),
                      title: const Text('Eliminar lugar',
                          style: TextStyle(color: Colors.white)),
                      content: Text(
                        '¿Eliminar "${place.name}"?',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancelar',
                              style: TextStyle(color: Colors.white60)),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            onDelete();
                          },
                          child: const Text('Eliminar',
                              style: TextStyle(color: Colors.redAccent)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}