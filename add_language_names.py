import json

# Add language name keys to all translation files
language_keys_en = {
    "language_es": "Spanish",
    "language_fr": "French",
    "language_de": "German"
}

language_keys_ar = {
    "language_es": "الإسبانية",
    "language_fr": "الفرنسية",
    "language_de": "الألمانية"
}

language_keys_es = {
    "language_es": "Español",
    "language_fr": "Francés",
    "language_de": "Alemán",
    "language_en": "Inglés",
    "language_ar": "Árabe"
}

language_keys_fr = {
    "language_es": "Espagnol",
    "language_fr": "Français",
    "language_de": "Allemand",
    "language_en": "Anglais",
    "language_ar": "Arabe"
}

language_keys_de = {
    "language_es": "Spanisch",
    "language_fr": "Französisch",
    "language_de": "Deutsch",
    "language_en": "Englisch",
    "language_ar": "Arabisch"
}

paths = {
    'en': r"f:\Ali\Projects\alionour33\dr_copilot\assets\translations\en.json",
    'ar': r"f:\Ali\Projects\alionour33\dr_copilot\assets\translations\ar.json",
    'es': r"f:\Ali\Projects\alionour33\dr_copilot\assets\translations\es.json",
    'fr': r"f:\Ali\Projects\alionour33\dr_copilot\assets\translations\fr.json",
    'de': r"f:\Ali\Projects\alionour33\dr_copilot\assets\translations\de.json"
}

all_keys = {
    'en': language_keys_en,
    'ar': language_keys_ar,
    'es': language_keys_es,
    'fr': language_keys_fr,
    'de': language_keys_de
}

for lang_code, path in paths.items():
    try:
        with open(path, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        added = 0
        for key, value in all_keys[lang_code].items():
            if key not in data:
                data[key] = value
                added += 1
                print(f"Added {lang_code}: {key} = {value}")
        
        with open(path, 'w', encoding='utf-8') as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
        
        if added > 0:
            print(f"✅ Added {added} keys to {lang_code}.json")
    except Exception as e:
        print(f"❌ Error processing {lang_code}.json: {e}")

print("\n✅ All language name keys added!")
