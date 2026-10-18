"""Coloured terminal output."""


class Colors:
    RED = '\033[31m'
    GREEN = '\033[32m'
    YELLOW = '\033[33m'
    BLUE = '\033[34m'
    MAGENTA = '\033[35m'
    CYAN = '\033[36m'
    BRIGHT_BLUE = '\033[94m'
    BRIGHT_CYAN = '\033[96m'
    END = '\033[0m'
    BOLD = '\033[1m'


def print_colored(text, color=Colors.END, bold=False):
    prefix = Colors.BOLD if bold else ''
    print(f'{prefix}{color}{text}{Colors.END}')


def print_header(text):
    print_colored(text, Colors.BLUE, bold=True)


def print_ok(text):
    print_colored(text, Colors.GREEN)


def print_warn(text):
    print_colored(text, Colors.YELLOW)


def print_error(text):
    print_colored(text, Colors.RED, bold=True)


def print_separator(char='=', length=50, color=Colors.BLUE):
    print_colored(char * length, color, bold=True)
