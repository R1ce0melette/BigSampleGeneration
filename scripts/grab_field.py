import sys
import json

REQUIRED_FIELDS = {"file_name", "output_prompt"}

def load_file(file_path):
    data = []
    with open(file_path, "r", encoding="utf-8") as f:
        for lineno, line in enumerate(f, start=1):
            line = line.strip()
            if not line:
                continue  # skip blank lines

            try:
                obj = json.loads(line)
                data.append(obj)
            except json.JSONDecodeError as e:
                print(f" Line {lineno}: Invalid JSON — {e}")
                error_count += 1
                continue
    return data

def get_field(obj):
    out = {}
    for item in obj:
        if isinstance(item, dict):
            out[item["file_name"]] = item["output_prompt"]
    return out

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python grab_field.py <jsonl_file>")
        sys.exit(1)
    data = get_field(load_file(sys.argv[1]))
    # write key value in json format to 1 text file
    with open("input_prompt.json", "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=4)