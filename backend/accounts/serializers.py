import random
from datetime import timedelta
import re

from django.contrib.auth import authenticate
from django.contrib.auth.models import User
from django.contrib.auth.password_validation import validate_password
from django.db import transaction
from django.utils import timezone
from rest_framework import serializers
from rest_framework.exceptions import AuthenticationFailed
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer

from .models import PasswordResetCode, Profile


PHONE_PATTERN = re.compile(r"^\d{10}$")
EMAIL_PATTERN = re.compile(r"^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$", re.IGNORECASE)


def normalize_phone_number(value: str) -> str:
    return re.sub(r"\s+", "", value.strip())


def validate_phone_number_format(value: str) -> str:
    normalized = normalize_phone_number(value)
    if not PHONE_PATTERN.fullmatch(normalized):
        raise serializers.ValidationError(
            "Weka namba ya simu sahihi yenye tarakimu 10."
        )
    return normalized


class UserSerializer(serializers.ModelSerializer):
    full_name = serializers.SerializerMethodField()
    phone_number = serializers.SerializerMethodField()

    class Meta:
        model = User
        fields = ["id", "username", "email", "full_name", "phone_number"]

    def get_full_name(self, user):
        return getattr(user.profile, "full_name", user.get_full_name())

    def get_phone_number(self, user):
        return getattr(user.profile, "phone_number", "")


class RegisterSerializer(serializers.Serializer):
    full_name = serializers.CharField(max_length=150)
    phone_number = serializers.CharField(max_length=20)
    email = serializers.EmailField(
        required=True,
        allow_blank=False,
        error_messages={
            "invalid": "Weka barua pepe sahihi.",
            "blank": "Barua pepe inahitajika.",
            "required": "Barua pepe inahitajika.",
        },
    )
    password = serializers.CharField(write_only=True, min_length=8)
    password_confirmation = serializers.CharField(write_only=True, min_length=8)

    def validate_phone_number(self, value):
        normalized = validate_phone_number_format(value)
        if Profile.objects.filter(phone_number=normalized).exists():
            raise serializers.ValidationError("Namba ya simu tayari imesajiliwa.")
        return normalized

    def validate_email(self, value):
        normalized = value.strip()
        if normalized and not EMAIL_PATTERN.fullmatch(normalized):
            raise serializers.ValidationError("Weka barua pepe sahihi.")
        if normalized and User.objects.filter(email__iexact=normalized).exists():
            raise serializers.ValidationError("Barua pepe tayari imesajiliwa.")
        return normalized

    def validate(self, attrs):
        full_name = attrs["full_name"].strip()
        if len(full_name) < 3:
            raise serializers.ValidationError(
                {"full_name": "Jina kamili lazima liwe na angalau herufi 3."}
            )

        if attrs["password"] != attrs["password_confirmation"]:
            raise serializers.ValidationError(
                {"password_confirmation": "Nenosiri halilingani."}
            )
        validate_password(attrs["password"])
        return attrs

    @transaction.atomic
    def create(self, validated_data):
        full_name = validated_data["full_name"].strip()
        phone_number = validated_data["phone_number"].strip()
        email = validated_data["email"].strip()
        password = validated_data["password"]

        user = User(
            username=phone_number,
            email=email,
            first_name=full_name,
        )
        user.set_password(password)
        user.save()

        Profile.objects.create(
            user=user,
            full_name=full_name,
            phone_number=phone_number,
        )
        return user


class LoginTokenSerializer(TokenObtainPairSerializer):
    username_field = User.USERNAME_FIELD

    @classmethod
    def get_token(cls, user):
        token = super().get_token(user)
        token["phone_number"] = getattr(user.profile, "phone_number", user.username)
        return token


class LoginSerializer(serializers.Serializer):
    email = serializers.EmailField(
        error_messages={
            "invalid": "Weka barua pepe sahihi.",
            "blank": "Barua pepe inahitajika.",
            "required": "Barua pepe inahitajika.",
        },
    )
    password = serializers.CharField(write_only=True)

    def validate(self, attrs):
        email = attrs["email"].strip()
        password = attrs["password"]
        user = User.objects.filter(email__iexact=email).first()
        if user is None:
            raise AuthenticationFailed("Barua pepe au nenosiri si sahihi.")

        user = authenticate(
            request=self.context.get("request"),
            username=user.username,
            password=password,
        )
        if user is None:
            raise AuthenticationFailed("Barua pepe au nenosiri si sahihi.")

        token_serializer = LoginTokenSerializer(
            data={"username": user.username, "password": password},
            context=self.context,
        )
        token_serializer.is_valid(raise_exception=True)

        return {
            "access": token_serializer.validated_data["access"],
            "refresh": token_serializer.validated_data["refresh"],
            "user": UserSerializer(user).data,
        }


class PasswordResetRequestSerializer(serializers.Serializer):
    identifier = serializers.CharField(
        max_length=254,
        error_messages={
            "blank": "Weka barua pepe au namba ya simu.",
            "required": "Weka barua pepe au namba ya simu.",
        },
    )

    def validate_identifier(self, value):
        normalized = value.strip()
        if not normalized:
            raise serializers.ValidationError("Weka barua pepe au namba ya simu.")

        if EMAIL_PATTERN.fullmatch(normalized):
            user = User.objects.filter(email__iexact=normalized).first()
            if user is None:
                raise serializers.ValidationError(
                    "Hakuna akaunti yenye barua pepe hii."
                )
            return getattr(user.profile, "phone_number", user.username)

        normalized_phone = validate_phone_number_format(normalized)
        if not Profile.objects.filter(phone_number=normalized_phone).exists():
            raise serializers.ValidationError("Hakuna akaunti yenye namba hii ya simu.")
        return normalized_phone

    def save(self, **kwargs):
        phone_number = self.validated_data["identifier"]
        code = f"{random.randint(0, 999999):06d}"
        reset_code = PasswordResetCode.objects.create(
            phone_number=phone_number,
            code=code,
            expires_at=timezone.now() + timedelta(minutes=10),
        )
        return {
            "phone_number": phone_number,
            "expires_at": reset_code.expires_at,
            "reset_code": code,
        }
