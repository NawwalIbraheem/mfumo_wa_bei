from django.urls import path

from .views import LoginView, MeView, PasswordResetRequestView, RefreshTokenView, RegisterView

urlpatterns = [
    path("register/", RegisterView.as_view(), name="register"),
    path("login/", LoginView.as_view(), name="login"),
    path("refresh/", RefreshTokenView.as_view(), name="refresh"),
    path("me/", MeView.as_view(), name="me"),
    path("password-reset-request/", PasswordResetRequestView.as_view(), name="password-reset-request"),
]
