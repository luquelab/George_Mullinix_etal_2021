# George_Mullinix_etal_2021
 - Post-Measurement Analysis Source Code

## Structure
 - Requires coral measurement CSV file: <URL FOR FILE ON DRYAD HERE>
 - `correlation_bootstrap`: Runner methods for calculating correlations via nonparametric bootstrap
   - _Depends on `linboot`, see `correlation_bootstrap/Readme.md`_
 - `random_forest`: Random forest analysis methods
 - `docker`: Container recipes and runners

## Usage
 - See the documentation in each directory for details.
 - Notes:
   - `correlation_bootstrap` requires `nvidia-docker2` support, which is currently unavailable outside of linux. As such, the data have been calculated and stored on Dryad: <URL FOR FILE ON DRYAD HERE>
   - `random_forest/RF_Bottom_Up_Assembly.R` takes a long time to complete.
