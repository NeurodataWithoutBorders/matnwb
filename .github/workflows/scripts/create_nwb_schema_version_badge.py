#!/usr/bin/env python3
"""Generate a badge showing the supported NWB schema version range."""

import argparse
import re
from pathlib import Path

from pybadges import badge


def get_schema_version_range(schema_dir: Path) -> tuple[str, str]:
    """
    Determine the minimum and maximum schema versions from folder names.
    
    Args:
        schema_dir: Path to the nwb-schema directory containing version folders.
        
    Returns:
        A tuple of (min_version, max_version) strings.
    """
    version_pattern = re.compile(r'^\d+\.\d+\.\d+$')
    versions = []
    
    for item in schema_dir.iterdir():
        if item.is_dir() and version_pattern.match(item.name):
            versions.append(item.name)
    
    if not versions:
        raise ValueError(f"No valid version folders found in {schema_dir}")
    
    # Sort versions semantically
    versions.sort(key=lambda v: tuple(map(int, v.split('.'))))
    
    return versions[0], versions[-1]


def create_badge(version: str, min_schema: str, max_schema: str, output_dir: Path) -> None:
    """
    Create and save the NWB schema version badge.
    
    Args:
        version: The matnwb version string.
        min_schema: Minimum supported schema version.
        max_schema: Maximum supported schema version.
        output_dir: Directory where the badge will be saved.
    """
    output_dir.mkdir(parents=True, exist_ok=True)
    output_path = output_dir / 'supported_nwb_schema.svg'
    
    badge_svg = badge(
        left_text='supported NWB schema',
        right_text=f'{min_schema} - {max_schema}',
        right_color='Teal'
    )
    
    with open(output_path, 'w') as f:
        f.write(badge_svg)
    
    print(f"Badge created: {output_path}")
    print(f"Schema version range: {min_schema} - {max_schema}")


def main():
    parser = argparse.ArgumentParser(
        description='Generate a badge showing the supported NWB schema version range.'
    )
    parser.add_argument(
        'version',
        help='The matnwb version string (e.g., 2.7.0)'
    )
    parser.add_argument(
        '--schema-dir',
        type=Path,
        default=None,
        help='Path to the nwb-schema directory (default: auto-detect from script location)'
    )
    parser.add_argument(
        '--output-dir',
        type=Path,
        default=None,
        help='Output directory for the badge (default: .github/badges/v<version>)'
    )
    
    args = parser.parse_args()
    
    # Determine the repository root (three levels up from this script)
    script_dir = Path(__file__).resolve().parent
    repo_root = script_dir.parent.parent.parent
    
    # Set default schema directory
    schema_dir = args.schema_dir or repo_root / 'nwb-schema'
    if not schema_dir.exists():
        raise FileNotFoundError(f"Schema directory not found: {schema_dir}")
    
    # Set default output directory
    output_dir = args.output_dir or repo_root / '.github' / 'badges' / f'v{args.version}'
    latest_dir = repo_root / '.github' / 'badges' / 'latest'
    
    # Get version range and create badge
    min_schema, max_schema = get_schema_version_range(schema_dir)
    create_badge(args.version, min_schema, max_schema, output_dir)
    create_badge(args.version, min_schema, max_schema, latest_dir)


if __name__ == '__main__':
    main()