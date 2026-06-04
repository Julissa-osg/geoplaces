import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import 'brujola_page.dart';
import 'login_page.dart';
import 'places_page.dart';
import 'mapa_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    NotificationService.initialize();
  }

  Future<void> _logout() async {
    await ApiService.logout();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }
  }

  static const List<String> _titles = ['Inicio', 'Mis Lugares', 'Mapa', 'Brújula'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF12121E),
      appBar: _currentIndex == 2
          ? null
          : AppBar(
              backgroundColor: const Color(0xFF1E1E2E),
              elevation: 0,
              title: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7C3AED), Color(0xFF9D4EDD)],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _titles[_currentIndex],
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout_rounded, color: Colors.white70),
                  tooltip: 'Cerrar sesión',
                ),
              ],
            ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _InicioScreen(onNavigate: (i) => setState(() => _currentIndex = i)),
          const PlacesPage(),
          const MapaPage(),
          const BrujolaPage(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E2E),
          border: Border(
            top: BorderSide(
              color: const Color(0xFF7C3AED).withOpacity(0.25),
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: const Color(0xFF7C3AED),
          unselectedItemColor: Colors.white38,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Inicio',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.location_on_outlined),
              activeIcon: Icon(Icons.location_on),
              label: 'Mis Lugares',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.map_outlined),
              activeIcon: Icon(Icons.map),
              label: 'Mapa',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.explore_outlined),
              activeIcon: Icon(Icons.explore),
              label: 'Brújula',
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Pantalla de Inicio
// ─────────────────────────────────────────────
class _InicioScreen extends StatefulWidget {
  final void Function(int index) onNavigate;
  const _InicioScreen({required this.onNavigate});

  @override
  State<_InicioScreen> createState() => _InicioScreenState();
}

class _InicioScreenState extends State<_InicioScreen> {
  Map<String, dynamic>? user;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final data = await ApiService.getUser();
    if (mounted) setState(() { user = data; loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF7C3AED)),
      );
    }

    final name = user?['name'] ?? 'Usuario';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 16),

          // Avatar + bienvenida
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFF9D4EDD)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(Icons.location_on, color: Colors.white, size: 36),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Hola, $name 👋',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Bienvenido a GeoPlaces',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.45),
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Accesos rápidos
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Acceso rápido',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _QuickCard(
                  icon: Icons.location_on,
                  title: 'Mis Lugares',
                  subtitle: 'Ver y gestionar',
                  color: const Color(0xFF7C3AED),
                  onTap: () => widget.onNavigate(1),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickCard(
                  icon: Icons.map_outlined,
                  title: 'Mapa',
                  subtitle: 'Ver en el mapa',
                  color: const Color(0xFF10B981),
                  onTap: () => widget.onNavigate(2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _QuickCard(
                  icon: Icons.explore,
                  title: 'Brújula',
                  subtitle: 'Sensores activos',
                  color: const Color(0xFFEC4899),
                  onTap: () => widget.onNavigate(3),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickCard(
                  icon: Icons.add_location_alt,
                  title: 'Nuevo Lugar',
                  subtitle: 'Marcar posición',
                  color: const Color(0xFFF59E0B),
                  onTap: () => widget.onNavigate(1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Instrucciones
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E2E),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF7C3AED).withOpacity(0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.info_outline, color: Color(0xFF7C3AED), size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Cómo usar GeoPlaces',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _StepRow(
                  step: '1',
                  icon: Icons.add_location_alt,
                  color: const Color(0xFF7C3AED),
                  title: 'Guarda un lugar',
                  text: 'Ve a "Mis Lugares", toca el botón morado y agrega foto, nombre y descripción.',
                ),
                const SizedBox(height: 16),
                _StepRow(
                  step: '2',
                  icon: Icons.touch_app_outlined,
                  color: const Color(0xFF3B82F6),
                  title: 'Explora el detalle',
                  text: 'Toca una tarjeta para ver mapa, distancia, imagen y acciones externas.',
                ),
                const SizedBox(height: 16),
                _StepRow(
                  step: '3',
                  icon: Icons.share_rounded,
                  color: const Color(0xFF25D366),
                  title: 'Comparte y conecta',
                  text: 'Abre WhatsApp, Google Maps, llama o busca en la web directamente.',
                ),
                const SizedBox(height: 16),
                _StepRow(
                  step: '4',
                  icon: Icons.explore,
                  color: const Color(0xFFEC4899),
                  title: 'Usa la brújula',
                  text: 'La pestaña Brújula muestra acelerómetro, giroscopio y dirección en tiempo real.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Center(
            child: Text(
              'GeoPlaces • Flutter + Laravel',
              style: TextStyle(
                color: Colors.white.withOpacity(0.2),
                fontSize: 12,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
class _QuickCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _QuickCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E2E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withOpacity(0.45),
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('Ir ahora',
                    style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
                const SizedBox(width: 4),
                Icon(Icons.arrow_forward_rounded, color: color, size: 12),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
class _StepRow extends StatelessWidget {
  final String step;
  final IconData icon;
  final Color color;
  final String title;
  final String text;

  const _StepRow({
    required this.step,
    required this.icon,
    required this.color,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(step,
                style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 15),
                  const SizedBox(width: 6),
                  Text(title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 4),
              Text(text,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.55),
                      fontSize: 12,
                      height: 1.5)),
            ],
          ),
        ),
      ],
    );
  }
}
