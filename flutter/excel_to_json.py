import pandas as pd
import json
import os

def excel_to_json(excel_file, json_file=None, sheet_name=0):
    """
    Convierte un archivo Excel a formato JSON
    
    Args:
        excel_file: Ruta del archivo Excel (.xlsx, .xls)
        json_file: Ruta del archivo JSON de salida (opcional)
        sheet_name: Nombre o índice de la hoja (0 = primera hoja)
    
    Returns:
        dict: Datos en formato JSON
    """
    try:
        # Leer el archivo Excel
        print(f"Leyendo archivo Excel: {excel_file}")
        df = pd.read_excel(excel_file, sheet_name=sheet_name)
        
        # Mostrar información básica
        print(f"\n✅ Archivo leído exitosamente!")
        print(f"📊 Filas: {len(df)}")
        print(f"📋 Columnas: {list(df.columns)}")
        
        # Convertir fechas a strings para que sean serializables
        for col in df.columns:
            if pd.api.types.is_datetime64_any_dtype(df[col]):
                df[col] = df[col].astype(str)
        
        # Convertir a JSON (orient='records' crea una lista de objetos)
        json_data = df.to_dict(orient='records')
        
        # Si no se especifica archivo de salida, usar el mismo nombre
        if json_file is None:
            json_file = os.path.splitext(excel_file)[0] + '.json'
        
        # Guardar el JSON
        with open(json_file, 'w', encoding='utf-8') as f:
            json.dump(json_data, f, ensure_ascii=False, indent=2)
        
        print(f"\n✅ JSON creado: {json_file}")
        print(f"📦 Total de registros: {len(json_data)}")
        
        # Mostrar preview del primer registro
        if json_data:
            print("\n📄 Preview del primer registro:")
            print(json.dumps(json_data[0], ensure_ascii=False, indent=2))
        
        return json_data
        
    except FileNotFoundError:
        print(f"❌ Error: No se encontró el archivo '{excel_file}'")
        return None
    except Exception as e:
        print(f"❌ Error: {str(e)}")
        return None


def excel_to_json_multiple_sheets(excel_file, json_file=None):
    """
    Convierte todas las hojas de un Excel a un JSON
    
    Args:
        excel_file: Ruta del archivo Excel
        json_file: Ruta del archivo JSON de salida
    
    Returns:
        dict: Diccionario con todas las hojas
    """
    try:
        # Leer todas las hojas
        print(f"Leyendo todas las hojas de: {excel_file}")
        excel_data = pd.read_excel(excel_file, sheet_name=None)
        
        result = {}
        for sheet_name, df in excel_data.items():
            print(f"\n📄 Hoja: {sheet_name}")
            print(f"   Filas: {len(df)}, Columnas: {len(df.columns)}")
            # Convertir fechas a strings
            for col in df.columns:
                if pd.api.types.is_datetime64_any_dtype(df[col]):
                    df[col] = df[col].astype(str)
            result[sheet_name] = df.to_dict(orient='records')
        
        # Guardar JSON
        if json_file is None:
            json_file = os.path.splitext(excel_file)[0] + '_completo.json'
        
        with open(json_file, 'w', encoding='utf-8') as f:
            json.dump(result, f, ensure_ascii=False, indent=2)
        
        print(f"\n✅ JSON creado: {json_file}")
        return result
        
    except Exception as e:
        print(f"❌ Error: {str(e)}")
        return None


# ============================================
# EJEMPLOS DE USO
# ============================================

if __name__ == "__main__":
    print("=" * 60)
    print("📊 CONVERSOR DE EXCEL A JSON")
    print("=" * 60)
    
    excel_file = 'datos.xls'
    
    if os.path.exists(excel_file):
        # Convertir todas las hojas del Excel
        print("\n🔹 Convirtiendo todas las hojas del Excel")
        print("-" * 60)
        data_all = excel_to_json_multiple_sheets(excel_file, 'datos.json')
    else:
        print(f"\n⚠️  No se encontró '{excel_file}'")
        print("\n💡 Instrucciones:")
        print("   1. Coloca tu archivo Excel en esta carpeta")
        print("   2. Cambia el nombre 'datos.xls' por el nombre de tu archivo")
        print("   3. Ejecuta el script nuevamente")
    
    print("\n" + "=" * 60)
    
    # Opción 2: Convertir todas las hojas
    # Descomenta las siguientes líneas para usar:
    # print("\n🔹 Opción 2: Convertir todas las hojas")
    # print("-" * 60)
    # data_all = excel_to_json_multiple_sheets(excel_file)
    
    # Opción 3: Especificar hoja por nombre
    # data = excel_to_json(excel_file, sheet_name='Hoja1')
    
    # Opción 4: Especificar archivo JSON de salida
    # data = excel_to_json(excel_file, json_file='mi_salida.json')

print("\n✅ Script completado!")
