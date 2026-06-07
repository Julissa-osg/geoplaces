import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:geolocator/geolocator.dart';
import '../models/place_model.dart';

class BrujolaPage extends StatefulWidget {
  final Place? destino;
  const BrujolaPage({super.key, this.destino});

  @override
  State<BrujolaPage> createState() => _BrujolaPageState();
}

class _BrujolaPageState extends State<BrujolaPage>
    with SingleTickerProviderStateMixin {
  double _heading = 0.0;
  double _accelX = 0.0;
  double _accelY = 0.0;
  double _accelZ = 0.0;
  double _gyroX = 0.0;
  double _gyroY = 0.0;
  double _gyroZ = 0.0;
  Position? _posicion;
  
  bool _isShaking = false;
  bool _isUpsideDown = false;
  bool _isFaceDown = false;

  StreamSubscription? _magnetoSub;
  StreamSubscription? _accelSub;
  StreamSubscription? _gyroSub;

  late AnimationController _animController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );

    _initSensores();
    _obtenerPosicion();
  }

  Future<void> _obtenerPosicion() async {
    try {
      bool ok = await Geolocator.isLocationServiceEnabled();
      if (!ok) return;
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) return;
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (mounted) setState(() => _posicion = pos);
    } catch (_) {}
  }

  void _initSensores() {
    // Magnetómetro → brújula
    try {
      _magnetoSub = magnetometerEventStream().listen((event) {
        final heading = math.atan2(event.y, event.x) * 180 / math.pi;
        if (mounted) setState(() => _heading = heading);
      });
    } catch (_) {}

    // Acelerómetro
    try {
      _accelSub = accelerometerEventStream().listen((event) {
        if (mounted) {
          final double magnitude = math.sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
          setState(() {
            _accelX = event.x;
            _accelY = event.y;
            _accelZ = event.z;
            
            // Detección de movimiento
            _isShaking = magnitude > 25.0;
            _isUpsideDown = event.y < -7.0;
            _isFaceDown = event.z < -8.0;
          });
        }
      });
    } catch (_) {}

    // Giroscopio
    try {
      _gyroSub = gyroscopeEventStream().listen((event) {
        if (mounted) {
          setState(() {
            _gyroX = event.x;
            _gyroY = event.y;
            _gyroZ = event.z;
          });
        }
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _magnetoSub?.cancel();
    _accelSub?.cancel();
    _gyroSub?.cancel();
    _animController.dispose();
    super.dispose();
  }

  String _direccion(double h) {
    if (h >= -22.5 && h < 22.5) return 'E';
    if (h >= 22.5 && h < 67.5) return 'NE';
    if (h >= 67.5 && h < 112.5) return 'N';
    if (h >= 112.5 && h < 157.5) return 'NO';
    if (h >= 157.5 || h < -157.5) return 'O';
    if (h >= -157.5 && h < -112.5) return 'SO';
    if (h >= -112.5 && h < -67.5) return 'S';
    return 'SE';
  }

  double? _distanciaDestino() {
    if (_posicion == null || widget.destino == null) return null;
    return Geolocator.distanceBetween(
          _posicion!.latitude,
          _posicion!.longitude,
          widget.destino!.latitude,
          widget.destino!.longitude,
        ) /
        1000;
  }

  @override
  Widget build(BuildContext context) {
    final dir = _direccion(_heading);
    final distancia = _distanciaDestino();

    return Scaffold(
      backgroundColor: const Color(0xFF12121E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E2E),
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFF9D4EDD)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.explore, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            const Text(
              'Brújula & Sensores',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ── Brújula ──────────────────────────────────
            ScaleTransition(
              scale: _pulseAnim,
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF1E1E2E),
                      const Color(0xFF12121E),
                    ],
                  ),
                  border: Border.all(
                    color: const Color(0xFF7C3AED).withOpacity(0.5),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7C3AED).withOpacity(0.3),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Marcadores cardinales
                    ..._buildCardinalMarkers(),
                    // Aguja de la brújula
                    Transform.rotate(
                      angle: -_heading * math.pi / 180,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 6,
                            height: 80,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFFEF4444), Color(0xFFFF6B6B)],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(3),
                                topRight: Radius.circular(3),
                              ),
                            ),
                          ),
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: const Color(0xFF7C3AED),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF7C3AED).withOpacity(0.6),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 6,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.3),
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(3),
                                bottomRight: Radius.circular(3),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Ángulo en el centro
                    Positioned(
                      bottom: 60,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7C3AED).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFF7C3AED).withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          '${_heading.toStringAsFixed(1)}°  $dir',
                          style: const TextStyle(
                            color: Color(0xFF7C3AED),
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Destino si viene con lugar ────────────────
            if (widget.destino != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF7C3AED).withOpacity(0.15),
                      const Color(0xFF9D4EDD).withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF7C3AED).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, color: Color(0xFF7C3AED)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Destino: ${widget.destino!.name}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (distancia != null)
                            Text(
                              distancia < 1
                                  ? '${(distancia * 1000).toStringAsFixed(0)} m de distancia'
                                  : '${distancia.toStringAsFixed(2)} km de distancia',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 13,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ── Estado de Movimiento (Feedback Interactivo) ──
            _MotionFeedbackPanel(
              isShaking: _isShaking,
              isUpsideDown: _isUpsideDown,
              isFaceDown: _isFaceDown,
            ),
            const SizedBox(height: 16),

            // ── Acelerómetro ──────────────────────────────
            _SensorCard(
              titulo: 'Acelerómetro',
              icono: Icons.speed,
              color: const Color(0xFF10B981),
              datos: [
                _DatoSensor('X', _accelX, 'm/s²'),
                _DatoSensor('Y', _accelY, 'm/s²'),
                _DatoSensor('Z', _accelZ, 'm/s²'),
              ],
            ),
            const SizedBox(height: 12),

            // ── Giroscopio ────────────────────────────────
            _SensorCard(
              titulo: 'Giroscopio',
              icono: Icons.rotate_90_degrees_ccw,
              color: const Color(0xFFF59E0B),
              datos: [
                _DatoSensor('X', _gyroX, 'rad/s'),
                _DatoSensor('Y', _gyroY, 'rad/s'),
                _DatoSensor('Z', _gyroZ, 'rad/s'),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCardinalMarkers() {
    final labels = {'N': 90.0, 'E': 0.0, 'S': 270.0, 'O': 180.0};
    return labels.entries.map((e) {
      final rad = e.value * math.pi / 180;
      const r = 95.0;
      return Positioned(
        left: 120 + r * math.cos(rad) - 10,
        top: 120 - r * math.sin(rad) - 10,
        child: Text(
          e.key,
          style: TextStyle(
            color: e.key == 'N'
                ? const Color(0xFFEF4444)
                : Colors.white.withOpacity(0.6),
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }).toList();
  }
}

class _DatoSensor {
  final String eje;
  final double valor;
  final String unidad;
  _DatoSensor(this.eje, this.valor, this.unidad);
}

class _SensorCard extends StatelessWidget {
  final String titulo;
  final IconData icono;
  final Color color;
  final List<_DatoSensor> datos;

  const _SensorCard({
    required this.titulo,
    required this.icono,
    required this.color,
    required this.datos,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icono, color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                titulo,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: datos.map((d) {
              return Expanded(
                child: Column(
                  children: [
                    Text(
                      d.eje,
                      style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      d.valor.toStringAsFixed(2),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'monospace',
                      ),
                    ),
                    Text(
                      d.unidad,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _MotionFeedbackPanel extends StatelessWidget {
  final bool isShaking;
  final bool isUpsideDown;
  final bool isFaceDown;

  const _MotionFeedbackPanel({
    required this.isShaking,
    required this.isUpsideDown,
    required this.isFaceDown,
  });

  @override
  Widget build(BuildContext context) {
    Color panelColor = const Color(0xFF1E1E2E);
    Color borderColor = const Color(0xFF7C3AED).withOpacity(0.2);
    String message = 'Movimiento estable';
    IconData icon = Icons.check_circle_outline;
    Color contentColor = Colors.white70;

    if (isShaking) {
      panelColor = const Color(0xFFDC2626).withOpacity(0.2);
      borderColor = const Color(0xFFDC2626);
      message = '¡Cuidado! Estás agitando el dispositivo';
      icon = Icons.warning_amber_rounded;
      contentColor = const Color(0xFFEF4444);
    } else if (isFaceDown) {
      panelColor = const Color(0xFFF59E0B).withOpacity(0.2);
      borderColor = const Color(0xFFF59E0B);
      message = 'Dispositivo boca abajo';
      icon = Icons.screen_rotation_outlined;
      contentColor = const Color(0xFFFBBF24);
    } else if (isUpsideDown) {
      panelColor = const Color(0xFF3B82F6).withOpacity(0.2);
      borderColor = const Color(0xFF3B82F6);
      message = 'Dispositivo de cabeza';
      icon = Icons.swap_vert_rounded;
      contentColor = const Color(0xFF60A5FA);
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: isShaking ? 2 : 1),
        boxShadow: isShaking
            ? [BoxShadow(color: const Color(0xFFDC2626).withOpacity(0.4), blurRadius: 15, spreadRadius: 2)]
            : [],
      ),
      child: Column(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
            child: Icon(icon, key: ValueKey(icon), color: contentColor, size: 36),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: contentColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
