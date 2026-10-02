# Rich-formatted tracebacks for every Python program run with the system
# interpreter: a boxed, syntax-highlighted traceback with source context,
# like the one netexec shows. Python's site module imports this automatically.
#
# Safe by design: if Rich is missing or anything fails, Python falls back to
# its normal traceback. Set NG_NO_RICH_TRACEBACK=1 to turn it off for a shell.
import os

if not os.environ.get("NG_NO_RICH_TRACEBACK"):
    try:
        from rich.traceback import install as _install
        _install(show_locals=False, width=None, word_wrap=True)
    except Exception:
        pass
