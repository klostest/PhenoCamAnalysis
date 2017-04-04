function [] = master_function()
%% Select a 'sitename' and ROI from the PhenoCam web page
% site = 'bartlettir';
% ROI = 'DB_0002';
%%
% site = 'bartlett';
% ROI = 'DB_0003';
%%
% site = 'dukehw';
% ROI = 'DB_0001';
%%
% site = 'harvard';
% site = 'harvardbarn';
% ROI = 'DB_0001';
% site = 'harvardlph';
% ROI = 'DB_0002';
%%
% site = 'dollysods';
% ROI = 'DB_0001';
%%
site = 'uwmfieldsta';
ROI = 'DB_0001';

% % site = 'torgnon-ld';
% % ROI = 'DN_0001';
%% Select a csv file and index
%i.e. https://phenocam.sr.unh.edu/data/archive/harvardlph/ROI/harvardlph_DB_0002_3day.csv
% https://phenocam.sr.unh.edu/data/archive/harvardlph/ROI/harvardlph_DB_0002_1day.csv
product = '3day';
%Could also choose
% product = '1day';
index = 'gcc';
% index = 'rcc';
%% Select curve fit
% model_name = 'separateSigmoids';
% model_name = 'greenDownSigmoid';
% model_name = 'greenDownRichards';
model_name = 'smoothInterp';

%% Date estimation method
date_method = 'percentiles';
% date_method = 'fallRedMax';
% date_method = 'CCR';
%% Percentiles for date estimation
% percentiles = [0.10 0.50 0.50 0.10];  %for greenDownRichards
percentiles = [0.10 0.50 0.90];   %for smoothInterp

%% Load time series from PhenoCam web site
[years, T, Y] = GCC_load(site, ROI, product, index);
%Could save output from these and other functions, but this is just for
%illustrative use

%% Do curve fit
[params, modelT, modelY, cut_off_dates, fhandle,...
    jacobian, resnorm] = ...
    VI_curve(T, Y, years, model_name);

%% Estimate phenology dates
[six_dates] = ...
    getPhenoDates(years, model_name, params, modelT, modelY,...
    T, Y,...
    date_method, percentiles,...
    cut_off_dates,...
    fhandle, site, ROI, index);

%% Monte Carlo
% getPhenoDatesMC(years, model_name, params, modelT, modelY,...
% T, Y,...
% date_method, percentiles,...
% cut_off_dates,...
% fhandle, site, ROI, index,...
% jacobian, resnorm);

%% Save phenology dates
% save(['./output/' site '_' ROI '_' model_name '_dates'],...
%     'six_dates', 'modelT', 'modelY',...
%     'years', 'model_name', 'T', 'Y');
%Also as csv


%% Plot all years
phenoPlot(years, index, T, Y, modelT, modelY, six_dates,...
    model_name, date_method, site, ROI);

%% Plot one year
% year_index = 3;
% pheno_plot_one_year(years, year_index,...
%     index, T, Y, modelT,...
%     modelY, six_dates,...
%     model_name, date_method, site, ROI, base_green);