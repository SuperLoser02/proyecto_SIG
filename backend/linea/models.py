from django.db import models

# Create your models here.

class Lineas(models.Model):
    nombreLinea = models.CharField(max_length=4, unique=True, null=False, blank=False)
    colorLinea = models.CharField(max_length=7, null=False, blank=False)  # Hex color code
    imagenLinea = models.ImageField(null=True, blank=True)
    fechaCreacion = models.DateField(null=True, blank=True)
    
    def __str__(self):
        return self.nombreLinea
    
class Puntos(models.Model):
    latitud = models.FloatField(null=False, blank=False)
    longitud = models.FloatField(null=False, blank=False)
    descripcion = models.CharField(max_length=10, null=True, blank=True)
    
    def __str__(self):
        return f"Punto({self.latitud}, {self.longitud}) - {self.descripcion}"
    
class LineaRuta(models.Model):
    idlinea = models.ForeignKey(Lineas, on_delete=models.CASCADE, related_name='rutas')
    idRuta = models.CharField(max_length=1, null=False, blank=False)
    descripcion = models.CharField(max_length=100, null=True, blank=True)
    distancia = models.FloatField(null=True, blank=True)  # in kilometers
    tiempo = models.FloatField(null=True, blank=True)  # in minutes
    
    
    def __str__(self):
        return f"LineaRuta({self.idlinea.nombreLinea} - {self.idRuta})"
    
class LineasPuntos(models.Model):
    idLineaRuta = models.ForeignKey(LineaRuta, on_delete=models.CASCADE, related_name='puntos')
    idPunto = models.ForeignKey(Puntos, on_delete=models.CASCADE, related_name='lineas')
    orden = models.IntegerField(null=False, blank=False)
    latitud = models.FloatField(null=False, blank=False)
    longitud = models.FloatField(null=False, blank=False)
    distancia = models.FloatField(null=True, blank=True)  # in kilometers
    tiempo = models.FloatField(null=True, blank=True)  # in minutes
    
    def __str__(self):
        return f"LineasPuntos({self.idLineaRuta.idlinea.nombreLinea} - {self.idLineaRuta.idRuta} - Punto Orden: {self.orden})"
