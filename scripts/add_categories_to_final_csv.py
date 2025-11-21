#!/usr/bin/env python3
"""
add_categories_to_final_csv.py

Reads a final CSV (with a `file_name` column and `prompt_type` column) and a mapping CSV
(`prompt,category` pairs). If a `prompt_x` string from the mapping is found inside the
`file_name`, its category is appended to `prompt_type` (deduplicated). The updated CSV
is written to an output file.

Usage:
    python add_categories_to_final_csv.py -i ../presenting/final-1000.csv -m ../prompts/solidity_35_category.csv -o ../presenting/final-1000.with_categories.csv

Assumptions:
- The mapping CSV has header columns named exactly: `prompt` and `category`.
- The final CSV has headers including `file_name` and `prompt_type`.
- Categories will be appended to `prompt_type` separated by " | ". Existing `prompt_type`
  values are preserved and duplicates avoided.

This script uses only the Python standard library.
"""

import re
import csv
import argparse
import os
import sys

PROMPT_PATTERN = re.compile(r'prompt_\d+')


def load_mapping(mapping_path):
    mapping = {}
    with open(mapping_path, newline='', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        # Expect columns: 'prompt' and 'category'
        if 'prompt' not in reader.fieldnames or 'category' not in reader.fieldnames:
            raise ValueError("Mapping CSV must have 'prompt' and 'category' columns")
        for row in reader:
            key = row['prompt'].strip()
            cat = row['category'].strip()
            if key:
                mapping[key] = cat
    return mapping


def update_rows(rows, mapping):
    updated_count = 0
    for row in rows:
        file_name = row.get('file_name', '') or ''
        found = PROMPT_PATTERN.findall(file_name)
        found = list(dict.fromkeys(found))  # preserve order, deduplicate
        categories = []
        for p in found:
            cat = mapping.get(p)
            if cat:
                categories.append(cat)
        if categories:
            existing = (row.get('prompt_type') or '').strip()
            existing_parts = [p.strip() for p in existing.split('|')] if existing else []
            # Remove empty strings
            existing_parts = [p for p in existing_parts if p]
            changed = False
            for c in categories:
                if c not in existing_parts:
                    existing_parts.append(c)
                    changed = True
            if changed:
                row['prompt_type'] = ' | '.join(existing_parts)
                updated_count += 1
    return updated_count


def read_csv(path):
    with open(path, newline='', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        rows = list(reader)
        fieldnames = reader.fieldnames
    return rows, fieldnames


def write_csv(path, rows, fieldnames):
    # Ensure the directory exists
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'w', newline='', encoding='utf-8') as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        for r in rows:
            writer.writerow(r)


def main():
    parser = argparse.ArgumentParser(description="Append categories to prompt_type in final CSV based on prompt_x found in file_name")
    parser.add_argument('-i', '--input', required=True, help="Path to final CSV (e.g., presenting/final-1000.csv)")
    parser.add_argument('-m', '--mapping', required=True, help="Path to mapping CSV (e.g., prompts/solidity_35_category.csv)")
    parser.add_argument('-o', '--output', required=False, help="Output CSV path. If not set and --inplace not used, defaults to input.with_categories.csv")
    parser.add_argument('--inplace', action='store_true', help="Overwrite the input file with changes")

    args = parser.parse_args()

    input_path = args.input
    mapping_path = args.mapping
    if args.output:
        output_path = args.output
    else:
        base, ext = os.path.splitext(input_path)
        output_path = base + '.with_categories' + (ext or '.csv')

    if args.inplace:
        output_path = input_path

    try:
        mapping = load_mapping(mapping_path)
    except Exception as e:
        print(f"Error reading mapping file: {e}", file=sys.stderr)
        sys.exit(2)

    try:
        rows, fieldnames = read_csv(input_path)
    except Exception as e:
        print(f"Error reading input CSV: {e}", file=sys.stderr)
        sys.exit(2)

    if 'file_name' not in fieldnames or 'prompt_type' not in fieldnames:
        print("Input CSV must contain 'file_name' and 'prompt_type' columns", file=sys.stderr)
        sys.exit(2)

    updated = update_rows(rows, mapping)

    try:
        write_csv(output_path, rows, fieldnames)
    except Exception as e:
        print(f"Error writing output CSV: {e}", file=sys.stderr)
        sys.exit(2)

    print(f"Done. Rows processed: {len(rows)}. Rows updated: {updated}. Output written to: {output_path}")


if __name__ == '__main__':
    main()
