import os
import re
import xml.etree.ElementTree as ET
import json

SITE_DIR = r"g:\Zundamons-kItchen-V2\site"
ASSETS_DIR = os.path.join(SITE_DIR, "assets")

results = {
    "task1_responsive_and_modals": [],
    "task2_css_cascade": [],
    "task3_svg_validation": [],
    "task4_zero_dependency_audit": []
}

print("=== STARTING EMPIRICAL SUITE FOR ZUNDA-OS 95 SITE ===")

# --- TASK 3: SVG VALIDATION ---
svg_files = ["pea_pod.svg", "zundamon_mochi.svg", "crt_monitor.svg", "disc_icon.svg"]
for svg_name in svg_files:
    svg_path = os.path.join(ASSETS_DIR, svg_name)
    if not os.path.exists(svg_path):
        results["task3_svg_validation"].append({
            "file": svg_name, "status": "FAIL", "reason": "File missing"
        })
        continue

    try:
        tree = ET.parse(svg_path)
        root = tree.getroot()
        
        # Check XML root tag
        if not root.tag.endswith("svg"):
            results["task3_svg_validation"].append({
                "file": svg_name, "status": "FAIL", "reason": f"Root tag is {root.tag}, expected svg"
            })
            continue

        with open(svg_path, "r", encoding="utf-8") as f:
            content = f.read()

        issues = []
        # Check for external references / image tags / script tags
        if "<image" in content.lower():
            issues.append("Contains <image> element")
        if "xlink:href" in content.lower():
            issues.append("Contains xlink:href attribute")
        if "href=" in content.lower() and not content.lower().count("xmlns=") > 0:
            # check if href points to external
            hrefs = re.findall(r'href=["\']([^"\']+)["\']', content)
            for h in hrefs:
                if not h.startswith("#"):
                    issues.append(f"External href reference: {h}")
        if "<script" in content.lower():
            issues.append("Contains <script> element")
        if "http://" in content.lower() or "https://" in content.lower():
            # Check if it's only xmlns
            urls = re.findall(r'https?://[^\s"\'>]+', content)
            for url in urls:
                if url != "http://www.w3.org/2000/svg" and url != "http://www.w3.org/1999/xlink":
                    issues.append(f"External URL found: {url}")

        if issues:
            results["task3_svg_validation"].append({
                "file": svg_name, "status": "FAIL", "issues": issues
            })
        else:
            results["task3_svg_validation"].append({
                "file": svg_name, "status": "PASS", "viewBox": root.attrib.get("viewBox"), "width": root.attrib.get("width"), "height": root.attrib.get("height")
            })

    except ET.ParseError as e:
        results["task3_svg_validation"].append({
            "file": svg_name, "status": "FAIL", "reason": f"XML Parse Error: {str(e)}"
        })

# --- TASK 4: ZERO DEPENDENCY & NETWORK AUDIT ---
all_files = [
    os.path.join(SITE_DIR, "index.html"),
    os.path.join(SITE_DIR, "style.css"),
    os.path.join(ASSETS_DIR, "audio_engine.js"),
] + [os.path.join(ASSETS_DIR, f) for f in svg_files]

network_keywords = ["fetch(", "xmlhttprequest", "websocket", "sendbeacon", "eventsource", "importscripts"]
url_regex = re.compile(r'(https?://[^\s"\'<>)]+|//[^\s"\'<>)]+)')

for file_path in all_files:
    rel_path = os.path.relpath(file_path, SITE_DIR)
    with open(file_path, "r", encoding="utf-8") as f:
        content = f.read()

    file_issues = []
    
    # Check network API usages
    content_lower = content.lower()
    for kw in network_keywords:
        if kw in content_lower:
            file_issues.append(f"Network API detected: '{kw}'")

    # Check external URLs
    matches = url_regex.findall(content)
    for m in matches:
        # Ignore standard W3C XML namespaces and standard informational links in HTML text/comments
        if m in ["http://www.w3.org/2000/svg", "http://www.w3.org/1999/xlink"]:
            continue
        # Check if URL is loaded as remote resource (script, stylesheet, font, image, iframe) vs plain informational link text
        # If in index.html, check tag type
        if "github.com" in m or "roblox.com" in m:
            file_issues.append(f"Hyperlink text to external site (anchor href): {m}")
        else:
            file_issues.append(f"External URL reference: {m}")

    # Check CSS @import or @font-face external URLs
    if file_path.endswith(".css"):
        if "@import" in content:
            file_issues.append("Contains CSS @import statement")
        font_urls = re.findall(r'@font-face[^{]*{[^}]*url\(([^)]+)\)', content)
        for fu in font_urls:
            file_issues.append(f"@font-face remote url: {fu}")

    results["task4_zero_dependency_audit"].append({
        "file": rel_path,
        "issues": file_issues
    })


# --- TASK 2: CSS VARIABLE CASCADE ---
style_path = os.path.join(SITE_DIR, "style.css")
with open(style_path, "r", encoding="utf-8") as f:
    css_content = f.read()

# Extract declared variables in :root
root_vars = set(re.findall(r'(--[a-zA-Z0-9_-]+)\s*:', css_content))

# Extract all var(--xxx) usages
used_vars = set(re.findall(r'var\((--[a-zA-Z0-9_-]+)\)', css_content))

missing_vars = used_vars - root_vars
results["task2_css_cascade"].append({
    "declared_in_root_count": len(root_vars),
    "used_vars_count": len(used_vars),
    "missing_vars": list(missing_vars)
})

# Check data-theme support in CSS vs JS
html_path = os.path.join(SITE_DIR, "index.html")
with open(html_path, "r", encoding="utf-8") as f:
    html_content = f.read()

has_data_theme_js = "data-theme" in html_content
has_data_theme_css = "data-theme" in css_content

results["task2_css_cascade"].append({
    "data_theme_in_html_js": has_data_theme_js,
    "data_theme_in_css": has_data_theme_css,
    "theme_toggle_issue": (has_data_theme_js and not has_data_theme_css)
})


# --- TASK 1: RESPONSIVE BREAKPOINTS & MODAL FALLBACK ANALYSIS ---
# Check media queries in style.css
media_queries = re.findall(r'@media[^{]+\{', css_content)
results["task1_responsive_and_modals"].append({
    "media_queries_found": [mq.strip() for mq in media_queries]
})

# Check 768px taskbar height discrepancy
taskbar_root = re.search(r'--taskbar-height:\s*([^;]+);', css_content)
taskbar_root_val = taskbar_root.group(1).strip() if taskbar_root else None

# Check taskbar height in media query <=768px
mobile_taskbar = re.search(r'@media[^{]*max-width:\s*768px[^{]*\{[^}]*#taskbar\s*\{[^}]*height:\s*([^;]+);', css_content, re.DOTALL)
mobile_taskbar_val = mobile_taskbar.group(1).strip() if mobile_taskbar else None

results["task1_responsive_and_modals"].append({
    "root_taskbar_height_var": taskbar_root_val,
    "mobile_taskbar_element_height": mobile_taskbar_val,
    "taskbar_height_mismatch": (taskbar_root_val != mobile_taskbar_val)
})

# Save empirical verification summary to JSON
with open(r"g:\Zundamons-kItchen-V2\.agents\teamwork_preview_challenger_m1_2\verification_results.json", "w", encoding="utf-8") as f:
    json.dump(results, f, indent=2)

print("SUITE COMPLETED. Results written to verification_results.json")
