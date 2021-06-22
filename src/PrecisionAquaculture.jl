module PrecisionAquaculture

using DataFrames
using CSV
using Dates

include("utils.jl")
using .Utils
export readdata,groupedmean,extractgrmean,hourly,extractsensor
export FishDType, FVal

include("workflow.jl")
using .Workflow

end # module
