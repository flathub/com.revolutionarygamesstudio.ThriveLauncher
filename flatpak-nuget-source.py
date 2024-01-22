#!/usr/bin/env python3
# Handles extracting flatpak source compatible package references from .nupkg files.
# Run this through "update_sources.sh" script as it depends on the intermediate output of that.

# Takes two parameters as paths to the output file and input folder.

# This script are derived from the extractor available here:
# https://github.com/flatpak/flatpak-builder-tools/tree/master/dotnet

# This whole script is licensed under the MIT license (c) Revolutionary Games Studio 2024 and
# original authors of flatpak-builder-tools

__license__ = 'MIT'

from pathlib import Path

import argparse
import base64
import binascii
import json


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('output', help='The output JSON sources file')
    parser.add_argument('input', help='The folder containing nuget package files to process')
    parser.add_argument('--destdir',
                        help='The directory the generated sources file will save sources to',
                        default='nuget-sources')

    args = parser.parse_args()

    sources = []

    for path in Path(args.input).glob('**/*.nupkg.sha512'):
        name = path.parent.parent.name
        version = path.parent.name
        filename = '{}.{}.nupkg'.format(name, version)
        url = 'https://api.nuget.org/v3-flatcontainer/{}/{}/{}'.format(name, version,
                                                                       filename)

        with path.open() as fp:
            sha512 = binascii.hexlify(base64.b64decode(fp.read())).decode('ascii')

        sources.append({
            'type': 'file',
            'url': url,
            'sha512': sha512,
            'dest': args.destdir,
            'dest-filename': filename,
        })

    if len(sources) < 2:
        print("No nuget package sources found")
        exit(2)
        
    with open(args.output, 'w') as fp:
        json.dump(
            sorted(sources, key=lambda n: n.get("dest-filename")),
            fp,
            indent=4
        )


if __name__ == '__main__':
    main()
