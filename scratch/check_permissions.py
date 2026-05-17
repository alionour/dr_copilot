import os
import re

lib_dir = r"f:\Projects\My_Clinic_Manager\dr_copilot\lib"
permission_enum_file = r"f:\Projects\My_Clinic_Manager\dr_copilot\lib\src\features\auth\domain\models\permission_enum.dart"

def get_defined_permissions():
    perms = set()
    try:
        with open(permission_enum_file, 'r', encoding='utf-8') as f:
            lines = f.readlines()
            in_enum = False
            for line in lines:
                if 'enum AppPermission {' in line:
                    in_enum = True
                    continue
                if in_enum and '}' in line:
                    break
                if in_enum:
                    match = re.match(r'^\s*([a-zA-Z0-9_]+),?', line)
                    if match:
                        perms.add(match.group(1))
    except Exception as e:
        print(f"Error reading enum file: {e}")
    return perms

def check_usages(defined_perms):
    usages = {p: [] for p in defined_perms}
    pattern = re.compile(r'AppPermission\.([a-zA-Z0-9_]+)')
    
    for root, dirs, files in os.walk(lib_dir):
        for file in files:
            if file.endswith('.dart'):
                filepath = os.path.join(root, file)
                # Ignore the enum file itself, role_defaults, and create_invitation_page (where all are listed)
                if 'permission_enum.dart' in file or 'role_defaults.dart' in file or 'create_invitation_page.dart' in file:
                    continue
                try:
                    with open(filepath, 'r', encoding='utf-8') as f:
                        lines = f.readlines()
                        for i, line in enumerate(lines):
                            matches = pattern.findall(line)
                            for match in matches:
                                if match in usages:
                                    usages[match].append(f"{os.path.relpath(filepath, lib_dir)}:{i+1}")
                except:
                    pass
    return usages

if __name__ == "__main__":
    perms = get_defined_permissions()
    usages = check_usages(perms)
    
    used = []
    unused = []
    
    for p, locs in usages.items():
        if locs:
            used.append((p, locs))
        else:
            unused.append(p)
            
    print("--- UNUSED OR UNENFORCED PERMISSIONS ---")
    for p in sorted(unused):
        print(f"- {p}")
        
    print("\n--- ENFORCED PERMISSIONS ---")
    for p, locs in sorted(used, key=lambda x: len(x[1])):
        print(f"- {p} ({len(locs)} usages)")
        # Print up to 3 usages
        for loc in locs[:3]:
            print(f"    {loc}")
