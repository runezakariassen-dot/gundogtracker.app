import json
from pathlib import Path

def load(path):
    with open(path, 'r', encoding='utf-8') as f:
        return json.load(f)

base = load('lib/l10n/app_nb.arb')
da = load('lib/l10n/app_da.arb')
sv = load('lib/l10n/app_sv.arb')

base_keys = [k for k in base.keys() if not k.startswith('@')]

def missing(target):
    return [k for k in base_keys if k not in target]

def missing_both(first, second):
    return [k for k in base_keys if k not in first and k not in second]

miss_da = missing(da)
miss_sv = missing(sv)
miss_both = missing_both(da, sv)

print('Missing in both (first 25):')
print('\n'.join(miss_both[:25]))
print('\nMissing in DA:', len(miss_da))
print('\n'.join(miss_da[:50]))
print('\n---\nMissing in SV:', len(miss_sv))
print('\n'.join(miss_sv[:50]))
