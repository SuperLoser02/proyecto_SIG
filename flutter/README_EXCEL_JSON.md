# Conversor de Excel a JSON

Script en Python para convertir archivos Excel (.xlsx, .xls) a formato JSON.

## 📋 Requisitos

```bash
pip install pandas openpyxl
```

## 🚀 Uso Rápido

### 1. Convertir primera hoja de Excel a JSON

```python
python excel_to_json.py
```

Asegúrate de tener un archivo `datos.xlsx` en la misma carpeta, o cambia el nombre en el script.

### 2. Convertir hoja específica

```python
from excel_to_json import excel_to_json

# Por nombre de hoja
data = excel_to_json('datos.xlsx', sheet_name='Ventas')

# Por índice (0 = primera hoja)
data = excel_to_json('datos.xlsx', sheet_name=0)
```

### 3. Convertir todas las hojas

```python
from excel_to_json import excel_to_json_multiple_sheets

data = excel_to_json_multiple_sheets('datos.xlsx')
```

### 4. Especificar archivo de salida

```python
data = excel_to_json('datos.xlsx', json_file='salida.json')
```

## 📊 Formato de Salida

El JSON se genera en formato de lista de objetos:

**Excel:**
| Nombre | Edad | Ciudad |
|--------|------|--------|
| Juan   | 25   | La Paz |
| María  | 30   | Santa Cruz |

**JSON generado:**
```json
[
  {
    "Nombre": "Juan",
    "Edad": 25,
    "Ciudad": "La Paz"
  },
  {
    "Nombre": "María",
    "Edad": 30,
    "Ciudad": "Santa Cruz"
  }
]
```

## 💡 Ejemplos Completos

### Ejemplo 1: Básico
```python
from excel_to_json import excel_to_json

# Lee 'clientes.xlsx' y crea 'clientes.json'
data = excel_to_json('clientes.xlsx')
```

### Ejemplo 2: Con configuración
```python
# Lee hoja específica y guarda con nombre personalizado
data = excel_to_json(
    excel_file='ventas.xlsx',
    json_file='ventas_2024.json',
    sheet_name='Diciembre'
)
```

### Ejemplo 3: Múltiples hojas
```python
from excel_to_json import excel_to_json_multiple_sheets

# Crea JSON con todas las hojas
data = excel_to_json_multiple_sheets('reporte_completo.xlsx')
# Resultado: {'Hoja1': [...], 'Hoja2': [...], ...}
```

## ⚙️ Funciones Disponibles

### `excel_to_json(excel_file, json_file=None, sheet_name=0)`
Convierte una hoja de Excel a JSON.

**Parámetros:**
- `excel_file`: Ruta del archivo Excel
- `json_file`: Ruta del JSON de salida (opcional)
- `sheet_name`: Nombre o índice de la hoja (default: 0)

**Retorna:** Lista de diccionarios con los datos

### `excel_to_json_multiple_sheets(excel_file, json_file=None)`
Convierte todas las hojas de un Excel a JSON.

**Parámetros:**
- `excel_file`: Ruta del archivo Excel
- `json_file`: Ruta del JSON de salida (opcional)

**Retorna:** Diccionario con todas las hojas

## 🔧 Características

✅ Lee archivos .xlsx y .xls
✅ Soporta múltiples hojas
✅ Codificación UTF-8 (caracteres especiales y acentos)
✅ JSON formateado con indentación
✅ Preview de datos al convertir
✅ Manejo de errores

## 📝 Instalación de Dependencias

```bash
# Instalar pandas y openpyxl
pip install pandas openpyxl

# O desde requirements.txt
pip install -r requirements.txt
```

## 🐛 Solución de Problemas

### Error: "No module named 'openpyxl'"
```bash
pip install openpyxl
```

### Error: "No module named 'pandas'"
```bash
pip install pandas
```

### Error: "No such file or directory"
Verifica que el archivo Excel esté en la misma carpeta o usa la ruta completa:
```python
data = excel_to_json('C:/Users/usuario/Desktop/datos.xlsx')
```
