function [] = runAll(rawData, modelName, dateMethod, percentiles)
%% Where is the raw data and what is the site specific threshold
rawData.maskName = 'canopy';    %ROI type
rawData.dir = '../';    %directory containing raw data site directories
rawData.sites = {'harvard'};  %site name
rawData.years = {2008:2011};    %years
threshold = 0.15;           % fractional DN threshold for dark conditions

%% what model to fit
modelName = 'greenDownSigmoid';
% modelName = 'piecewise';
% modelName = 'greenDownRichards';
% modelName = 'smoothInterp';
% modelName = 'separateSigmoids';

%% what method to extract phenological dates
% dateMethod = 'secondDeriv';   %use with separateSigmoids or
%greenDownSigmoid

dateMethod = 'CCR'; %use with separateSigmoids, greenDownSigmoid, or
%greenDownRichards

% dateMethod = 'percentiles'; %use with greenDownRichards

% dateMethod = 'dataPercentiles'; %use with smoothInterp and GCC data.
% Gets spring dates only.

% dateMethod = 'fallRedMax'; %use with smoothInterp and RCC data.  Gets one
% fall date at RCC peak.

%% Specify percentiles
% percentiles are used by the 'percentiles' and 'dataPercentiles'
% dateMethods.  If using other methods, this variable must be assigned a
% value but it will be ignored.

%if using 'percentiles' dateMethod, specify 4 percentiles for beginning of
%spring, middle of spring, middle of fall, and end of fall.  CCR is used
%for end of spring and beginning of fall.  Dates are calculated as the date
%of crossing the value at this percentile between baseline and CCR value.
percentiles = [0.10 0.50 0.50 0.10];
% percentiles = [0.04 0.30 0.50 0.12];

%if using 'dataPercentiles' dateMethod, specify 3 percentiles for
%beginning, middle, and end of spring
% percentiles = [0.10 0.50 0.90];   %for dataPercentiles

%% How to filter and threshold data, where to save results
% filter can be 'none', 'quantile', 'mean', or 'median'
filter.type = 'quantile';
% length of moving window in days
filter.window = 3;
% quantile if using this filter
filter.quantile = 0.9;
% start and end year on these days
temporal.beginYear = 0;
temporal.endYear = 365;
% start and end each day
temporal.beginDay = 0;
temporal.endDay = 24;
% choose index to calculate and filter:  'GCC', 'RCC', 'BCC', or 'ExG'
index = 'GCC';
% output file naming
saveDir = '../results/';
outName = [saveDir rawData.sites{1} '-' index '-siteInfo'];


%% What to plot
plotWhat.rawData = 0;
plotWhat.processedData = 1;
plotWhat.weighting = 0;
plotWhat.model = 1;
plotWhat.phenoDates = 1;
plotWhat.legendSwitch = 1;

%% Run analyses
% load and filter GCC data
% GCC_load(saveDir, outName, rawData, threshold, filter, temporal, index);

% fit model
% VI_curve(outName, modelName);

% estimate phenological dates
% getPhenoDates(outName, modelName, dateMethod, percentiles);

% plot results for all years
% phenoPlot(outName, modelName, dateMethod, plotWhat);

% plot results for one year
% phenoPlotOneYear(saveDir, outName, modelName, dateMethod, plotWhat);

%% for Monte Carlo samples of parameters and associated phenological dates
% so far this is only implemented for separateSigmoids and greenDownSigmoid
% with the CCR method

%n is the number of samples to generate.  1000 is standard, 100 is faster.
% n = 100;

% run analysis
% getPhenoDatesMC(saveDir, outName, modelName, dateMethod, n);

%set of all parameter samples and associated dates will be saved in a file
%with 'MC' in the file name.  The variable 'sixDatesMC' contains the set of
%n phenological dates for each year.  Take the inner 95% of these dates to
%generate 95% confidence intervals on the dates.

% plot all model fits used to calculate dates for a given year
% only works for greenDownSigmoid right now.

% choose which year
% yearIndex = 4;
% 
% phenoPlotMC(outName, modelName, dateMethod, plotWhat, yearIndex);