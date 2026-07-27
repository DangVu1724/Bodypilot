import pandas as pd
import os

files_to_process = [
    ("vietnamese_foods.csv", "vietnamese_foods_import.csv"),
    ("usda_foods.csv", "usda_foods_import.csv"),
    ("opennutrition_foods.csv", "opennutrition_foods_import.csv")
]

data_dir = r"c:\Personal\DATN\BodyPilot\data"

print("Generating import-ready CSV files (clearing default_serving_id)...")

for src_name, dest_name in files_to_process:
    src_path = os.path.join(data_dir, src_name)
    dest_path = os.path.join(data_dir, dest_name)
    
    if os.path.exists(src_path):
        print(f"Processing {src_name} -> {dest_name}...")
        # Since opennutrition_foods.csv is large, we load it with pandas and empty the default_serving_id column
        if src_name == "opennutrition_foods.csv":
            # Process in chunks to save memory
            chunk_size = 50000
            first_chunk = True
            for chunk in pd.read_csv(src_path, chunksize=chunk_size, low_memory=False):
                chunk['default_serving_id'] = None
                if first_chunk:
                    chunk.to_csv(dest_path, index=False, mode='w')
                    first_chunk = False
                else:
                    chunk.to_csv(dest_path, index=False, mode='a', header=False)
        else:
            df = pd.read_csv(src_path)
            df['default_serving_id'] = None
            df.to_csv(dest_path, index=False)
            
        print(f"Created: {dest_path}")
    else:
        print(f"Skipping {src_name} (file not found).")

print("\nAll import-ready files generated successfully!")
