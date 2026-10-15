#!/usr/bin/env python3
"""Renders docs/screenshot.svg, the illustration of a retro-console window in the README."""
from html import escape
from pathlib import Path

THEMES = {"green": ("#33FF33", "#1A801A")}
CHAR_W, LINE_H, COLS, ROWS, PAD, TITLE_H = 8.4, 17, 78, 14, 14, 32
LINES = [
    "$ vpn",
    "[sudo] password for dev:",
    "2026-10-15 09:12:01 TUN/TAP device tun0 opened",
    "2026-10-15 09:12:02 Initialization Sequence Completed",
    "=====>> SUCCESS =====> connected",
    "",
    "",
]
TABS = [("1:VPN", "active"), ("2:port-forwards", "activity"), ("3:local-env", "")]


def text(x, y, content, color, weight="normal"):
    return (f'<text x="{x:.1f}" y="{y:.1f}" fill="{color}" font-weight="{weight}">'
            f"{escape(content)}</text>")


def status_bar(y, fg):
    parts, x = [], PAD
    for label, state in TABS:
        width = (len(label) + 2) * CHAR_W
        bg, color = {"active": (fg, "#000"), "activity": ("#FFFF00", "#000")}.get(state, ("#000", fg))
        parts.append(f'<rect x="{x:.1f}" y="{y - 13}" width="{width:.1f}" height="{LINE_H}" fill="{bg}"/>')
        parts.append(text(x + CHAR_W, y, label, color, "bold" if state == "active" else "normal"))
        x += width
    parts.append(text(PAD + (COLS - 6) * CHAR_W, y, "09:12", fg))
    return parts


def window(theme, x0):
    fg, _ = THEMES[theme]
    width, height = COLS * CHAR_W + 2 * PAD, ROWS * LINE_H + TITLE_H + 2 * PAD
    body = [f'<g transform="translate({x0},0)">',
            f'<rect width="{width:.1f}" height="{height}" rx="10" fill="#1e1e1e"/>',
            f'<text x="{width / 2:.1f}" y="21" fill="#ccc" text-anchor="middle" '
            f'font-family="sans-serif" font-size="13">Consoles</text>',
            f'<rect y="{TITLE_H}" width="{width:.1f}" height="{height - TITLE_H}" fill="#000"/>']
    for row, line in enumerate(LINES):
        body.append(text(PAD, TITLE_H + PAD + (row + 1) * LINE_H, line, fg))
    body.append(f'<rect x="{PAD:.1f}" y="{TITLE_H + PAD + 6 * LINE_H - 13}" '
                f'width="{CHAR_W:.1f}" height="{LINE_H}" fill="{fg}"/>')
    body += status_bar(TITLE_H + PAD + ROWS * LINE_H, fg)
    return body + ["</g>"], width, height


def main():
    green, width, height = window("green", 0)
    svg = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{width:.0f}" height="{height}" '
           f'font-family="DejaVu Sans Mono, monospace" font-size="14">', *green, "</svg>"]
    Path(__file__).with_name("screenshot.svg").write_text("\n".join(svg) + "\n")


if __name__ == "__main__":
    main()
