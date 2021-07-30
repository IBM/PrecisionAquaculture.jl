# precision-aquaculture
This repository contains code related:
1. an online course for Precision Aquaculture that posits the value of [Julia](https://julialang.org/) as a programming language for applied data science such as is demanded in aquaculture. It provides
 - an introduction to Julia programming langugage
 - an overview of data wrangling in Julia and
 - data science applications in Juliana
 2. Code for data driven interrogation of aquaculture dataset. It details the interrogation of environmental and hydroacoustic datasets from an actual salmon farm. Details are provide in our paper [`Data Driven Insight into Fish Behaviour and their use for Precision Aquaculture`](https://www.frontiersin.org/articles/10.3389/fanim.2021.695054/abstract).

 The Julia Workshop is composed of three sections:
 1. [Part 1 - Introductory Julia Live Tutorials](https://mybinder.org/v2/gh/IBM/PrecisionAquaculture.jl/main?filepath=JuliaWorkshop%2FPart1-BasicJulia)
 2. [Part 2 - Introduction to DataFrames in Julia Live Tutorials](https://mybinder.org/v2/gh/IBM/PrecisionAquaculture.jl/main?filepath=JuliaWorkshop%2FPart2-DataFrames)
 3. [Part 3 - Julia with Python/R for Data Science Live Tutorials](https://mybinder.org/v2/gh/IBM/PrecisionAquaculture.jl/main?filepath=JuliaWorkshop%2FPart3-DataScience)

 Finally, we illustrate an application to data from aquaculture farms. In particular, it describes the loading, processing, and curating of data from environmental and hydroacoustic sensors from an aquaculture farm in Norway. environmental data considered include water and air temperature, dissolved oxygen (DO), sea surface height (SSH), salinity, current speed, wind speed, and temporal features. Further we describe the generation of autoregressive features for time series analysis.

 Hydroacoustic methods provide a proxy measure for density and distribution of marine animals in form of acoustic backscattering. The fundamental principle is based on emitting a signal of known type and power level from a transducer. As it encounters regions of the medium with differing properties, also called heterogeneities, the sound is generally redistributed, or scattered, in all directions. This makes possible detection of the scattered sound with transducer and suitable receiver electronics. Advantages linked to hydroacoustic sampling techniques include, high spatial and temporal resolution, autonomous long-term sampling duration, range (especially during poor visibility when visual-based methods tend to fail), and a non-invasive surveying approach. Given these advantages, hydroacoustics is increasingly used to characterise animal behaviour in the marine environment, and considered a promising system to improve management of aquaculture farms.
