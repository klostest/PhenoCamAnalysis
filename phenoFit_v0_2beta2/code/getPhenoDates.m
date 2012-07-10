function [] = getPhenoDates(loadName, modelName, dateMethod)
%============================================
% [] = getPhenoDates(loadName, modelName, dateMethod)
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
loadName = 'phenocam-siteInfo-HarvardTower';
% loadName = 'phenocam-siteInfo-Niwot';
% loadName = 'ArbutusBroad-EVI-siteInfo';
% modelName is a string used to indicate which model the data has been fit
% to.  Possible arguments are 'separateSigmoids'.
% modelName = 'separateSigmoids';
modelName = 'greenDownSigmoid';
%
% dateMethod is a string indicating the method used to extract phenology
% dates 'secondDeriv' and 'CCR'
dateMethod = 'CCR';
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
    %to be added
    %case 'separateGompertz'
    %case 'pieceWiseLinear'
    %case 'spline'
    %case 'Richards'
end
    
%% get pheno dates
for i = 1:nSites    

    site = sites{i};
    loadname = [modelName '-params-' site];
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
                            Kprime)';
                        sixDates(1:3,j) = temp;
                        %fall
                        temp = CCR(params{j}(2,:),...
                            modelT{j}( modelT{j} >= cutOffDates{j}(2) ),...
                            Kprime )';
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
                    case 'secondDeriv'
                        tempParams = [params{j}(3)/params{j}(4)...
                            -1/params{j}(4);
                            params{j}(5)/params{j}(6)...
                            -1/params{j}(6)];
                            
                        sixDates(:,j) = secondDeriv(tempParams, minMax,...
                            T{j}, cutOffDates{j});

                    case 'CCR'
                        %spring
                        springParams = [params{j}(3)/params{j}(4)...
                            -1/params{j}(4)...
                            params{j}(2) params{j}(1)];%[m1 m2 vamp vmin]
                        temp = CCR(springParams,...
                            modelT{j},...
                            Kprime)';
                        sixDates(1:3,j) = temp;
                        %fall
                        fallParams = [params{j}(5)/params{j}(6)...
                            -1/params{j}(6)...
                            params{j}(2) params{j}(1)];%[m3 m4 vamp vmin]
                        temp = CCR(fallParams,...
                            modelT{j},...
                            Kprime)';
                        sixDates(4:6,j) = temp;
                end
                
        end
%         fprintf('Done with %s %d\n', site, unYears(i));

    end
    
    savename = [site '-phenoDates-' modelName ...
        '-' dateMethod];
    save([saveDir savename]);
end