function [] = runAllMODIS_NBAR(site, modelName, dateMethod, percentiles)

modelName = 'separateSigmoids';
% modelName = 'greenDownSigmoid';
% modelName = 'greenDownRichards';
dateMethod = 'CCR';
% dateMethod = 'dataPercentiles';
% dateMethod = 'percentiles';
percentiles = [0.10 0.50 0.50 0.10];
% percentiles = [0.10 0.50 0.90];
loadDir = '../../modisClient/modisPhenocamCompareNBAR/';
saveDir = ['./MODIS_NBAR' filesep];  %for temporal median filter
% saveDir = ['./MODIS_NBAR' filesep]; %for SV filter

% filter.type = 'none';
filter.type = 'median';
% filter.type = 'SV';
filter.window = 3;  %number of data points in moving window filter
% filter.SVdeg = 2;   %degree of polynomial for SV filter

% site = 'acadia';  %no 2010
% site = 'arbutuslake';   %good
% site = 'bartlett';  %no 2010
% site = 'boundarywaters';    %no 2011 fall
% site = 'dollysods'; %no 2004, 10, 11 (disregard 11 for median)
% site = 'groundhog'; %good
% site = 'harvard';   %good
% site = 'mammothcave';   %good
% site = 'monture';   %not much useful info
% site = 'mountzirkel';   %most autumns missing here
% site = 'nationalcapitol'; %fall 2003, 2004, fall 2010, spring 2011
% site = 'queens';  %no 2009, 2010 (need to disregard 2010 fall for SV)
% site = 'smokylook';   %good
% site = 'umichbiological';   % need to disregard 2011 for SV
site = 'upperbuffalo';  %good

%3 day median window seems to remove most dubious data points

fname = [site 'MODIS_NBAR_data.mat'];
savename = site;

% fname = [site '_reshaped_km_MODIS_data.mat'];
% savename = [site '_km'];

%choose EVI or NDVI to use these results
% outName = [savename '-EVI-NBAR' '-siteInfo'];
outName = [savename '-EVI-NBAR' '-siteInfo'];

plotWhat.rawData = 0;
plotWhat.processedData = 1;
plotWhat.weighting = 0;
plotWhat.model = 1;
plotWhat.phenoDates = 1;
plotWhat.legendSwitch = 1;
% 
MODIS_load_NBAR(fname, loadDir, savename, saveDir, filter);
VI_curve(outName, modelName);
getPhenoDates(outName, modelName, dateMethod, percentiles);
phenoPlot(outName, modelName, dateMethod, plotWhat);

% getPhenoDatesMC(outName, modelName, dateMethod);
% phenoPlotMC(outName, modelName, dateMethod, plotWhat);