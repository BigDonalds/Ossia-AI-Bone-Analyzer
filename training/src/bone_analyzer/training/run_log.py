"""The training log: a copy of everything a run prints, plus per-class detail after each epoch.

It is written as the run goes, so a run can be read back, or a crash diagnosed, later.
"""
import re
import sys

# The per-class tables go to the log only; True prints them on the console as well
DETAIL_ON_CONSOLE = False
_ANSI = re.compile(r'\x1b\[[0-9;]*m')
_log = None     # the open log file, once start() has been called


class Tee:
    """A console stream that also copies what it writes into the log, without colour codes."""

    def __init__(self, stream, log):
        self.stream, self.log = stream, log

    def write(self, text):
        # The file first, so it has every line even if the console fails on one
        self.log.write(_ANSI.sub('', text))
        self.log.flush()
        try:
            self.stream.write(text)
        except UnicodeEncodeError:      # a console that can't encode a character (cp1252 on Windows) gets '?'
            encoding = getattr(self.stream, 'encoding', None) or 'ascii'
            self.stream.write(text.encode(encoding, 'replace').decode(encoding))
        return len(text)

    def flush(self):
        self.stream.flush()
        self.log.flush()

    def __getattr__(self, name):    # isatty, encoding, fileno... answered by the real console
        return getattr(self.stream, name)


def start(path, append=False):
    """Open the log at path and copy stdout and stderr into it. Returns the open file."""
    global _log
    _log = open(path, 'a' if append else 'w', encoding='utf-8')
    sys.stdout = Tee(sys.stdout, _log)
    sys.stderr = Tee(sys.stderr, _log)
    return _log


def detail(text):
    """Detailed report lines: into the log (and the console if DETAIL_ON_CONSOLE)."""
    if DETAIL_ON_CONSOLE:
        print(text)
    elif _log is not None:
        _log.write(text + '\n')
        _log.flush()
