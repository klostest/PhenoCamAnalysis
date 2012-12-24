function [] = getPhenoDates(loadName, modelName, dateMethod, percentiles)
%============================================
% [] = getPhenoDates(loadName, modelName, dateMethod, varargin)
%
%% description
% This function uses a modeled timeseries of a vegetation index to estimate
% phenological transition dates.  Results are saved in the directory where
% the data and modeled time series results are.
%
%% inputs
% loadName is a string which is the filename of a .mat file in the current
% directory containing information about the site, the type of vegetation
% index, and where the data is stored.  See 'example arguments' below for
% appropriate arguments to work with the sample data.
% loadName = 'phenocam-siteInfo-BoundaryWaters';
% loadName = 'phenocam-siteInfo-HarvardTree3';
% loadName = 'ArbutusBroad-EVI-siteInfo';
% modelName is a string used to indicate which model the data has been fit
% to.  Possible arguments are 'separateSigmoids'.
% modelName = 'separateSigmoids';
% modelName = 'greenDownSigmoid';
%
% dateMethod is a string indicating the method used to extract phenology
% dates 'secondDeriv' and 'CCR'
% dateMethod = 'CCR';
% 
% percentiles are used by the 'percentiles' and 'dataPercentiles'
% dateMethods.  If using other methods, this variable must be assigned a
% value but it will be ignored.
%if using 'percentiles' dateMethod, specify 4 percentiles for beginning of
%spring, middle of spring, middle of fall, and end of fall.  CCR is used
%for end of spring and beginning of fall.  Dates are calculated as the date
%of crossing the value at this percentile between baseline and CCR value.
% e.g.
% percentiles = [0.10 0.50 0.50 0.10];
%if using 'dataPercentiles' dateMethod, specify 3 percentiles for
%beginning, middle, and end of spring, e.g.
% percentiles = [0.10 0.50 0.90];   %for dataPercentiles
%
%% notes
% The functions secondDeriv.m and CCR.m produce the .mat files containing
% the formulas used to extract phenology dates, secondDeriv_formula.mat and
% CCR_formula.mat.
%
%============================================
% Stephen Klosterman
% 11/20/2011
% steve.klosterman@gmail.com
%============================================
%% example arguments
% loadName = 'MODIS-EVI-siteInfo';
% loadName = 'GCC-siteInfo';
% modelName = 'separateSigmoids';
% dateMethod = 'secondDeriv';
% dateMethod = 'CCR';

%% Load the names and number of sites, where the data came from, and what
%% kind of data it is
load(loadName); %Ex. 'MODIS-EVI-siteInfo'
%contains 'siteNames', 'nSites', 'remotelySensedQuantity',...
%    'loadDir', 'saveDir'

%% load or define formula for calculating dates
switch modelName
    case 'separateSigmoids'
        switch dateMethod
            case 'secondDeriv'
                load('secondDeriv_formula', 'minMax');
            case 'CCR'
                load('CCR_formula.mat', 'Kprime');
        end
    case 'fullYearSigmoid'
        switch dateMethod
            case 'secondDeriv'
                load('secondDeriv_formula', 'minMax');
            case 'CCR'
                load('CCR_formula.mat', 'Kprime');
        end
    case 'greenDownSigmoid'
        switch dateMethod
            case 'secondDeriv'
                load('secondDeriv_formula', 'minMax');
            case 'CCR'
                load('CCR_formula.mat', 'Kprime');
        end
    case 'greenDownRichards'
        switch dateMethod
            case 'secondDeriv'
                load('secondDeriv_formula', 'minMax');
            case 'CCR'
                load('CCR_formula.mat', 'Kprime');
        end
    %to be added
    %case 'separateGompertz'
    %case 'pieceWiseLinear'
    %case 'spline'
    %case 'Richards'
end
    
