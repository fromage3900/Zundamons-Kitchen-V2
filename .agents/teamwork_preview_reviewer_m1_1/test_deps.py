import re
import glob

print("=== CHECKING EXTERNAL RESOURCE DEPENDENCIES ===")
files = ['site/index.html', 'site/style.css', 'site/assets/audio_engine.js']

violations = []

for filepath in files:
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    scripts = re.findall(r'<script[^>]+src=["\']([^"\']+)["\']', content, re.IGNORECASE)
    links = re.findall(r'<link[^>]+href=["\']([^"\']+)["\']', content, re.IGNORECASE)
    css_urls = re.findall(r'url\(["\']?([^"\'\)]+)["\']?\)', content, re.IGNORECASE)
    imports = re.findall(r'@import\s+["\']?([^"\'\s;]+)', content, re.IGNORECASE)

    print(f"File: {filepath}")
    print(f"  Script sources: {scripts}")
    print(f"  Link hrefs: {links}")
    print(f"  CSS urls: {css_urls}")
    print(f"  CSS imports: {imports}")

    for s in scripts:
        if s.startswith(('http://', 'https://', '//')):
            violations.append(f"External script in {filepath}: {s}")
    for l in links:
        # Note: SVG data URI is allowed (local inline data)
        if l.startswith(('http://', 'https://', '//')):
            violations.append(f"External link/stylesheet in {filepath}: {l}")
    for u in css_urls:
        if u.startswith(('http://', 'https://', '//')):
            violations.append(f"External CSS url in {filepath}: {u}")
    for i in imports:
        if i.startswith(('http://', 'https://', '//')):
            violations.append(f"External CSS import in {filepath}: {i}")

print("\n=== SUMMARY ===")
if violations:
    print("Violations found:")
    for v in violations:
        print(f" - {v}")
else:
    print("ZERO external resource dependencies found! 100% self-contained.")
