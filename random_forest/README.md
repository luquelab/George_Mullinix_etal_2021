# Random Forest Analyses

## Dependencies
 - `RF_Bottom_Up_Assembly.R` sources `build_custom_trees.R` and `random_forest_coral.R`

## Execution Time Warning
 - `RF_Bottom_Up_Assembly.R` takes a _very_ long time to run

## Running the Analysis
 - Launch Rstudio Server container: `cd ../docker && make rstudio && make rstudio-run`
 - This will launch RStudio Server on port 9087, unless it is occupied, in which case it will pick a random port between 9000-9999
 - Notes:
   - Remember to set the workspace to the directory where the source files are.
   - You may need to install some R libraries -- once in RStudio Server, open each `.R` source file.
   - If a library needs to be installed, RStudio Server will provide a warning and the option to install -- choose to install.