%% get pheno dates
for i = 1:nSites    

    site = sites{i};
    siteInfoSplit = regexp(loadName, '-', 'split');
    loadname = [modelName '-params-' site...
        '-' siteInfoSplit{2}];
    load([saveDir loadname]);
    clear sixDates temp

    for j = 1:nYears
        
        switch modelName
            case 'separateSigmoids'
                switch dateMethod
                    case 'secondDeriv'
                        sixDates(:,j) = secondDeriv(params{j}, minMax,...
                            T{j}, cutOffDates{j});

                    case 'CCR'
                        %spring
                        temp = CCR(params{j}(1,:),...
                            modelT{j}( modelT{j} <= cutOffDates{j}(1) ),...
                            Kprime, fhandle)';
                        sixDates(1:3,j) = temp;
                        %fall
                        temp = CCR(params{j}(2,:),...
                            modelT{j}( modelT{j} >= cutOffDates{j}(2) ),...
                            Kprime, fhandle)';
                        sixDates(4:6,j) = temp;
                end
            case 'fullYearSigmoid'
                switch dateMethod
                    case 'secondDeriv'
                        sixDates(:,j) = secondDeriv(params{j}, minMax,...
                            T{j}, cutOffDates{j});

                    case 'CCR'
                        %spring
                        springParams = [params{j}(3) params{j}(4)...
                            params{j}(2) params{j}(1)];%[m1 m2 vamp vmin]
                        temp = CCR(springParams,...
                            modelT{j},...
                            Kprime)';
                        sixDates(1:3,j) = temp;
                        %fall
                        fallParams = [params{j}(5) params{j}(6)...
                            params{j}(2) params{j}(1)];%[m3 m4 vamp vmin]
                        temp = CCR(fallParams,...
                            modelT{j},...
                            Kprime)';
                        sixDates(4:6,j) = temp;
                end
            case 'greenDownSigmoid'
                switch dateMethod
                    case 'percentiles'
%                         percentiles = [0.10 0.50 0.50 0.10];
                        sixDates(:,j) = percentileDates(params{j}, modelT{j},...
                            fhandle, percentiles, modelName);
                    case 'secondDeriv'
                        %*** change from previous version, sigmoid
                        %parameters from fall sigmoid need to be multiplied
                        %by negative one to work with secondDeriv.m the
                        %same way singleSigmoids does
                        tempParams = [params{j}(3)/params{j}(4)...
                            -1/params{j}(4);
                            -params{j}(5)/params{j}(6)...
                            1/params{j}(6)];
                            
                        sixDates(:,j) = secondDeriv(tempParams, minMax,...
                            T{j}, cutOffDates{j});

                    case 'CCR'
                        sixDates(:,j) = CCRgd(params{j}, modelT{j},...
                            Kprime, fhandle);

%                         %spring
%                         springParams = [params{j}(3)/params{j}(4)...
%                             -1/params{j}(4)...
%                             params{j}(2) params{j}(1)];%[m1 m2 vamp vmin]
%                         temp = CCR(springParams,...
%                             modelT{j},...
%                             Kprime, fhandle)';
%                         sixDates(1:3,j) = temp;
%                         %fall
%                         fallParams = [params{j}(5)/params{j}(6)...
%                             -1/params{j}(6)...
%                             params{j}(2) params{j}(1)];%[m3 m4 vamp vmin]
%                         temp = CCR(fallParams,...
%                             modelT{j},...
%                             Kprime, fhandle)';
%                         sixDates(4:6,j) = temp;
                end
            case 'greenDownRichards'
                switch dateMethod
                    case 'CCR'
                        sixDates(:,j) = CCRgd(params{j}, modelT{j},...
                            Kprime, fhandle);
                    case 'percentiles'
%                         percentiles = [0.10 0.50 0.50 0.10];
                        sixDates(:,j) = percentileDates(params{j}, modelT{j},...
                            fhandle, percentiles, modelName);
                end
            case 'smoothInterp'
                switch dateMethod
                    case 'dataPercentiles'
                        sixDates(:,j) = dataPercentileDates(modelT{j},...
                            modelY{j},...
                            percentiles);
                    case 'fallRedMax'
                        sixDates(:,j) = fallRedMax(modelT{j},...
                            modelY{j},...
                            percentiles);
                end     
        end
%         fprintf('Done with %s %d\n', site, unYears(i));

    end
    
    savename = [site '-' siteInfoSplit{2} '-phenoDates-' modelName ...
        '-' dateMethod];
    save([saveDir savename]);
end