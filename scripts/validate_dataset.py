#!/usr/bin/env python3
"""
validate_jsonl.py

Verify that a .jsonl file:
- Can be parsed as valid JSON
- Contains required fields: file_name, source, output_prompt, input_code
- Contains strings for all fields

Usage:
    python validate_jsonl.py solidity_dataset.jsonl
"""
import sys
import json

REQUIRED_FIELDS = {"file_name", "source", "output_prompt", "input_code"}

def validate_jsonl(file_path):
    valid_count = 0
    error_count = 0

    with open(file_path, "r", encoding="utf-8") as f:
        for lineno, line in enumerate(f, start=1):
            line = line.strip()
            if not line:
                continue  # skip blank lines

            try:
                obj = json.loads(line)
            except json.JSONDecodeError as e:
                print(f" Line {lineno}: Invalid JSON — {e}")
                error_count += 1
                continue

            # Check required fields
            missing = REQUIRED_FIELDS - obj.keys()
            if missing:
                print(f"Line {lineno}: Missing fields: {', '.join(missing)}")
                error_count += 1
                continue

            # Check that all required fields are strings
            for field in REQUIRED_FIELDS:
                if not isinstance(obj[field], str):
                    print(f"Line {lineno}: Field '{field}' is not a string")
                    error_count += 1
                    break
            else:
                valid_count += 1

    print(f"\n {valid_count} valid entries")
    if error_count > 0:
        print(f" {error_count} invalid entries")
        sys.exit(1)
    else:
        print(" All entries valid!")
        sys.exit(0)

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python validate_jsonl.py <jsonl_file>")
        sys.exit(1)

    validate_jsonl(sys.argv[1])
