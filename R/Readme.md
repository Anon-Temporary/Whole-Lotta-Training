# Project Overview

This project involves data preparation, performing analysis, and rule extraction using a series of scripts. Below is a detailed description of each file in the folder and its role in the workflow.

## File Descriptions

1. **`1_Data_Prepare.Rmd`**  
   This script is the starting point of the workflow. It handles the preparation and preprocessing of data required for model training. Key tasks include:
   - Loading and cleaning the raw dataset.
   - Feature engineering and transformations.
   - Creation of sub-datasets related to oversampling and undersampling.

2. **`2_Performance_Analysis.Rmd`**  
   This script loads trained machine learning models and evaluates their performance. Key tasks include:
   - Measuring performance metrics like accuracy, precision, recall, etc.

3. **`3_Analysis.Rmd`**  
   This script conducts an in-depth analysis of the best-trained model. Key tasks include:
   - Generating visualizations and reports on model behavior.
   - Performing error analysis to identify areas for improvement.
   - Computing Shapley values.

4. **`4_Rule_Extraction.Rmd`**  
   This script extracts interpretable rules from the trained models. Key tasks include:
   - Translating model predictions into logical or human-readable rules.

5. **`NeuralNetworkAnalysis.R`**  
   This script contains a collection of helper functions used across the other scripts. These functions streamline repetitive tasks, enhance code modularity, and support the overall analysis.

## Execution Workflow

To achieve the desired outcomes, execute the scripts in the following order:
1. **`1_Data_Prepare.Rmd`**

2a. Manual training of neural networks.
   Train multiple neural network models: We trained multiple neural network models by invoking the command:
   ```r
   compute_NN_classification <- function(pdata = df_relevant3, target = "train",
                                         perr_fct = "ce",
                                         pact_fct = "logistic",
                                         palg = "rprop+",
                                         pthres = 0.01,
                                         pstepmax = 2e+05,
                                         fight_discrimination = FALSE,
                                         phid = 3,
                                         ptrain_itt = 20,
                                         pseed = 0)

```
from the R file NeuralNetworkAnalysis.R and saved the resulting models in a separate .Rdata file. These models will be used in the later part of the scripts. The seed ensures reproducibility of our results. As long as the data and model specifications do not change, a later invocation of this function will yield the same results. A complete list of all trained models will be provided upon publication.

2b. 2_Training_and_Performance.Rmd
3. 3_Analysis.Rmd
4. 4_Rule_Extraction.Rmd

Each step depends on the results of the previous script, so maintaining the sequence is crucial.

## Notes
Ensure all necessary libraries and dependencies are installed before running the scripts.
NeuralNetworkAnalysis.R should be sourced whenever its helper functions are required.

