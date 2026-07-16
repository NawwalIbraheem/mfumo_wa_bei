from django.contrib.auth.models import User
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase

from .models import Profile


class LoginApiTests(APITestCase):
    def setUp(self):
        self.password = "StrongPass123!"
        self.phone_number = "0712345678"
        self.email = "test@example.com"
        self.user = User.objects.create_user(
            username=self.phone_number,
            email=self.email,
            password=self.password,
        )
        Profile.objects.create(
            user=self.user,
            full_name="Test User",
            phone_number=self.phone_number,
        )
        self.url = reverse("login")

    def test_login_returns_tokens_and_user_details(self):
        response = self.client.post(
            self.url,
            {
                "email": self.email,
                "password": self.password,
            },
            format="json",
        )

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(
            response.data["message"],
            "Umeingia kwenye akaunti yako kwa mafanikio.",
        )
        self.assertIn("access", response.data["data"])
        self.assertIn("refresh", response.data["data"])
        self.assertEqual(
            response.data["data"]["user"]["phone_number"],
            self.phone_number,
        )

    def test_login_rejects_invalid_credentials(self):
        response = self.client.post(
            self.url,
            {
                "email": self.email,
                "password": "wrong-password",
            },
            format="json",
        )

        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)
        self.assertEqual(
            response.data["detail"],
            "Barua pepe au nenosiri si sahihi.",
        )


class AuthValidationApiTests(APITestCase):
    def setUp(self):
        self.password = "StrongPass123!"
        self.phone_number = "0712345678"
        self.email = "test@example.com"
        self.user = User.objects.create_user(
            username=self.phone_number,
            email=self.email,
            password=self.password,
        )
        Profile.objects.create(
            user=self.user,
            full_name="Test User",
            phone_number=self.phone_number,
        )

    def test_register_rejects_invalid_phone_number(self):
        response = self.client.post(
            reverse("register"),
            {
                "full_name": "Test User",
                "phone_number": "12345",
                "email": "test@example.com",
                "password": "StrongPass123!",
                "password_confirmation": "StrongPass123!",
            },
            format="json",
        )

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertEqual(
            response.data["phone_number"][0],
            "Weka namba ya simu sahihi yenye tarakimu 10.",
        )

    def test_register_rejects_invalid_email(self):
        response = self.client.post(
            reverse("register"),
            {
                "full_name": "Test User",
                "phone_number": "0712345678",
                "email": "invalid-email",
                "password": "StrongPass123!",
                "password_confirmation": "StrongPass123!",
            },
            format="json",
        )

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertEqual(
            response.data["email"][0],
            "Weka barua pepe sahihi.",
        )

    def test_register_requires_email(self):
        response = self.client.post(
            reverse("register"),
            {
                "full_name": "Test User",
                "phone_number": "0712345678",
                "email": "",
                "password": "StrongPass123!",
                "password_confirmation": "StrongPass123!",
            },
            format="json",
        )

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertEqual(
            response.data["email"][0],
            "Barua pepe inahitajika.",
        )

    def test_password_reset_accepts_phone_number(self):
        response = self.client.post(
            reverse("password-reset-request"),
            {
                "identifier": self.phone_number,
            },
            format="json",
        )

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["data"]["phone_number"], self.phone_number)
        self.assertIn("reset_code", response.data["data"])

    def test_password_reset_accepts_email(self):
        response = self.client.post(
            reverse("password-reset-request"),
            {
                "identifier": self.email,
            },
            format="json",
        )

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["data"]["phone_number"], self.phone_number)
        self.assertIn("reset_code", response.data["data"])

    def test_password_reset_rejects_invalid_identifier(self):
        response = self.client.post(
            reverse("password-reset-request"),
            {
                "identifier": "07 12",
            },
            format="json",
        )

        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertEqual(
            response.data["identifier"][0],
            "Weka namba ya simu sahihi yenye tarakimu 10.",
        )
