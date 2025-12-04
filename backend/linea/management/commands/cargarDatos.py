"""
Comando para cargar datos iniciales desde DatosLineas.xls

Ubicación: linea/management/commands/cargarDatos.py

Uso:
    python manage.py cargarDatos
"""

from django.core.management.base import BaseCommand
from django.conf import settings
from django.core.files import File
from linea.models import Lineas, Puntos, LineaRuta, LineasPuntos
import pandas as pd
import os


class Command(BaseCommand):
    help = 'Carga datos iniciales desde el archivo DatosLineas.xls'

    def handle(self, *args, **kwargs):
        # Buscar primero .xlsx, luego .xls
        excel_path_xlsx = os.path.join(settings.BASE_DIR, 'DatosLineas.xlsx')
        excel_path_xls = os.path.join(settings.BASE_DIR, 'DatosLineas.xls')
        
        if os.path.exists(excel_path_xlsx):
            excel_path = excel_path_xlsx
            engine = 'openpyxl'
            self.stdout.write('Usando engine: openpyxl (formato .xlsx)')
        elif os.path.exists(excel_path_xls):
            excel_path = excel_path_xls
            engine = 'xlrd'
            self.stdout.write('Usando engine: xlrd (formato .xls)')
        else:
            self.stdout.write(self.style.ERROR(f'✗ Archivo no encontrado: DatosLineas.xls o DatosLineas.xlsx'))
            return
        
        self.stdout.write(self.style.SUCCESS(f'Leyendo archivo: {excel_path}\n'))
        
        # Cargar en orden: Lineas -> Puntos -> LineaRuta -> LineasPuntos
        self.cargar_lineas(excel_path, engine)
        self.cargar_puntos(excel_path, engine)
        self.cargar_linea_ruta(excel_path, engine)
        self.cargar_lineas_puntos(excel_path, engine)
        
        self.stdout.write(self.style.SUCCESS('\n✓ Proceso completado'))

    def cargar_lineas(self, excel_path, engine):
        """Carga datos de la hoja Lineas"""
        try:
            df_lineas = pd.read_excel(excel_path, sheet_name='Lineas', engine=engine)
            self.stdout.write(f'\n📍 Cargando {len(df_lineas)} líneas...')
            
            for _, row in df_lineas.iterrows():
                id_linea = int(row['IdLinea'])
                nombre_linea = str(row['NombreLinea']).strip()
                color_linea = str(row['ColorLinea']).strip()
                
                linea, created = Lineas.objects.update_or_create(
                    id=id_linea,
                    defaults={
                        'nombreLinea': nombre_linea,
                        'colorLinea': color_linea,
                    }
                )
                
                # Manejar la imagen
                imagen_filename = f"img_{nombre_linea}.png"
                imagen_path = os.path.join(settings.MEDIA_ROOT, imagen_filename)
                
                if os.path.exists(imagen_path) and not linea.imagenLinea:
                    with open(imagen_path, 'rb') as img_file:
                        linea.imagenLinea.save(imagen_filename, File(img_file), save=False)
                    linea.save()
                
                action = "Creada" if created else "Actualizada"
                self.stdout.write(f'  {action}: ID={id_linea} - {nombre_linea}')
            
            self.stdout.write(self.style.SUCCESS(f'✓ {len(df_lineas)} líneas procesadas'))
            
        except Exception as e:
            self.stdout.write(self.style.ERROR(f'✗ Error cargando Líneas: {e}'))
            import traceback
            traceback.print_exc()

    def cargar_puntos(self, excel_path, engine):
        """Carga datos de la hoja Puntos"""
        try:
            df_puntos = pd.read_excel(excel_path, sheet_name='Puntos', engine=engine)
            self.stdout.write(f'\n📍 Cargando {len(df_puntos)} puntos...')
            
            for _, row in df_puntos.iterrows():
                id_punto = int(row['IdPunto'])  # Corregido: IdPuto -> IdPunto
                latitud = float(row['Latitud'])
                longitud = float(row['Longitud'])
                descripcion = str(row['Descripcion']).strip() if pd.notna(row['Descripcion']) else ''
                
                punto, created = Puntos.objects.update_or_create(
                    id=id_punto,
                    defaults={
                        'latitud': latitud,
                        'longitud': longitud,
                        'descripcion': descripcion,
                    }
                )
                
                action = "Creado" if created else "Actualizado"
                self.stdout.write(f'  {action}: ID={id_punto} - {descripcion}')
            
            self.stdout.write(self.style.SUCCESS(f'✓ {len(df_puntos)} puntos procesados'))
            
        except Exception as e:
            self.stdout.write(self.style.ERROR(f'✗ Error cargando Puntos: {e}'))
            import traceback
            traceback.print_exc()

    def cargar_linea_ruta(self, excel_path, engine):
        """Carga datos de la hoja LineaRuta"""
        try:
            df_linea_ruta = pd.read_excel(excel_path, sheet_name='LineaRuta', engine=engine)
            self.stdout.write(f'\n📍 Cargando {len(df_linea_ruta)} rutas de línea...')
            
            for _, row in df_linea_ruta.iterrows():
                id_linea_ruta = int(row['IdLineaRuta'])
                id_linea = int(row['IdLinea'])
                id_ruta = str(row['IdRuta']).strip()  # Cambiado a string según tu modelo
                descripcion = str(row['Descripcion']).strip() if pd.notna(row['Descripcion']) else ''
                distancia = float(row['Distancia']) if pd.notna(row['Distancia']) else None
                tiempo = float(row['Tiempo']) if pd.notna(row['Tiempo']) else None
                
                try:
                    linea_obj = Lineas.objects.get(id=id_linea)
                except Lineas.DoesNotExist:
                    self.stdout.write(self.style.WARNING(f'  ⚠ Línea ID={id_linea} no existe, saltando...'))
                    continue
                
                linea_ruta, created = LineaRuta.objects.update_or_create(
                    id=id_linea_ruta,
                    defaults={
                        'idlinea': linea_obj,  # Corregido: idLinea -> idlinea
                        'idRuta': id_ruta,
                        'descripcion': descripcion,
                        'distancia': distancia,
                        'tiempo': tiempo,
                    }
                )
                
                action = "Creada" if created else "Actualizada"
                self.stdout.write(f'  {action}: ID={id_linea_ruta} - {descripcion}')
            
            self.stdout.write(self.style.SUCCESS(f'✓ {len(df_linea_ruta)} rutas procesadas'))
            
        except Exception as e:
            self.stdout.write(self.style.ERROR(f'✗ Error cargando LineaRuta: {e}'))
            import traceback
            traceback.print_exc()

    def cargar_lineas_puntos(self, excel_path, engine):
        """Carga datos de la hoja LineasPuntos"""
        try:
            df_lineas_puntos = pd.read_excel(excel_path, sheet_name='LineasPuntos', engine=engine)
            self.stdout.write(f'\n📍 Cargando {len(df_lineas_puntos)} relaciones línea-punto...')
            
            for _, row in df_lineas_puntos.iterrows():
                id_linea_punto = int(row['IdLineaPunto'])
                id_linea_ruta = int(row['IdLineaRuta'])
                id_punto = int(row['IdPunto'])
                orden = int(row['Orden'])
                latitud = float(row['Latitud'])
                longitud = float(row['Longitud'])
                distancia = float(row['Distancia']) if pd.notna(row['Distancia']) else None
                tiempo = float(row['Tiempo']) if pd.notna(row['Tiempo']) else None
                
                try:
                    linea_ruta_obj = LineaRuta.objects.get(id=id_linea_ruta)
                    punto_obj = Puntos.objects.get(id=id_punto)
                except (LineaRuta.DoesNotExist, Puntos.DoesNotExist) as e:
                    self.stdout.write(self.style.WARNING(f'  ⚠ Referencia no existe: {e}, saltando...'))
                    continue
                
                linea_punto, created = LineasPuntos.objects.update_or_create(
                    id=id_linea_punto,
                    defaults={
                        'idLineaRuta': linea_ruta_obj,
                        'idPunto': punto_obj,
                        'orden': orden,
                        'latitud': latitud,
                        'longitud': longitud,
                        'distancia': distancia,
                        'tiempo': tiempo,
                    }
                )
                
                action = "Creada" if created else "Actualizada"
                self.stdout.write(f'  {action}: ID={id_linea_punto} - Orden {orden}')
            
            self.stdout.write(self.style.SUCCESS(f'✓ {len(df_lineas_puntos)} relaciones procesadas'))
            
        except Exception as e:
            self.stdout.write(self.style.ERROR(f'✗ Error cargando LineasPuntos: {e}'))
            import traceback
            traceback.print_exc()