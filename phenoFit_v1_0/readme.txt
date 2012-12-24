phenoFit v1_0.  Please email steve.klosterman@gmail.com with any bug fixes or suggestions.  Coauthorship is requested if you use this code to for published work.  Thanks!

The file runAll.m contains example arguments and will step you through the process.  Important functions are:

GCC_load.m, which processes VI time series (e.g. GCC or RCC)

VI_curve.m, fits models to data

phenoDates.m, extracts phenological dates

phenoPlot.m, plots all years for a site

phenoDatesMC.m, generates Monte Carlo samples of parameters and calculates associated phenological dates

phenoPlotMC.m, plots models to see where the Monte Carlo dates are from.  This can be helpful in interpreting the results of phenoDates.m