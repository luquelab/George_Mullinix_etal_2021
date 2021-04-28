library(lattice)
library(ggplot2)
library(ggrepel)
library(partykit)

source("build_custom_trees.R")

## install reprtree + dependencies ##
options(repos='http://cran.rstudio.org')
have.packages <- installed.packages()
cran.packages <- c('devtools','plotrix','randomForest','tree')
to.install <- setdiff(cran.packages, have.packages[,1])
if(length(to.install)>0) install.packages(to.install)

library(devtools)
if(!('reprtree' %in% installed.packages())){
  install_github('araastat/reprtree')
}
for(p in c(cran.packages, 'reprtree')) eval(substitute(library(pkg), list(pkg=p)))

## load RF code, if needed ##
if(!exists("resampledRF", mode="function")) source("random_forest_coral.R")

# (Re)-load the data
if(!exists("results")){
  load('rf_allvars.RData')
}

NRF = 10000 # number of random forest resamplings
BOTTOMS_UP = TRUE # set to FALSE to not rebuild RF, loading in previous data

## UNIVARIATE CORRELATION ##
univariate_analysis = function(data, response_vars){
  # read in bootstrapped correlations
  coors = read.csv('../correlation_bootstrap/bs-correlations.csv', row.names=1)
  names = row.names(coors)
  
  # grep out only the results that end with L,W
  pattern = "^(.{2,})-([LW]{1})$"
  matches = str_match(names, pattern)
  match_ix = grep(pattern, names)
  
  # find maximum correlations
  best_coors = list()
  for(response in response_vars){
    # downselect for correlation values
    pattern = sprintf("^(.{2,})-([%s]{1})$", response)
    matches = str_match(names, pattern)
    response_ix = grep(pattern, names)
    best_ix = which.max(abs(coors[response_ix,]$median))
    best_coors[[response]] = row.names(coors[response_ix,])[best_ix]
  }
  correlation_data = list(correlations=coors,
                          best_correlations=best_coors)
  return(correlation_data)
}

standard_error <- function(x) sd(x) / sqrt(length(x))

if(BOTTOMS_UP){

  corr_data = univariate_analysis(data, response_vars)
  
  coors = corr_data[["correlations"]]
  best_coors = corr_data[["best_correlations"]]
  names = row.names(coors)
  
  ## BOTTOM-UP ASSEMBLY ##
  # construct models in bottom-up fashion starting from best univariate correlation
  bottom_up = list()
  for(response in response_vars){
    obs_ix = 1
  
    pick = best_coors[[response]]
    pattern = sprintf("^(.{2,})-([%s]{1})$", response)
    matches = str_match(names, pattern)
    response_ix = grep(pattern, names)
    best_ix = row.names(coors[response_ix,])==best_coors[[response]]
    ix = unique(which(!is.na(matches), arr.ind=TRUE)[,1])[best_ix]
    obs_vars = matches[ix,2]
    
    model_probs = matrix(rep(0,length(observation_vars)*length(observation_vars)),
                         nrow = length(observation_vars),
                         ncol = length(observation_vars))
    model_probs = data.frame(model_probs)
    colnames(model_probs) = observation_vars
    model_probs[obs_ix, pick] = 1
    bottom_up[[response]] = list(Rsq = rep(0,length(observation_vars)),
                                 RsqSE = rep(0,length(observation_vars)),
                                 obs_vars = list(),
                                 model_probs = model_probs)
    bottom_up[[response]]$Rsq[obs_ix] = t(coors[response_ix,]$median)[best_ix]^2
    bottom_up[[response]]$obs_vars[[obs_ix]] = obs_vars
    while(obs_ix < length(observation_vars)){
      obs_ix = obs_ix + 1
      pick_from = observation_vars[!(observation_vars %in% obs_vars)]
      rsq = matrix(rep(0,length(pick_from)*NRF),
                   nrow = NRF,
                   ncol = length(pick_from))
      rsq = data.frame(rsq)
      colnames(rsq) = pick_from
      probs = matrix(rep(0,length(pick_from)),
                     nrow = 1,
                     ncol = length(pick_from))
      probs = data.frame(probs)
      colnames(probs) = pick_from
      for(obs in pick_from){
        new_obs = c(obs_vars, obs)
        new_results = resampledRF(data=data,
                                  nrf=NRF,
                                  observation_vars=new_obs,
                                  response_vars=response)
        rsq[obs] = new_results[[response]]$Rsq
      }
      winners = max.col(rsq)
      for(i in c(1:length(pick_from))){
        obs = pick_from[i]
        probs[obs] = mean(winners==i)
      }
      model_probs[obs_ix, pick_from] = probs
      bottom_up[[response]]$model_probs = model_probs
      pick = pick_from[max.col(probs)]
      obs_vars = c(obs_vars, pick)
      bottom_up[[response]]$obs_vars[[obs_ix]] = obs_vars
      bottom_up[[response]]$Rsq[obs_ix] = mean(t(rsq[pick]))
      bottom_up[[response]]$RsqSE[obs_ix] = standard_error(t(rsq[pick]))
    }
    best_ix = which.max(bottom_up[[response]]$Rsq)
    print(sprintf("%s max expl var: %f",response,bottom_up[[response]]$Rsq[best_ix]))
    print("vars:")
    print(bottom_up[[response]]$obs_vars[[best_ix]])
  }
  save(bottom_up, file='rf_bottoms_up.RData')
}

if(!exists("bottom_up")){
  load('rf_bottoms_up.RData')
}

### PLOTTING ###
keys = c(
  "Depth",
  "P_polyp_3D",
  "P_SA_3D",
  "Perimeter_D",
  "perimeter_length_3D",
  "Polyp_diameter",
  "RP_length",
  "RP_SA",
  "SA_polyp2",
  "Species",
  "Surface_Area",
  "Surface_D",
  "Volume",
  "Volume_SA"
)

