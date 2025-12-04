from rest_framework import viewsets, status
from rest_framework.decorators import action, api_view
from rest_framework.response import Response
from .models import Lineas, Puntos, LineaRuta, LineasPuntos
from .serializer import LineasSerializer , PuntosSerializer, LineaRutaSerializer, LineasPuntosSerializer

# Create your views here.


class LineasViewSet(viewsets.ModelViewSet):
    queryset = Lineas.objects.all()
    serializer_class = LineasSerializer


class PuntosViewSet(viewsets.ModelViewSet):
    queryset = Puntos.objects.all()
    serializer_class = PuntosSerializer

class LineaRutaViewSet(viewsets.ModelViewSet):
    queryset = LineaRuta.objects.all()
    serializer_class = LineaRutaSerializer
    
class LineasPuntosViewSet(viewsets.ModelViewSet):
    queryset = LineasPuntos.objects.all()
    serializer_class = LineasPuntosSerializer
    
@api_view(['GET'])
def get_all_data(request):
    return Response({
        'Lineas': LineasSerializer(Lineas.objects.all(), many=True).data,
        'Puntos': PuntosSerializer(Puntos.objects.all(), many=True).data,
        'LineaRuta': LineaRutaSerializer(LineaRuta.objects.all(), many=True).data,
        'LineasPuntos': LineasPuntosSerializer(LineasPuntos.objects.all(), many=True).data,
    })