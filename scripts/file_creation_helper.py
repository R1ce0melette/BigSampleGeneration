import json
import os
import sys

"""
Helper script to read prompt dataset and spawn all .sol files in the current working directory.

Usage: python file_creation_helper.py <jsonl_file>
"""
def create_sol_files_from_json(json_file):
    # Load the JSON file
    with open(json_file, "r", encoding="utf-8") as f:
        data = json.load(f)

    # Iterate over each key-value pair
    for filename, content in data.items():
        # Ensure filename ends with .sol
        if not filename.endswith(".sol"):
            filename += ".sol"

        # Write content to file in current working directory, adding '//' at the start
        with open(filename, "w", encoding="utf-8") as sol_file:
            sol_file.write('// ' + content)

        print(f"Created: {filename}")

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python file_creation_helper.py <jsonl_file>")
        sys.exit(1)
    create_sol_files_from_json(sys.argv[1])