values = c(
  "d",
  "Ppolyp",
  "P3D/SA",
  "DP",
  "P3D",
  "Pd",
  "PR",
  "PR/SA",
  "SApolyp",
  "S",
  "SA",
  "DS",
  "V",
  "V/SA"
)


var_names = list()
for(i in c(1:length(values))){
  var_names[[keys[i]]] = values[i]
}

## HEATMAP/LEVELPLOT ##
for(response in response_vars){
  output_filename=sprintf("selection_likelihood_%s.pdf",response)
  data_fname=sprintf("selection_likelihood_%s.csv",response)
  WidthInInches=8.75/2.54;
  pdf(output_filename,width=WidthInInches,height=WidthInInches);
  par(family="Helvetica",ps=9,cex=1,pch=20,mai=c(rep(0.5,3),0.3));
  ordered = tail(bottom_up[[response]]$obs_vars, 1)[[1]]
  mx = bottom_up[[response]]$model_probs[ordered]
  mx = t(as.matrix(mx))
  colnames(mx) = c(1:length(ordered))
  rnames = c()
  for(name in rownames(mx)){
    rnames = append(rnames,var_names[name])
  }
  rownames(mx) = rnames
  write.csv(mx, data_fname)
  lattice.options(
    layout.heights=list(bottom.padding=list(x=0), top.padding=list(x=0)),
    layout.widths=list(left.padding=list(x=0), right.padding=list(x=0))
  )
  plt = levelplot(mx,
                  xlab="Selected Variables",
                  ylab="# Variables",
                  col.regions = grey.colors(100, start=0, end=1, rev=TRUE),
                  colorkey = FALSE,
                  scales=list(y=list(rot=0), x=list(rot=90)))#,
  print(plt)
  dev.off()
}

### BAR CHARTS ###
for(response in response_vars){
  output_filename=sprintf("selection_likelihood_barcharts_%s.pdf",response)
  data_fname=sprintf("selection_likelihood_bars_%s.csv",response)
  WidthInInches=8.75/2.54;
  pdf(output_filename)
  ordered = tail(bottom_up[[response]]$obs_vars, 1)[[1]]
  df_2d = bottom_up[[response]]$model_probs[ordered]
  cnames = c()
  for(name in colnames(df_2d)){
    cnames = append(cnames,var_names[name])
  }
  colnames(df_2d) = cnames
  df_long = reshape(data=df_2d, idvar="model_size",
                    varying=colnames(df_2d),
                    v.name="likelihood",
                    times=colnames(df_2d),
                    new.row.names = 1:1000,
                    direction="long")
  colnames(df_long) = c("variable_name", "likelihood", "variable")
  df_long$variable_name = factor(df_long$variable_name, levels=colnames(df_2d))
  write.csv(df_long, data_fname)
  plt = ggplot(df_long,
               aes(x=variable, y=likelihood, fill=variable))+
               geom_bar(position="dodge", stat="identity")+
               facet_wrap(~variable_name)+
               theme(legend.position="none")
  print(plt)
  dev.off()
}

## EXPL VARIANCE ##
for(response in response_vars){
  output_filename=sprintf("expl_var_%s.pdf",response)
  data_fname=sprintf("expl_var_%s.csv",response)
  WidthInInches=8.75/2.54;
  pdf(output_filename,width=WidthInInches,height=WidthInInches);
  par(family="Helvetica",ps=9,cex=1,pch=20,mai=c(rep(0.5,3),0.3));
  ydata = bottom_up[[response]]$Rsq*100
  y_up = ydata+2*bottom_up[[response]]$RsqSE*sqrt(NRF)*100
  y_down = ydata-2*bottom_up[[response]]$RsqSE*sqrt(NRF)*100
  vars = tail(bottom_up[[response]]$obs_vars, n=1)[[1]]
  single_var_Rsq = ydata[1]
  single_var_name = var_names[vars[1]]
  ydata = ydata[2:length(ydata)]
  y_up = y_up[2:length(y_up)]
  y_down = y_down[2:length(y_down)]
  xlabels = ydata
  for(i in c(1:length(xlabels))){
    key = vars[i+1]
    xlabels[i] = sprintf("+ %s", var_names[[key]])
  }
  xplot=seq(from=2, to=length(ydata)+1, by=1)
  df = data.frame(xplot,ydata,y_up,y_down)
  colnames(df) = c("variables","explained_variance","y_up","y_down")
  write.csv(df, data_fname)
  plt = ggplot(df, aes(x=variables, y=explained_variance))+
        geom_ribbon(aes(ymin=y_down, ymax=y_up), fill="grey", alpha=0.5)+
        geom_point()+
        geom_line(aes(x=variables,y=explained_variance))+
        annotate(geom = "text", 
                 x = xplot, 
                 y = ydata, 
                 label = xlabels, 
                 angle = 90)+
        scale_x_continuous(name="# Variables",
                         breaks=xplot,
                         labels=xplot)+
        scale_y_continuous(name="% Explained Variance",
                         breaks=seq(10,35,5),
                         labels=seq(10,35,5))+
        theme_classic()
  print(plt)
  dev.off()
}


## CUSTOM TREE ##
trees = list()
cleaned = data[complete.cases(data),]
for(response in c("L","W")){
  vars = c("Surface_D", "perimeter_length_3D", "P_SA_3D")
  trees[[response]] = custom_tree(cleaned, response, vars, 1, c(1:nrow(cleaned)))
  strout = print_tree(trees[[response]],
                      0,
                      sprintf("%%%s",response),
                      sprintf("<%%%s>",response))
  cat(strout)
}
