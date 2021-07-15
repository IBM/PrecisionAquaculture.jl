module Utils

using DataFrames
using CSV
using Dates
using TSML
import AutoMLPipeline 
AMLP = AutoMLPipeline

export readdata,groupedmean,extractgrmean,hourly,extractsensor,FishDType,FVal

# create dynamic dispatch based on data type: abm, cad2, cad4
abstract type FishDType end

struct FVal{x} <: FishDType
end

FVal(x) = FVal{x}()

function groupedmean(tpe::FishDType,dv::Union{DataFrameRow,Vector}) end
function extractgrmean(tpe::FishDType,data::DataFrame)  end
# end of dynamic dispatch

# extract temp/salinity/oxygen
function extractsensor(fname,sy::Symbol)
  tempdata=readdata(fname,"y-m-d H:M:S+S:S",:observed_timestamp)
  if :label in names(tempdata)
	 select!(tempdata,Not(:label)) # remove redundant column
  end
  if ncol(tempdata) == 3
     hourlytemp=hourly(tempdata[:,2:3])
  else
     hourlytemp=hourly(tempdata)
  end
  rename!(hourlytemp,Dict(:Value => sy))
  return hourlytemp
end


function readdata(file::String,datefmt::String="y-m-d H:M:S",datefield::Symbol=:Timestamp)
	dataloc = joinpath(@__DIR__,"../data/"*file)
	data = CSV.File(dataloc) |> DataFrame
	data[!,datefield] = DateTime.(data[!,datefield],datefmt)
	return data
end

function groupedmean(::FVal{:abm},dv::Vector)
	#row-wise impute
	v = interp(dv) |> locf() |> nocb()
	len = length(v)
	wndx = collect(0:0.5:len)[2:2:2len] # depths midpoints
	@assert length(v) == length(wndx)
	return sum(wndx .* v)/sum(v)
end


function groupedmean(::FVal{:cad2},dv::Vector)
	#row-wise impute
	v = interp(dv) |> locf() |> nocb()
	wndx = collect(0.1:0.2:10.5) # depths midpoints
	@assert length(v) == length(wndx)
	return sum(wndx .* v)/sum(v)
end


function groupedmean(::FVal{:cad4},dv::Vector)
	#row-wise impute
	v = interp(dv) |> locf() |> nocb()
	wndx = collect(0.1:0.2:8.7) # depths midpoints
	@assert length(v) == length(wndx)
	return sum(wndx .* v)/sum(v)
end

function groupedmean(::FVal{:scot},dv::Vector)
	#row-wise impute
	v = interp(dv) |> locf() |> nocb()
	wndx = collect(0.1:0.2:2.7) # depths midpoints
	@assert length(v) == length(wndx)
	return sum(wndx .* v)/sum(v)
end

function groupedmean(tpe::FishDType,dv::DataFrameRow)
	groupedmean(tpe,Vector(dv))
end
	
function groupedmean(tpe::FishDType,data::DataFrame)
	[groupedmean(tpe,x) for x in eachrow(data)]
end

function extractgrmean(tpe::FVal{:abm},data::DataFrame)
	# check specific data
	@assert eltype(data[:,1]) <: DateTime
	@assert ncol(data) == 23
	# global impute
	vals = float.(data[:,2:(end-2)]) # extract depths
	# columnwise impute
	vals = interp(vals) |> locf() |> nocb()
	fvals = groupedmean(tpe,vals)
	cdata = DataFrame(time=data.Timestamp,mean=fvals)
end

function extractgrmean(tpe::Union{FVal{:cad2},FVal{:cad4},FVal{:scot}},data::DataFrame)
	# check specific data
	@assert eltype(data[:,1]) <: DateTime
	#@assert ncol(data) == 54
	# global impute
	vals = float.(data[:,2:end]) # extract depths
	# columnwise impute
	vals = interp(vals) |> locf() |> nocb()
	fvals = groupedmean(tpe,vals)
	cdata = DataFrame(time=data.Timestamp,mean=fvals)
end

function hourly(df::DataFrame,plot::Bool=false)
	valnner = DateValNNer(Dict(:strict=>false,:nnsize=>2))
	valgator = DateValgator()
	valizer = DateValizer()
	outliernicer = Outliernicer()
	pltr = Plotter()
	if plot == true
		pipeline = @pipeline valgator |> valnner |> pltr
	else
		pipeline = @pipeline valgator |> valnner
	end
	fit!(pipeline,df)
	ct=TSML.transform!(pipeline,df)
	ct
end

end
