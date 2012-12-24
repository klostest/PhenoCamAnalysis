function [] = VI_curve(siteInfo, modelName)
%============================================
% [] = VI_curve(siteInfo, modelName)
%
%% description
% This function fits a model to preprocessed vegetation index time series
% data.
% Results, including modeled vegetation index values and estimated
% parameters, are saved in the directory containing the data.
%
%% inputs
% 'siteInfo' is a string which is the filename of a .mat file in the current
% directory, containing information about the preprocessing session.  See
% below for 'example arguments' to work with the sample data.
% siteInfo = 'phenocam-siteInfo-BoundaryWaters';
% siteInfo = 'phenocam-siteInfo-HarvardTree3GWW';
% siteInfo = 'HarvardTowerBroad-EVI-siteInfo';
%
% 'modelName' is a string containing the type of function fit to the data.
% Possible arguments are: 'separateSigmoids'  See below for example
% arguments to work with the sample data.
% modelName = 'greenDownSigmoid';
% modelName = 'separateSigmoids';
%
%% dependencies
% This function calls model and estimator functions specified by the
% handles 'estimatorHandle' and 'fhandle'
%
%============================================
% Stephen Klosterman
% 11/20/2011
% steve.klosterman@gmail.com
%============================================

%% Load the names and number of sites, where the data came from, and what
%% kind of data it is
load(siteInfo); %Ex. 'MODIS-EVI-siteInfo'
%contains 'siteNames', 'nSites', 'remotelySensedQuantity',...
%    'loadDir', 'saveDir'

%% assign estimator and model function handles depending on model
switch modelName
    case 'separateSigmoids'
        estimatorHandle = @estParamsSeparateSigmoids;
        fhandle = @singleSigmoid;
    case 'fullYearSigmoid'
        estimatorHandle = @estParamsFullYearSigmoid;
        fhandle = @fullYearSigmoid;
    case 'greenDownSigmoid'
        estimatorHandle = @estParamsGreenDownSigmoid;
        fhandle = @greenDownSigmoid;
    case 'piecewise'
        estimatorHandle = @estParamsPiecewise;
        fhandle = @piecewise;
    case 'greenDownRichards'
        estimatorHandle = @estParamsGreenDownRichards;
        fhandle = @greenDownRichards;
    case 'smoothInterp'
        fhandle = @smoothInterp;
    %case 'separateGompertz'
    %case 'pieceWiseLinear'
    %case 'Richards'
end
    

%% For each site
for fitOuterLoop = 1:length(sites)
    load([saveDir sites{fitOuterLoop} '-' remotelySensedQuantity]);
    
%% For each year
    for i = 1:length(unYears)
        %Get model parameters a full year time series for modeled values.
        %modelT may be the same as T depending on the model.
        
        if ~strcmp(modelName, 'smoothInterp')
        
        [params{i}, modelT{i}, modelY{i}, cutOffDates{i},...
            resnorm{i}, initGuess{i}, initGuessY{i}, weighting{i}...
            residual{i}, jacobian{i}] = ...
            estimatorHandle(fhandle, modelName, T{i}, Y{i});
        else
        [modelT{i}, modelY{i}] = ...
            fhandle(T{i}, Y{i});
        end
%             springParams{i} = estParamsSeparateSigmoids(fhandle);
%             springModel{i} = fhandle(springParams{i}, springTime{i});
%             
%             fallParams{i} = estParams(fallData{i}, initGuess2{i},...
%                 fallTime{i}, fhandle2);
%             fallModel{i} = fhandle2(fallParams{i}, fallTime{i});
    fprintf('Done with %s %d\n', sites{fitOuterLoop},...
        unYears(i));
    end
    
    %save
    %get index name
    siteInfoSplit = regexp(siteInfo, '-', 'split');
    savename = [modelName '-params-' sites{fitOuterLoop}...
        '-' siteInfoSplit{2}];
    save([saveDir savename]);
end