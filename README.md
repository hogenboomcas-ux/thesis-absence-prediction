# Predicting Employee Absence in Long-Term Care Using Operational Workforce Data

This repository contains the code developed for the Master's thesis submitted in partial fulfillment of the requirements for the degree of Master of Science in Data Science & Society at Tilburg University (2026).

## Author
Cas Hogenboom

## Supervisor
Dr. Lisanne Huis in 't Veld

## Project Context
This study was conducted in collaboration with Hibis, a data and business intelligence consultancy supporting Dutch long-term care organizations. The data was provided by one of their client organizations and contains operational workforce data spanning 52 months across 39 teams, resulting in 1,541 team-month observations.

## Research Goal
To investigate whether monthly team absence rates in long-term care can be forecast using only operational workforce data, and to compare the performance of a Random Forest and Artificial Neural Network against a naïve lag-1 baseline. 

## Repository Contents
- `team_month_aggregation.sql` — SQL preprocessing script that aggregates individual-level HR, shift, and absence data to team-month level
- `random_forest.py` — Random Forest model training, hyperparameter tuning, feature importance, and evaluation
- `ann_model.py` — ANN (MLP) model architecture, training, and evaluation
- `requirements.txt` — Python dependencies

## Requirements
See `requirements.txt`. Install with:

pip install -r requirements.txt


## Note on Data
The original data is confidential and not included in this repository. Confidential team identifiers and organizational schema names have been removed from the SQL script. The code cannot be run independently without access to the organization's internal database.