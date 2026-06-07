# App de Geolocalización + Contactos en Flutter

## Descripción

Crear una nueva app Flutter llamada **`geo_contacts_app`** dentro del mismo workspace. La app permite al usuario:
- Ver su ubicación actual en tiempo real en un mapa
- Guardar ubicaciones con un nombre personalizado
- Vincular una ubicación guardada a un contacto del teléfono
- Ver la lista de contactos con su ubicación asignada
- Calcular distancia desde tu ubicación a la del contacto

**Nivel:** Intermedio — uso de permisos nativos, múltiples paquetes, navegación entre pantallas, persistencia local con `shared_preferences`.

---

## Paquetes a usar

| Paquete | Función |
|---|---|
| `geolocator` | Obtener GPS actual |
| `google_maps_flutter` | Mostrar mapa interactivo |
| `flutter_contacts` | Leer contactos del dispositivo |
| `shared_preferences` | Guardar ubicaciones localmente |
| `permission_handler` | Gestionar permisos en runtime |

---

## Estructura de archivos

```
geo_contacts_app/
└── lib/
    ├── main.dart                         # Entry point + navegación
    ├── models/
    │   └── ubicacion_contacto.dart       # Modelo de datos
    ├── services/
    │   ├── location_service.dart         # GPS + lógica de ubicación
    │   └── storage_service.dart          # SharedPreferences
    ├── screens/
    │   ├── home_screen.dart              # Mapa principal + botón GPS
    │   ├── contactos_screen.dart         # Lista de contactos vinculados
    │   └── detalle_contacto_screen.dart  # Detalle: contacto + mapa pequeño
    └── widgets/
        └── contacto_card.dart            # Tarjeta de contacto reutilizable
```

---

## Pantallas

### 1. Home Screen — Mapa + GPS
- Mapa de Google Maps centrado en la ubicación actual
- Botón FAB para obtener/refrescar ubicación
- Marcador en la posición actual
- Botón para ir a la pantalla de Contactos

### 2. Contactos Screen
- Lista de contactos del teléfono (con foto si tiene)
- Indicador visual si ya tiene ubicación asignada
- Al tocar un contacto → abre Detalle

### 3. Detalle Contacto Screen
- Foto/avatar + nombre + teléfono del contacto
- Botón "Asignar mi ubicación actual" → guarda GPS actual al contacto
- Si ya tiene ubicación: muestra un mini-mapa con su pin
- Muestra distancia en km desde tu posición actual

---

## Cambios en archivos nativos

### AndroidManifest.xml
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<uses-permission android:name="android.permission.READ_CONTACTS"/>
```
También agregar la API Key de Google Maps.

### iOS (Info.plist)
Strings de permisos de ubicación y contactos (si aplica).

---

> [!IMPORTANT]
> Se necesita una **API Key de Google Maps**. Para desarrollo/clase se puede usar una key gratuita de la consola de Google. Si no tienes una, el mapa puede reemplazarse con `flutter_map` (OpenStreetMap, sin key).

> [!NOTE]
> El proyecto se crea **dentro de** `C:\Users\ACER\Documents\UNIVERSIDAD\IV SEMESTRE\DBPI\C1 - FLUTTER CON API\` como una carpeta nueva `geo_contacts_app`, separado del `pokedex_app`.

---

## Preguntas abiertas

1. ¿Tienes una **API Key de Google Maps**? Si no, uso OpenStreetMap (sin key, funciona igual).
2. ¿Corres la app en **emulador Android** o **dispositivo físico**? (para GPS el físico es mejor)
