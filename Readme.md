# Data Preparation Scripts

This folder contains two Stata scripts designed for preparing datasets for analysis:

## Scripts Overview

1. **`merging_script_school_data.do`**  
   - **Purpose**: Creates a separate dataset containing average marks per school.  
   - **Usage**: This script must be run **first** to ensure the required intermediate dataset is available.

2. **`merging_script_final.do`**  
   - **Purpose**: Merges all datasets, including the school data created by the first script, into a final, comprehensive dataset.  
   - **Usage**: Run this script **after** `merging_script_school_data.do`.

## Execution Order
1. Run `merging_script_school_data.do`.  
2. Run `merging_script_final.do`.

Ensure all required input datasets are in the appropriate directory before running the scripts.
