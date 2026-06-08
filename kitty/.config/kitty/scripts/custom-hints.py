import re


def mark(text, args, Mark, extra_cli_args, *a):
    # Match URLs, paths with line numbers, and regular paths
    url_re = r'https?://[^\s<>\{\}\[\]"\'`]+'
    file_line_re = r"(?:\$[A-Za-z_][A-Za-z0-9_]*)?[a-zA-Z0-9._/~\-]+:\d+(?::\d+)?"
    # Paths: starting with ./, ~/, /, ../, or $VAR
    # Support Chinese and other Unicode characters in paths
    unicode_path_char = r"[\w./~\-]"
    path_re = rf"\$[A-Za-z_][A-Za-z0-9_]*(?:[/\\]{unicode_path_char}*)*|(?:[.~]?/|\.\/){unicode_path_char}+|[\w.\-]+\.[a-zA-Z][a-zA-Z0-9]{{0,9}}"

    # Datetime: ISO 8601 / full datetime first (most specific)
    datetime_re = r"\d{4}[-/]\d{2}[-/]\d{2}[T ]\d{2}:\d{2}(?::\d{2}(?:\.\d+)?)?(?:Z|[+-]\d{2}:?\d{2})?"
    # Date only: YYYY-MM-DD or YYYY/MM/DD
    date_re = r"\d{4}[-/]\d{2}[-/]\d{2}"
    # Time only: HH:MM:SS or HH:MM, allow surrounding [ ] ( ) or word boundary
    time_re = r"(?:(?<=\[)|(?<=\()|(?<!\d))\d{2}:\d{2}(?::\d{2}(?:\.\d+)?)?(?=\]|\)|(?!\d))"

    # Email address
    email_re = r"[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}"

    # IPv4: 0.0.0.0 to 255.255.255.255, optional port
    ipv4_re = r"\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}(?::\d+)?"
    # IPv6: full form, compressed with ::, optional port after brackets
    # Matches: 2001:db8::1, ::1, fe80::1, [::1]:8080
    ipv6_re = r"(?:[0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}|(?:[0-9a-fA-F]{1,4}:){1,7}:|(?:[0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|::(?:[0-9a-fA-F]{1,4}:){0,6}[0-9a-fA-F]{1,4}|\[(?:[0-9a-fA-F]{1,4}:){3,7}[0-9a-fA-F]{1,4}\](?::\d+)?"

    combined = f"({url_re})|({email_re})|({ipv6_re})|({ipv4_re})|({datetime_re})|({date_re})|({time_re})|({file_line_re})|({path_re})"

    all_matches = []
    for m in re.finditer(combined, text):
        start, end = m.span()
        match_text = text[start:end].strip()
        if len(match_text) < 2:
            continue
        match_text = match_text.replace("\n", "").replace("\0", "")
        all_matches.append((start, end, match_text))

    # Universal: match any non-whitespace text of 5+ chars, excluding regions
    # already covered by specific patterns above
    covered = [(s, e) for s, e, _ in all_matches]
    for m in re.finditer(r"\S+", text):
        start, end = m.span()
        if any(not (end <= s or start >= e) for s, e in covered):
            continue
        match_text = text[start:end]
        if len(match_text) < 5:
            continue
        # Skip lines that are mostly box-drawing/special Unicode decoration
        if all(not c.isalnum() for c in match_text):
            continue
        match_text = match_text.replace("\n", "").replace("\0", "")
        all_matches.append((start, end, match_text))

    all_matches.sort()
    for idx, (start, end, match_text) in enumerate(all_matches):
        yield Mark(idx, start, end, match_text, {})
