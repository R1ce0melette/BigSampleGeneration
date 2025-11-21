import os
import json
import re
import argparse
"""
Helper script compiles Solidity files into a JSONL dataset. The Solidity file structure is like so:
// Input prompt
pragma solidity ^x.x.x;
the actual code...
The script splits the file at the pragma line, collecting all preceding comment because they are input prompt.

Usage: python make_vuln_prompt_dataset.py <path-to-folder> <output-jsonl-file> [--pragma_pattern <regex>]
"""
def process_files(folder_path, output_file, pragma_pattern):
    pragma_regex = re.compile(pragma_pattern)

    with open(output_file, "w", encoding="utf-8") as jsonl_out:
        for filename in os.listdir(folder_path):
            if filename.endswith(".sol"):
                file_path = os.path.join(folder_path, filename)

                with open(file_path, "r", encoding="utf-8") as f:
                    lines = f.readlines()

                if not lines:
                    print(f"Skipping {filename}: file is empty")
                    continue

                # Extract source from first comment line
                first_line = lines[0].strip()
                if first_line.startswith("//"):
                    source = first_line[2:].strip()
                else:
                    source = ""

                # Find pragma line index
                split_index = None
                for i, line in enumerate(lines):
                    if pragma_regex.search(line):
                        split_index = i
                        break

                if split_index is None:
                    print(f"Skipping {filename}: no pragma line found")
                    continue

                # Output prompt = all comment lines before pragma except first comment (source)
                comment_lines_above = [
                    l for l in lines[1:split_index] if l.strip().startswith("//")
                ]
                output_prompt = "".join(comment_lines_above).strip()

                # Input code = pragma line and everything after
                input_code = "".join(lines[split_index:]).strip()

                # Build JSON object
                json_obj = {
                    "file_name": filename,
                    "source": source,
                    "output_prompt": output_prompt,
                    "input_code": input_code
                }

                # Write as JSONL
                jsonl_out.write(json.dumps(json_obj, ensure_ascii=False) + "\n")

    print(f"JSONL file created: {output_file}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Convert Solidity files to JSONL with split at pragma.")
    parser.add_argument("folder_path", help="Path to folder containing Solidity files")
    parser.add_argument("output_file", help="Path for the output JSONL file")
    parser.add_argument(
        "--pragma_pattern",
        default=r"^\s*pragma\s+solidity\b.*;",
        help="Regex pattern to detect pragma line (default matches any pragma solidity version)"
    )

    args = parser.parse_args()
    process_files(args.folder_path, args.output_file, args.pragma_pattern)
