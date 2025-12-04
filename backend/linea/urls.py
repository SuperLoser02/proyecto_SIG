from django.urls import path
from rest_framework.routers import DefaultRouter
from .views import (
    LineasViewSet,
    PuntosViewSet,
    LineaRutaViewSet,
    LineasPuntosViewSet,
    get_all_data,
)

router = DefaultRouter()
router.register(r'lineas', LineasViewSet, basename='lineas')
router.register(r'puntos', PuntosViewSet, basename='puntos')
router.register(r'linea_ruta', LineaRutaViewSet, basename='linea_ruta')
router.register(r'lineas_puntos', LineasPuntosViewSet, basename='lineas_puntos')

urlpatterns = router.urls

urlpatterns += [
    path('all-data/', get_all_data, name='all-data'),
]
