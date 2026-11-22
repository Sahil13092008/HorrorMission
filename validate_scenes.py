import re
import sys

def validate_tscn(path):
    print(f"Validating {path}...")
    with open(path, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    sub_resources = set()
    ext_resources = set()
    errors = []

    for i, line in enumerate(lines, 1):
        line_s = line.strip()
        if line_s.startswith('[sub_resource'):
            m = re.search(r'\bid="([^"]+)"', line_s)
            if m: sub_resources.add(m.group(1))
        elif line_s.startswith('[ext_resource'):
            m = re.search(r'\bid="([^"]+)"', line_s)
            if m: ext_resources.add(m.group(1))

    for i, line in enumerate(lines, 1):
        for m in re.finditer(r'SubResource\("([^"]+)"\)', line):
            ref = m.group(1)
            if ref not in sub_resources:
                errors.append(f"Line {i}: Missing SubResource: {ref}")
        for m in re.finditer(r'ExtResource\("([^"]+)"\)', line):
            ref = m.group(1)
            if ref not in ext_resources:
                errors.append(f"Line {i}: Missing ExtResource: {ref}")

    if errors:
        print(f"Found {len(errors)} error(s) in {path}:")
        for e in errors[:10]:
            print("  ", e)
        return False
    else:
        print(f"OK: {path} is 100% valid with {len(sub_resources)} sub-resources and {len(ext_resources)} ext-resources!")
        return True

valid = True
for f in ["scenes/street_to_kripal.tscn", "scenes/police_station.tscn", "scenes/classroom.tscn", "scenes/bhangarh_ruins.tscn"]:
    if not validate_tscn(f):
        valid = False

sys.exit(0 if valid else 1)
