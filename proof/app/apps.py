from django.apps import AppConfig

from .models import Test


Test('bar')


class AppConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'app'
