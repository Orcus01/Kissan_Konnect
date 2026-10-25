"""Create a pinned sibling checkout without altering an existing checkout."""
import json
from pathlib import Path
import shutil
import subprocess
import sys

root = Path(__file__).resolve().parents[1]
lock = json.loads((root / 'ml-service.lock.json').read_text())
checkout = Path(sys.argv[1]).expanduser().resolve()
if not checkout.exists():
    if shutil.which('gh'):
        subprocess.run(['gh', 'repo', 'clone', lock['repository'], str(checkout), '--', '--no-checkout'], check=True)
    else:
        subprocess.run(['git', 'clone', '--no-checkout', lock['repository'], str(checkout)], check=True)
    subprocess.run(['git', '-C', str(checkout), 'checkout', '--detach', lock['revision']], check=True)
head = subprocess.check_output(['git', '-C', str(checkout), 'rev-parse', 'HEAD'], text=True).strip()
if head != lock['revision']:
    raise SystemExit(f"ML checkout is at {head}, but this app pins {lock['revision']}. Your checkout was preserved. Use a matching checkout through KISSAN_ML_DIR or update ml-service.lock.json deliberately.")
if not (checkout / 'model_service/app.py').is_file():
    raise SystemExit('The selected checkout does not contain the ML service.')
print(f'Using ML service revision {head[:12]} at {checkout}')
