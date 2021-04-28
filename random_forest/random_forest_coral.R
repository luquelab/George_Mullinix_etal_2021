#!/usr/bin/env Rscript
library(randomForest)
library(cluster)
library(purrr)
library(ggplot2)
library(stringr)
library(rpart)
library(rpart.plot)

## Run RF on full variable set
# maybe we don't want to run the full setup; in this case we'll load the results in from file
RUN_FULL_RF = TRUE
minits = 1024 # number of times run RFs -- at the start, anyhow!
nsamples = 5 # number of RF-averages to calculate; we use this to determine if the importance order is stable
# load data
data = read.csv('../coral_geometry_measurements.csv')
# select response and observation vars by filtering out unwanted vars
response_vars = c("W","L")
unused_vars = c("Filename", "ID", "Species_Name", "Type", "Area", "N")
not_observation = c(response_vars, unused_vars)
observation_vars = c()
for(col in colnames(data)){
  if(!(col %in% not_observation)){
    observation_vars = c(observation_vars, col)
  }
}
# run the RF

resampledRF = function(data=data.frame(),
                     nrf=10000,
                     observation_vars=c("."),
                     response_vars=c("Y")){
  # preallocate memory for speed
  results = list()
  for(res in response_vars){
    results[[res]]=list(
      importance=as.data.frame(matrix(rep(0,nrf*length(observation_vars)), 
                                      nrow=nrf, 
                                      ncol=length(observation_vars), 
                                      byrow=TRUE, 
                                      dimnames=list(c(1:nrf),c(observation_vars)))
      ),
      rank=as.data.frame(matrix(rep(0,nrf*length(observation_vars)), 
                                      nrow=nrf, 
                                      ncol=length(observation_vars), 
                                      byrow=TRUE, 
                                      dimnames=list(c(1:nrf),c(observation_vars)))
      ),
      Rsq=matrix(rep(0,nrf))
    )
  }
  # run RF nrf times for each response variable we wish to test
  for(res in response_vars){
    str_formula = paste(res,'~',paste(observation_vars, collapse=" + "), sep=" ")
    for(i in c(1:nrf)){
      rf = randomForest(as.formula(str_formula), data=data, na.action=na.exclude, importance=TRUE)
      rf$residuals = rf$y-rf$predicted
      rf$yres = rf$y-mean(rf$y)
      rf$RSS = sum(rf$residuals^2)
      rf$TSS = sum(rf$yres^2)
      rf$Rsq = 1.0-rf$RSS/rf$TSS
      imp = importance(rf, type=1)
      Rsq = rf$Rsq
      results[[res]]$importance[i,] = imp
      results[[res]]$rank[i,] = order(imp, decreasing=TRUE)
      results[[res]]$Rsq[i] = Rsq
    }
    
  }
  return(results)
}

calculate_ranks = function(results){
  for(res in names(results)){
    results[[res]][["rank"]] = results[[res]][["importance"]]
    results[[res]][["rank"]][,] = -1
    iters = length(results[[res]][["rank"]][,1])
    for(iter in c(1:maxits)){
      results[[res]][["rank"]][iter,] = order(results[[res]][["importance"]][iter,], decreasing=TRUE)
    }
  }
}

if(RUN_FULL_RF){
  nrf = minits
  results = resampledRF(data=data, nrf=nrf, observation_vars=observation_vars, response_vars=response_vars)
  mean_ranks = list()
  for(res in response_vars){
    m = colMeans(results[[res]][["importance"]])
    mean_ranks[[res]] = order(m, decreasing=TRUE)
  }
  different = TRUE
  while(different){
    new_results = resampledRF(data=data, nrf=nrf, observation_vars=observation_vars, response_vars=response_vars)
    for(res in response_vars){
      results[[res]][["importance"]] = rbind(results[[res]][["importance"]], new_results[[res]][["importance"]])
      results[[res]][["rank"]] = rbind(results[[res]][["rank"]], new_results[[res]][["rank"]])
      results[[res]][["Rsq"]] = c(results[[res]][["Rsq"]], new_results[[res]][["Rsq"]])
    }
    new_ranks = list()
    for(res in response_vars){
      m = colMeans(results[[res]][["importance"]])
      new_ranks[[res]] = order(m, decreasing=TRUE)
    }
    different = !identical(new_ranks, mean_ranks)
    if(different){
      mean_ranks = new_ranks
    }
    nrf = nrf*2
    print(nrf)
  }
  
  save(results,file='rf_allvars.RData')
}
