import re


def mark(text, args, Mark, extra_cli_args, *a):
    # Match URLs, paths with line numbers, and regular paths
    url_re = r'https?://[^\s<>\{\}\[\]"\'`]+'
    file_line_re = r"[a-zA-Z0-9._/~\-]+:\d+(?::\d+)?"
    # Paths: starting with ./, ~/, /, ../ or having extensions
    # Support Chinese and other Unicode characters in paths
    unicode_path_char = r"[\w./~\-]"
    path_re = rf"(?:[.~]?/|\.\/){unicode_path_char}+|[\w.\-]+\.[a-zA-Z]{{1,10}}"

    combined = f"({url_re})|({file_line_re})|({path_re})"

    for idx, m in enumerate(re.finditer(combined, text)):
        start, end = m.span()
        match_text = text[start:end].strip()
        if len(match_text) < 2:
            continue
        match_text = match_text.replace("\n", "").replace("\0", "")
        yield Mark(idx, start, end, match_text, {})
