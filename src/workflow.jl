module Workflow 

using AutoMLPipeline
using TSML
using RCall
using Plots
using DataFrames
using DataFramesMeta
AMLP = AutoMLPipeline
pl=Plots
sy=Symbol

src = dirname(pathof(PrecisionAquaculture))


fname="abm/all-abmdata.csv"
mdata=readdata(fname,"y-m-d H:M:S",:Timestamp) # field with date format

#extract hourly mean height of fish locations
rowmean = extractgrmean(FVal(:abm),mdata)
hourlyheight=hourly(rowmean) .|> identity  # remove union types
rename!(hourlyheight,Dict(:Value => :Height))
CSV.write(joinpath(src,"../data/abm/rowmean-abm.csv"),rowmean)
R"library(ggplot2)"
R"ggplot(data=$rowmean,aes(time,mean))+geom_line()"


# extract hourly temp
temp12m = "abm/Temperature_12m.csv" 
htemp12m=extractsensor(temp12m,:Temp12m)
temp3m = "abm/Temperature_3m.csv" 
htemp3m=extractsensor(temp3m,:Temp3m)
temp6m = "abm/Temperature_6m.csv" 
htemp6m=extractsensor(temp6m,:Temp6m)

# extract oxygen
oxyfname = "abm/Oxygen_12m.csv" 
hoxy12m = extractsensor(oxyfname,:Oxy12m)

# extract salinity
salinityfname = "abm/Salinity_6m.csv" 
hsalinity6m = extractsensor(salinityfname,:Salin6m)

# extract speed
speedfname = "abm/Speed_5m.csv"
hspeed5m = extractsensor(speedfname,:Speed5m)

# speed direction
spdirfname = "abm/SpeedDirection_5m.csv"
hspeed5m_dir = extractsensor(spdirfname,:SpeedDir5m);

# merge date,height,temp,oxygen
df = innerjoin(innerjoin(innerjoin(hourlyheight,htemp3m,on=:Date),htemp6m,on=:Date),htemp12m,on=:Date)
df = innerjoin(innerjoin(innerjoin(df,hoxy12m,on=:Date),hsalinity6m,on=:Date),hspeed5m,on=:Date)
df = innerjoin(df,hspeed5m_dir,on=:Date)
df = identity.(df)

# skip missings
df = df[600:end,:] .|> identity
R"library(ggplot2)"
R"ggplot(data=$df,aes(Date,Height))+geom_line()"
R"ggplot(data=$df,aes(Date,Speed5m))+geom_line()"
R"ggplot(data=$df,aes(Date,Oxy12m))+geom_line()"
R"ggplot(data=$df,aes(Date,Salin6m))+geom_line()"

# extract features for ML
dfs = df[:,1:2]
rename!(dfs,Dict(:Height => :Value))
cargs = Dict(:ahead=>1,:size=>3,:stride=>1)
dateifier=Dateifier(cargs)
matrifier=Matrifier(cargs)
datemx=fit_transform!(dateifier,dfs) .|> identity
valmx=fit_transform!(matrifier,dfs) .|> identity
datemx.Date = [DateTime(x.year,x.month,x.day,x.hour) for x in eachrow(datemx)]
datevalmx = hcat(datemx,valmx)
fdf=innerjoin(datevalmx,df,on=:Date)
R"ggplot(data=$fdf)+geom_line(aes(Date,output))"

#filter: data > June 15 to avoid noise/missing/interpolated data based on plot
#rfdf=@linq fdf |> where(:Date .> DateTime(2019,06,13,00,00)) |> where((:week .>= 24) .& (:week .<= 26))
rfdf=@linq fdf |> where(:Date .> DateTime(2019,06,13,00,00)) 
R"ggplot(data=$rfdf)+geom_line(aes(Date,output))"

# save df
CSV.write(joinpath(src,"../data/abm/abm_processed.csv"),rfdf)

@rput rfdf
R"library(randomForest)"
R"library(caret)"
R"library(e1071)"
R"colnames=c('year','month','hour','week','dow','day','qoy','doq')"
R"rfdf[colnames] <- lapply(rfdf[colnames] , factor)"

R"fm1 = as.formula('output ~ month+hour+week+dow+qoy+Temp3m+Temp6m+Temp12m+Oxy12m+Salin6m+Speed5m+SpeedDir5m+x1+x2+x3')"
R"rfmodel=randomForest(fm1,data = rfdf)"
R"varImpPlot(rfmodel)"

R"fm2 = as.formula('output ~ hour+week+dow+Temp3m+Temp6m+Temp12m+Oxy12m+x1+x2+x3')"
R"rfmodel=randomForest(fm2,data = rfdf)"
R"varImpPlot(rfmodel)"

R"fmo = as.formula('output ~ Temp3m+Temp12m+Oxy12m+Salin6m+Speed5m+x2+x3')"
R"rfmodel=randomForest(fmo,data = rfdf)"
R"varImpPlot(rfmodel)"

R"fmh = as.formula('Height ~ Temp3m+Temp12m+Oxy12m+Salin6m+Speed5m')"
R"rfmodel=randomForest(fmh,data = rfdf)"
R"varImpPlot(rfmodel)"

R"fms = as.formula('Speed5m ~ Temp3m+Temp12m+Oxy12m+Salin6m+x1+x2+x3')"
R"rfmodel=randomForest(fms,data = rfdf)"
R"varImpPlot(rfmodel)"

#R"lmmodel=lm(fms,data = rfdf)"
#R"lmpred = predict(lmmodel)"
#R"svmmodel=svm(fm,data = rfdf)"
#R"svmpred = predict(svmmodel)"
#R"rfpred = predict(rfmodel)"
#R"clmmodel=train(fm,data = rfdf,method='lm')"
#R"svmmodel=train(fm,data = rfdf,method='svmRadial')"
#R"plot(lmmodel)"

R"ggplot(data=rfdf)+geom_line(aes(Date,output))"

end
