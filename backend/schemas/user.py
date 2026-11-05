"""schemas/user.py — Pydantic models for the users domain."""

from __future__ import annotations

from datetime import datetime
from typing import Optional

from pydantic import BaseModel, ConfigDict, EmailStr, field_validator


# ---------------------------------------------------------------------------
# Shared config: output camelCase so Flutter's fromJson() works unchanged
# ---------------------------------------------------------------------------
class _CamelBase(BaseModel):
    model_config = ConfigDict(populate_by_name=True, alias_generator=None)

    def model_dump_camel(self) -> dict:
        """Return dict with camelCase keys matching Flutter toJson()."""
        return self.model_dump(by_alias=True)


# ---------------------------------------------------------------------------
# Inbound
# ---------------------------------------------------------------------------
class LoginRequest(BaseModel):
    email: str
    password: str
    expectedRole: str = "citizen"  # citizen | responder | admin


class RegisterRequest(BaseModel):
    name: str
    email: str
    password: str
    confirmPassword: str
    emergencyContactName: Optional[str] = None
    emergencyContactPhone: Optional[str] = None


# ---------------------------------------------------------------------------
# Outbound
# ---------------------------------------------------------------------------
class UserOut(BaseModel):
    """Matches AppUser.fromJson() field names exactly."""
    model_config = ConfigDict(populate_by_name=True)

    id: str
    name: str
    email: str
    role: str
    isApproved: bool
    isEnabled: bool
    emergencyContactName: Optional[str] = None
    emergencyContactPhone: Optional[str] = None
    organization: Optional[str] = None
    createdAt: str


class LoginResponse(BaseModel):
    success: bool
    message: str
    user: Optional[UserOut] = None


class RegisterResponse(BaseModel):
    success: bool
    message: str
    user: Optional[UserOut] = None
