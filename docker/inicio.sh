#!/bin/bash

if [ ! -f "/app/backend/manage.py" ]; then
  echo "🛠️ Creando proyecto Django..."
  django-admin startproject planificador_viajes /app/backend
  echo "✅ Proyecto creado."
fi

cd /app/backend

echo "🔄 Ejecutando makemigrations para todas las apps..."
python manage.py makemigrations

echo "🔄 Ejecutando migrate..."
python manage.py migrate --noinput || exit 1

until python manage.py showmigrations | grep "\[X\]"; do
  echo "Esperando a que la base de datos esté lista..."
  sleep 2
done

if ! python manage.py shell -c "from django.contrib.auth import get_user_model; User = get_user_model(); print(User.objects.filter(username='${DJANGO_SUPERUSER_USERNAME}').exists())" | grep -q True; then
  echo "🛠️ Creando superusuario..."
  python manage.py shell << END
from django.contrib.auth import get_user_model
User = get_user_model()
User.objects.create_superuser(
    "${DJANGO_SUPERUSER_USERNAME}",
    "${DJANGO_SUPERUSER_EMAIL}",
    "${DJANGO_SUPERUSER_PASSWORD}"
)
END
else
  echo "✅ Superusuario ya existe."
fi

echo "🚀 Iniciando Django..."
python manage.py runserver 0.0.0.0:8000