# Python output rules

1. Use the exact names from the SPEC. Copy the function names, class names, parameter names, and parameter order without change. The tests import these names and call them. One wrong name or one wrong parameter makes every test fail.

2. Write every line of code in full. Do not use `...`, a bare `pass`, or a `# TODO` comment as a function body.

3. Give the full file in one ```python block. Put all imports at the top of the file. Do not add code that runs when the tests import the file. For example, do not add example calls, `print` calls, or `input()` calls at module level.
