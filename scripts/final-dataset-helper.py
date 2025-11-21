import json
import csv
import sys
import os

"""
Helper script to parse from Slither detector summary JSON file and create a CSV mapping 
of file names to vulnerability names and model.

Usage: python final-dataset-helper.py <target_directory> <model>
"""
def create_vulnerability_mapping_csv(target_dir, model):    
    # Construct file paths
    json_file_path = os.path.join(target_dir, 'detectors_summary.json')
    output_file_path = os.path.join(target_dir, f'vulnerability_mapping_output_{model}.csv')
    
    # Check if input file exists
    if not os.path.exists(json_file_path):
        print(f"Error: Input file '{json_file_path}' not found.")
        return
    
    # Read the JSON file
    try:
        with open(json_file_path, 'r') as jsonfile:
            data = json.load(jsonfile)
    except json.JSONDecodeError as e:
        print(f"Error: Invalid JSON in '{json_file_path}': {e}")
        return
    except Exception as e:
        print(f"Error reading '{json_file_path}': {e}")
        return
    
    # Prepare output data
    output_rows = []
    
    # Process each file in the JSON
    for file_name, file_data in data.items():
        if isinstance(file_data, dict) and 'number_of_information_blocks' in file_data:
            # Iterate through all blocks
            for block_key, block_data in file_data.items():
                if block_key.startswith('block') and isinstance(block_data, dict):
                    if 'fragment_identifier' in block_data:
                        fragment_id = block_data['fragment_identifier']
                        
                        # Add row to output
                        output_rows.append([file_name, fragment_id, model])
    
    # Write to output CSV
    try:
        with open(output_file_path, 'w', newline='', encoding='utf-8') as outfile:
            writer = csv.writer(outfile)
            writer.writerow(['file_name', 'vuln_name', 'model'])
            writer.writerows(output_rows)
        
        print(f"Successfully created '{output_file_path}' with {len(output_rows)} rows")
        
        # Display first few rows as preview
        print("\nFirst 10 rows preview:")
        print("file_name, vuln_name, model")
        for row in output_rows[:10]:
            print(f"{row[0]}, {row[1]}, {row[2]}")
            
    except Exception as e:
        print(f"Error writing to '{output_file_path}': {e}")

def main():
    # Check command line arguments
    if len(sys.argv) != 3:
        print("Usage: python final-dataset-helper.py <target_directory> <model>")
        print("Example: python final-dataset-helper.py d:\\dataset\\ model_name")
        sys.exit(1)
    
    target_dir = sys.argv[1]
    model = sys.argv[2]
    
    # Check if target directory exists
    if not os.path.isdir(target_dir):
        print(f"Error: Directory '{target_dir}' does not exist.")
        sys.exit(1)
    
    print(f"Processing files in directory: {target_dir}")
    create_vulnerability_mapping_csv(target_dir, model)

if __name__ == "__main__":
    main()