import hashlib
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

SCRIPT = Path(__file__).resolve().parents[1] / '.agents/skills/octopus-jps-transcription-review/scripts/linux-review.py'


class LinuxReviewTest(unittest.TestCase):
    def run_helper(self, *args, ok=True):
        result = subprocess.run([sys.executable, str(SCRIPT), *map(str, args)], capture_output=True, text=True)
        self.assertEqual(result.returncode == 0, ok, result.stderr)
        return result.stdout

    def test_workspace_and_export_safety(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            image = root / '音符.jpg'
            image.write_bytes(b'image')
            output = root / 'review'
            default = subprocess.run(
                [sys.executable, str(SCRIPT), 'prepare', str(image)], cwd=root,
                capture_output=True, text=True, check=True,
            )
            default_dir = Path(default.stdout.split('OutputDirectory: ', 1)[1].strip())
            self.assertTrue(default_dir.is_dir())
            self.assertEqual(default_dir.parent, root / 'output')
            result = self.run_helper('prepare', image, '--output', output)
            self.assertIn(hashlib.sha256(b'image').hexdigest(), result)
            self.run_helper('prepare', image, '--output', output, ok=False)
            self.assertEqual(image.read_bytes(), b'image')
            invalid = root / 'bad.txt'
            invalid.write_text('x')
            self.run_helper('prepare', invalid, '--output', root / 'bad', ok=False)
            self.assertFalse((root / 'bad').exists())
            wrapped = root / 'wrapped.jps'
            wrapped.write_text(json.dumps({'code': 'B: 音符\n'}, ensure_ascii=False))
            plain = output / 'plain.jps'
            self.run_helper('export', wrapped, plain)
            self.assertEqual(plain.read_text(), 'B: 音符\n')
            self.run_helper('export', wrapped, plain, ok=False)
            self.run_helper('export', plain, plain, ok=False)
            self.assertEqual(plain.read_text(), 'B: 音符\n')
            copy = output / 'copy.jps'
            self.run_helper('export', plain, copy)
            self.assertEqual(copy.read_text(), plain.read_text())
            wrapped.write_text(json.dumps({'code': 3}))
            self.run_helper('export', wrapped, output / 'invalid.jps', ok=False)
            self.assertFalse((output / 'invalid.jps').exists())
            wrapped.write_text('{broken')
            self.run_helper('export', wrapped, output / 'invalid.jps', ok=False)
            self.assertFalse((output / 'invalid.jps').exists())


if __name__ == '__main__':
    unittest.main()
