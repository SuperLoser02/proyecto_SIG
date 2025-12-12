# 📘 Proyecto – Guía de Configuración

## 🛠️ 1. Formato del archivo `inicio.sh`

Asegúrate de que el archivo:

```
docker/inicio.sh
```

esté en formato **LF** y **NO CRLF**.
Esto evita errores de ejecución en sistemas basados en Linux (como Docker).

---

## 📥 2. Cargar datos desde la raíz del proyecto

Si necesitas cargar datos manualmente, ejecuta:

```bash
cd backend
docker exec -it proyecto_sig-backend-1 bash   # O el nombre real del contenedor (con `docker ps` lo puedes ver)
cd backend
python manage.py cargarDatos
```

---

## 📱 3. Probar Flutter con el backend de Django

### ▶️ 3.1. Flutter Web

Si vas a probar la versión web de Flutter:

1. Abre el archivo:

```
flutter/bus/lib/services/api_django.dart
```

2. Si tienes esto:

```dart
'http://localhost:8000/api'
```

Cámbialo por:

```dart
'http://10.0.2.2:8000/api'
```

> **10.0.2.2** es la IP interna del emulador para acceder al host.

---

### ▶️ 3.2. Emulador de celular (Android Emulator)

Si usarás un **emulador Android**, también debes usar:

```dart
'http://10.0.2.2:8000/api'
```

---

### ▶️ 3.3. Si solo usarás Flutter Web

Entonces déjalo así:

```dart
'http://localhost:8000/api'
```

---

## 🖼️ 4. Problemas con imágenes en Flutter (Web o Android)

Si las imágenes **no cargan**, o te aparece un error tipo *“Unable to load asset”*, prueba:

```bash
flutter clean
flutter pub get
```

Esto fuerza a Flutter a reconstruir los assets y normalmente soluciona problemas de cargas corruptas o rutas incorrectas.
