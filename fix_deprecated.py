from pathlib import Path

replacements = {
    'const Color(0xFF38BDF8).withOpacity(0.30)': 'Color(0x4D38BDF8)',
    'const Color(0xFF2563EB).withOpacity(0.14)': 'Color(0x242563EB)',
    'const Color(0xFF14B8A6).withOpacity(0.22)': 'Color(0x3814B8A6)',
    'const Color(0xFF0EA5E9).withOpacity(0.10)': 'Color(0x190EA5E9)',
    'const Color(0xFF0F172A).withOpacity(0.06)': 'Color(0x0F0F172A)',
    'const Color(0xFF0F62FE).withOpacity(0.22)': 'Color(0x380F62FE)',
    'AppPalette.primary.withOpacity(0.25)': 'AppPalette.primary.withAlpha(64)',
    'getStatusColor(status).withOpacity(0.14)': 'getStatusColor(status).withAlpha(36)',
    'getStatusColor(status).withOpacity(0.13)': 'getStatusColor(status).withAlpha(33)',
    'statusColor.withOpacity(0.12)': 'statusColor.withAlpha(31)',
    'statusColor.withOpacity(0.35)': 'statusColor.withAlpha(89)',
    'value: selectedCity,': 'initialValue: selectedCity,',
    'value: rentType,': 'initialValue: rentType,',
}
root = Path('lib/screens')
for path in root.rglob('*.dart'):
    text = path.read_text(encoding='utf-8')
    updated = text
    for old, new in replacements.items():
        updated = updated.replace(old, new)
    if updated != text:
        path.write_text(updated, encoding='utf-8')
        print(f'Updated {path}')
