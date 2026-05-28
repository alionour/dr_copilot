import os
import re
import json

project_dir = r"f:\Projects\My_Clinic_Manager\dr_copilot"
lib_dir = os.path.join(project_dir, "lib")
translations_dir = os.path.join(project_dir, "assets", "translations")

languages = ["en", "ar", "de", "es", "fr"]

# Load translations
translations = {}
for lang in languages:
    path = os.path.join(translations_dir, f"{lang}.json")
    if os.path.exists(path):
        with open(path, "r", encoding="utf-8") as f:
            try:
                translations[lang] = json.load(f)
                print(f"Loaded {lang}.json with {len(translations[lang])} keys.")
            except Exception as e:
                print(f"Error loading {lang}.json: {e}")
    else:
        print(f"File not found: {path}")

en_keys = set(translations.get("en", {}).keys())

# 1. Compare other languages with en.json
print("\n--- Cross-Language Key Comparison (Comparing with en.json) ---")
for lang in languages:
    if lang == "en":
        continue
    lang_keys = set(translations.get(lang, {}).keys())
    missing_in_lang = en_keys - lang_keys
    extra_in_lang = lang_keys - en_keys
    print(f"{lang}.json: missing {len(missing_in_lang)} keys, has {len(extra_in_lang)} extra keys compared to en.json")
    if missing_in_lang and len(missing_in_lang) <= 20:
        print(f"  Missing in {lang}: {sorted(list(missing_in_lang))}")
    if extra_in_lang and len(extra_in_lang) <= 20:
        print(f"  Extra in {lang}: {sorted(list(extra_in_lang))}")

# 2. Extract keys used in .dart files with .tr()
print("\n--- Analyzing Dart files for .tr() usages ---")
tr_pattern = re.compile(r"['\"]([^'\"]+)['\"]\.(?:tr|translate)\(\)")
used_keys = {}

for root, _, files in os.walk(lib_dir):
    for file in files:
        if file.endswith(".dart"):
            path = os.path.join(root, file)
            with open(path, "r", encoding="utf-8", errors="ignore") as f:
                content = f.read()
                matches = tr_pattern.findall(content)
                for match in matches:
                    if match not in used_keys:
                        used_keys[match] = []
                    rel_path = os.path.relpath(path, project_dir)
                    used_keys[match].append(rel_path)

print(f"Found {len(used_keys)} unique translation keys used in Dart files.")

# Compare used keys with en.json
missing_keys_in_en = []
for key, files in used_keys.items():
    if key not in en_keys:
        missing_keys_in_en.append((key, files[0]))

print(f"Found {len(missing_keys_in_en)} keys used in code but missing from en.json:")
for key, file in sorted(missing_keys_in_en, key=lambda x: x[0]):
    print(f"  - '{key}' (used in: {file})")

# Let's save a detailed report
report = {
    "missing_keys_in_en": [
        {"key": key, "file": file} for key, file in sorted(missing_keys_in_en, key=lambda x: x[0])
    ],
    "missing_in_other_languages": {}
}

for lang in languages:
    if lang == "en":
        continue
    lang_keys = set(translations.get(lang, {}).keys())
    missing = en_keys - lang_keys
    report["missing_in_other_languages"][lang] = sorted(list(missing))

with open(os.path.join(project_dir, "scratch", "l10n_report.json"), "w", encoding="utf-8") as f:
    json.dump(report, f, indent=2, ensure_ascii=False)
print("\nSaved detailed report to scratch/l10n_report.json")
