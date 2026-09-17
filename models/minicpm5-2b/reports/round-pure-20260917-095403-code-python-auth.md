# Bench report: code-python-auth (round pure-20260917-095403)

- Prompt: `/home/peppe/github/testlocalai/tasks/code-python-auth/rounds/prompt-pure-20260917-095403.txt`
- Model: minicpm5:2b (temp 0.2)
- Backend: llamacpp
- Mode: rules (python-rules.md + SPEC.md, current best)
- Tokens: 542 prompt / 166 completion

## VERDICT: TEST FAIL
FAILED tasks/code-python-auth/harness/tests/test_auth_resolver.py::test_returns_x_dev_user_when_present
FAILED tasks/code-python-auth/harness/tests/test_auth_resolver.py::test_returns_x_dev_user_even_when_require_auth_true
FAILED tasks/code-python-auth/harness/tests/test_auth_resolver.py::test_whitespace_only_counts_as_absent_and_raises_when_required
FAILED tasks/code-python-auth/harness/tests/test_auth_resolver.py::test_none_raises_permission_error_when_required
FAILED tasks/code-python-auth/harness/tests/test_auth_resolver.py::test_none_returns_anonymous_when_not_required
FAILED tasks/code-python-auth/harness/tests/test_auth_resolver.py::test_whitespace_only_returns_anonymous_when_not_required
FAILED tasks/code-python-auth/harness/tests/test_auth_resolver.py::test_x_dev_user_returned_unstripped
