#!/usr/bin/env python3
"""Prepare a review workspace or extract plain JPS without overwriting files."""
import argparse
import hashlib
import json
from pathlib import Path
import tempfile


def source_file(value):
    path = Path(value).expanduser().resolve(strict=True)
    if not path.is_file():
        raise ValueError('input must be a file')
    return path


def digest(path):
    with path.open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()


def prepare(args):
    source = source_file(args.input)
    if source.suffix.lower() not in {'.png', '.jpg', '.jpeg', '.pdf'}:
        raise ValueError('input must be a PNG, JPG, JPEG or PDF file')
    checksum = digest(source)
    if args.output:
        target = Path(args.output).expanduser().absolute()
        target.mkdir(parents=True, exist_ok=False)
    else:
        parent = Path.cwd() / 'output'
        parent.mkdir(parents=True, exist_ok=True)
        target = Path(tempfile.mkdtemp(prefix=f'{source.stem}-', dir=parent))
    print(f'SourcePath: {source}\nSourceSha256: {checksum}\nOutputDirectory: {target}')


def export(args):
    source = source_file(args.input)
    target = Path(args.output).expanduser().absolute()
    if target.suffix.lower() != '.jps':
        raise ValueError('output must end in .jps')
    text = source.read_text(encoding='utf-8-sig')
    if text.lstrip().startswith('{'):
        document = json.loads(text)
        if not isinstance(document, dict) or not isinstance(document.get('code'), str):
            raise ValueError('OctoPus JSON document must contain a string code field')
        text = document['code']
    with target.open('x', encoding='utf-8', newline='') as stream:
        stream.write(text)
    print(f'InputPath: {source}\nOutputPath: {target}\nSha256: {digest(target)}')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest='command', required=True)
    workspace = commands.add_parser('prepare')
    workspace.add_argument('input')
    workspace.add_argument('--output')
    workspace.set_defaults(func=prepare)
    plain = commands.add_parser('export')
    plain.add_argument('input')
    plain.add_argument('output')
    plain.set_defaults(func=export)
    args = parser.parse_args()
    try:
        args.func(args)
    except (OSError, ValueError) as error:
        parser.exit(1, f'{error}\n')


if __name__ == '__main__':
    main()
