import pytest

from auth_resolver import resolve_user


def test_returns_x_dev_user_when_present():
    assert resolve_user(False, "alice") == "alice"


def test_returns_x_dev_user_even_when_require_auth_true():
    assert resolve_user(True, "alice") == "alice"


def test_whitespace_only_counts_as_absent_and_raises_when_required():
    with pytest.raises(PermissionError):
        resolve_user(True, "   ")


def test_none_raises_permission_error_when_required():
    with pytest.raises(PermissionError):
        resolve_user(True, None)


def test_none_returns_anonymous_when_not_required():
    assert resolve_user(False, None) == "anonymous"


def test_whitespace_only_returns_anonymous_when_not_required():
    assert resolve_user(False, "   ") == "anonymous"


def test_x_dev_user_returned_unstripped():
    assert resolve_user(False, "  bob  ") == "  bob  "
