from django.contrib import admin

from .models import PasswordResetCode, Profile


@admin.register(Profile)
class ProfileAdmin(admin.ModelAdmin):
    list_display = ("full_name", "phone_number", "user", "created_at")
    search_fields = ("full_name", "phone_number", "user__username")


@admin.register(PasswordResetCode)
class PasswordResetCodeAdmin(admin.ModelAdmin):
    list_display = ("phone_number", "code", "expires_at", "used_at", "created_at")
    search_fields = ("phone_number", "code")

# Register your models here.
