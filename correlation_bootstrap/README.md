# Correlation Boostrap Results

## Running the analyses
 - navigate to `../docker`
 - run `make rstudio`
 - run `make run-rstudio`
 - This will run `rstudio-server` in a docker container
   - Note: The code expects a 'nix based system
   - The dependency on `linboot` will require CUDA integration with docker `nvidia-docker2`
   - The container will launch with `rstudio-server` mapping to `localhost:9087` unless it is occupied, in which case it will randomly pick a port from `9000-9999`
 - Navigate to `workspace/correlation_bootstrap` in the `rstudio-server` web-interface
 - `boot_LW_v_others.R` will run the full analysis and place the results in `correlation_boostrap/results_data`
   - *Be sure to set the Session working directory!*


## Extras: Plotting Bootstrap Histograms
 - `linboot` produces histogram data for the bootstrapped parameters
 - run `plot_hist.R` to plot the histogram results from bootstrap procedure.
