from rest_framework import serializers
from .models import Lineas, Puntos, LineaRuta, LineasPuntos

class LineasSerializer(serializers.ModelSerializer):
    idlinea = serializers.PrimaryKeyRelatedField
    class Meta:
        model = Lineas
        fields = '__all__'
        
class PuntosSerializer(serializers.ModelSerializer):
    class Meta:
        model = Puntos
        fields = '__all__'

class LineaRutaSerializer(serializers.ModelSerializer):
    class Meta:
        model = LineaRuta
        fields = '__all__'

class LineasPuntosSerializer(serializers.ModelSerializer):
    class Meta:
        model = LineasPuntos
        fields = '__all__'
        
