import os
import re
import json

def extract_detectors_from_file(filepath):
    with open(filepath, "r", encoding="utf-8") as f:
        text = f.read()

    # Regex to capture the detector information and reference URLs
    pattern = r"INFO:Detectors:(.*?)Reference:\s*(https?://[^\s]+)"
    matches = re.findall(pattern, text, re.DOTALL)

    results = []
    for detector_info, reference_url in matches:
        # Extract fragment identifier from URL (part after #)
        fragment_match = re.search(r"#([^#\s]+)", reference_url)
        fragment = fragment_match.group(1) if fragment_match else ""
        
        results.append({
            "detector_info": detector_info.strip(),
            "reference_url": reference_url,
            "fragment_identifier": fragment
        })
    
    return results

def process_reports(output_file="detectors_summary.json"):
    results = {}

    # Scan current directory for *_report.txt files
    for file in os.listdir("."):
        if file.endswith("_report.txt"):
            detector_blocks = extract_detectors_from_file(file)
            entry = {
                "number_of_information_blocks": len(detector_blocks)
            }
            # Add block1, block2, ... with detector info and fragment identifiers
            for i, block in enumerate(detector_blocks, start=1):
                entry[f"block{i}"] = {
                    "detector_info": block["detector_info"],
                    "reference_url": block["reference_url"],
                    "fragment_identifier": block["fragment_identifier"]
                }
            results[file] = entry

    # Save to JSON
    with open(output_file, "w", encoding="utf-8") as out:
        json.dump(results, out, indent=4, ensure_ascii=False)

    print(f"Processed {len(results)} report files. Results saved to {output_file}")

if __name__ == "__main__":
    process_reports()
