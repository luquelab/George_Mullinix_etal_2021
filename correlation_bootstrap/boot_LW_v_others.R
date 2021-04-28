#!/usr/bin/env Rscript
mydata=read.csv('../coral_geometry_measurements.csv',header=TRUE)
indices=c(match("L",names(mydata)),
          match("W",names(mydata)))
names(indices)=c("L","W")
mydata$Surface_Area=log10(mydata$Surface_Area)
mydata$Volume=log10(mydata$Volume)

skip=c(match("Filename",names(mydata)),
       match("ID",names(mydata)),
       match("Species_Name",names(mydata)),
       match("Type",names(mydata)),
       match("N",names(mydata)),
       match("Area",names(mydata)))

fit_ix=c(1:length(names(mydata)));
fit_ix=fit_ix[-skip]
num_entries=(length(fit_ix)-1)*2;
bootstrap_names=c("statistic",
                  "lower_percentile",
                  "upper_percentile",
                  "lower_BCa",
                  "upper_BCa",
                  "lower_SE_Median",
                  "upper_SE_Median",
                  "median",
                  "mean",
                  "npts",
                  "nBS");
results=data.frame(matrix(rep(0,num_entries*length(bootstrap_names)),ncol=length(bootstrap_names)));
colnames(results)=bootstrap_names;
corr_names=rep(0,length(num_entries));
k=1;
for(i in c(1:length(indices))){
  for(j in fit_ix){
    if(j!=indices[i]){
      tmpdata=data.frame(mydata[,j],mydata[,indices[i]]);
      colnames(tmpdata)=c(names(mydata)[j],names(indices)[i]);
      str(names(tmpdata))
      corr_names[k]=sprintf("%s-%s",names(tmpdata)[1],names(tmpdata)[2])
      filename=sprintf("%s_correlation.txt",corr_names[k])
      write.table(tmpdata,file=filename,row.names=FALSE,col.names = FALSE,sep=",")
      system(sprintf("linboot %s 0.05",filename));
      results_in=read.csv(sprintf("%s-CI.dat",filename),header=TRUE);
      correlation = results_in[results_in$statistic == "pearson_rho",]
      results[k,]=correlation
      k=k+1;
    }
  }
}
rownames(results)=corr_names
insignificant=which( (results$lower_BCa<0 & results$upper_BCa>0) |
                     (results$lower_BCa>0 & results$upper_BCa<0))
print("The following are significantly correlated:")
str(row.names(results[-insignificant,]))
write.csv(results,"bs-correlations.csv")
significant=results[-insignificant,];
skip=-c(1:length(significant[,1]))
ylims=c(min(significant$lower_BCa[-skip]),max(significant$upper_BCa[-skip]))
plot(significant$lower_BCa[-skip],ylim=ylims,pch="-",xlab=NA,xaxt="n",ylab="Correlation (rho)")
axis(1,at=c(1:length(significant[-skip,1])),labels=rownames(significant[-skip,]),las=2)
points(c(1:length(significant[-skip,1])),significant$upper_BCa[-skip],pch="-")
points(c(1:length(significant[-skip,1])),significant$median[-skip],pch=20);
abline(h=0, lty=3);

move_files = Sys.glob(file.path(".", c("*.txt", "*.txt*.dat")))
for(f in move_files) {
  file.copy(f, "results_data")
  file.remove(f)
}


