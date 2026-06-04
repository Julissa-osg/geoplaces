import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  static Future<void> initialize() async {
    if (kIsWeb) return; // No soportado en Web
    if (_initialized) return;

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );

    await _plugin.initialize(settings);
    _initialized = true;
  }

  // Notificación: lugar guardado
  static Future<void> mostrarLugarGuardado(String nombre) async {
    if (kIsWeb) return;
    await initialize();
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'lugares_channel',
      'Lugares Guardados',
      channelDescription: 'Notificaciones al guardar lugares',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails details =
        NotificationDetails(android: androidDetails);

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      '📍 Lugar guardado',
      '"$nombre" fue añadido a tus lugares',
      details,
    );
  }

  // Notificación: lugar eliminado
  static Future<void> mostrarLugarEliminado(String nombre) async {
    if (kIsWeb) return;
    await initialize();
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'lugares_channel',
      'Lugares Guardados',
      channelDescription: 'Notificaciones al guardar lugares',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails details =
        NotificationDetails(android: androidDetails);

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      '🗑️ Lugar eliminado',
      '"$nombre" fue eliminado de tus lugares',
      details,
    );
  }

  // Notificación: lugar actualizado
  static Future<void> mostrarLugarActualizado(String nombre) async {
    if (kIsWeb) return;
    await initialize();
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'lugares_channel',
      'Lugares Guardados',
      channelDescription: 'Notificaciones al guardar lugares',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails details =
        NotificationDetails(android: androidDetails);

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      '✏️ Lugar actualizado',
      '"$nombre" fue actualizado correctamente',
      details,
    );
  }
}

