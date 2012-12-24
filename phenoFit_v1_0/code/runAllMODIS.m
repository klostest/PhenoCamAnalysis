function [] = runAllMODIS()

modelName = 'greenDownSigmoid';
dateMethod = 'CCR';
loadDir = '../../modisClient/modisPhenocamCompare/';
saveDir = './MODIS/';

% site = 'acadia';  %good
% site = 'arbutuslake';   %good
% site = 'bartlett';  %good
% site = 'boundarywaters';    %good, maybe could get 2007
% site = 'dollysods'; %good, maybe could get 2005
% site = 'groundhog'; %good
% site = 'harvard';   %good
% site = 'mammothcave';   %good
% site = 'monture';   %not consistent season to season
% site = 'mountzirkel';   %good but lots of missing data leading to missing curve fits
% site = 'nationalcapitol'; %good but 2004 autumn probably early
% site = 'queens';  %manually adjust QC for this one, likely due to water
% site = 'smokylook';   %good
% site = 'umichbiological';   %good, why not autumn 09?
% site = 'upperbuffalo';  %good

fname = [site '_MODIS_data.mat'];
savename = site;

% fname = [site '_reshaped_km_MODIS_data.mat'];
% savename = [site '_km'];

%choose EVI or NDVI to use these results
outName = [savename '-EVI' '-siteInfo'];
% outName = [savename '-NDVI' '-siteInfo'];

plotWhat.rawData = 0;
plotWhat.processedData = 1;
plotWhat.weighting = 0;
plotWhat.model = 1;
plotWhat.phenoDates = 1;
plotWhat.legendSwitch = 1;

% MODIS_load2(fname, loadDir, savename, saveDir);
% VI_curve(outName, modelName);
% getPhenoDates(outName, modelName, dateMethod);
phenoPlot(outName, modelName, dateMethod, plotWhat);