function [params, modelT, modelY, cut_off_dates, fhandle,...
    jacobian, resnorm] = ...
    VI_curve(T, Y, years, model_name)
%============================================
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
% 'model_name' is a string containing the type of function fit to the data.
% Possible arguments are: 'separateSigmoids'  See below for example
% arguments to work with the sample data.
% model_name = 'greenDownSigmoid';
% model_name = 'separateSigmoids';
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


%% assign estimator and model function handles depending on model
switch model_name
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
end

%% For each year
for i = 1:length(years)
    %Get model parameters a full year time series for modeled values.
    %modelT may be the same as T depending on the model.
        
    if ~strcmp(model_name, 'smoothInterp')
        [params{i}, modelT{i}, modelY{i}, cut_off_dates{i},...
            resnorm{i}, initGuess{i}, initGuessY{i}, weighting{i}...
            residual{i}, jacobian{i}] = ...
            estimatorHandle(fhandle, model_name, T{i}, Y{i});
    else
        %Smoothed and interpolated model, uses data fraction of 0.1 since
        %this is only designed for PhenoCam data
        [modelT{i}, modelY{i}] = ...
             fhandle(T{i}, Y{i}, 0.1);
         modelY{i} = modelY{i}';
         params = NaN; cut_off_dates = NaN;
         jacobian = NaN; resnorm = NaN;
    end
    
    fprintf(1, 'Done with curve fit for year %d of %d\n',...
        i, length(years));
end