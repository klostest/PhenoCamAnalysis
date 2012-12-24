function [] = phenoPlotMC(loadName, modelName, dateMethod, plotWhat,...
    yearIndex)
%============================================
% [] = phenoPlot(loadName, modelName, dateMethod, plotWhat)
%
%% description
% This function plots the results of preprocessing vegetation index time
% series, fitting a model to it, and extracting phenology dates from the
% modeled time series.
%
%% inputs
% loadName is a string which is the filename of a .mat file in the current
% directory containing information about the site, the type of vegetation
% index, and where the data is stored
% loadName = 'phenocam-siteInfo-Bartlett';
% loadName = 'phenocam-siteInfo-HarvardTree3';
% loadName = 'Bartlett-EVI-siteInfo';
%
% modelName is a string used to indicate which model the data has been fit
% to
% modelName = 'separateSigmoids';
% modelName = 'greenDownSigmoid';
%
% dateMethod is a string indicating the method used to extract phenology
% dates
% dateMethod = 'CCR';
% 
% plotWhat is a structure with the following fields:  rawData, weighting, 
% processedData, model, phenoDates, and legendSwitch.  Fields must be set
% to either 1, to see the data, or zero, to not see it.  For example, to
% see only the raw data and a legend, set plotWhat.rawData = 1,
% plotWhat.legendSwitch = 1, and all other fields to zero.
plotWhat.rawData = 0;
plotWhat.processedData = 1;
plotWhat.weighting = 0;
plotWhat.model = 1;
plotWhat.modelMC = 1;
plotWhat.phenoDates = 1;
plotWhat.legendSwitch = 1;
%
%% notes
% Manual placement of the legend is recommended for best results.
%
%============================================
% Stephen Klosterman
% 3/25/2012
% steve.klosterman@gmail.com
%============================================

%% example arguments
% loadName = 'MODIS-EVI-siteInfo';
% loadName = 'GCC-siteInfo';
% modelName = 'separateSigmoids';
% dateMethod = 'CCR';
% dateMethod = 'secondDeriv';

%% Plot attributes
lineWidth = 2;
markerSize = 8;
fontSize = 14;
% position vector or string for legend location
legendLoc = [0.4 0.9 0.2 0.1];
%screen size
scrsz = get(0,'ScreenSize');

%% Load the names and number of sites, where the data came from, and what
%% kind of data it is
% this code designed for when there's just one site and one year
load(loadName); %Ex. 'MODIS-EVI-siteInfo'
%contains 'siteNames', 'nSites', 'remotelySensedQuantity',...
%    'loadDir', 'saveDir'

% load optimal parameters
site = sites{1};
siteInfoSplit = regexp(loadName, '-', 'split');
loadname = [modelName '-params-' site...
        '-' siteInfoSplit{2}];
load([saveDir loadname]);
    
% load optimal phenology dates and samples of parameter space and
% phenology dates
    phenoLoadName = [site '-' siteInfoSplit{2}...
        '-phenoDatesMC-' modelName ...
        '-' dateMethod];
load([saveDir phenoLoadName], 'sixDates', 'sixDatesMC', 'R');

% assign model function alias
switch modelName
    case 'separateSigmoids'
        fhandle = @singleSigmoid;
    case 'fullYearSigmoid'
        fhandle = @fullYearSigmoid;
    case 'greenDownSigmoid'
        fhandle = @greenDownSigmoid;
    %case 'separateGompertz'
    %case 'pieceWiseLinear'
    %case 'spline'
    %case 'Richards'
end

% make smoother modeled time series
modelT{yearIndex} = min(modelT{yearIndex}):0.1:max(modelT{yearIndex});

% generate modeled time series for all parameter sets
for i = 1:size(R{yearIndex},1)
    if strcmp(modelName, 'separateSigmoids')
        %need to do something here to get separateSigmoids to plot
    else
        modelY_MC(i,:) = fhandle(R{yearIndex}(i,:), modelT{yearIndex});
    end
end
modelY{yearIndex} = fhandle(params{yearIndex}, modelT{yearIndex});

%make figure window
figure('Position',[1 1 scrsz(3) scrsz(4)])


    
%initialize object handles, array to hold all data
h1 = []; h2 = []; h3 = []; h4 = []; h5 = [];
allData = [];
        
        set(gca, 'FontSize', fontSize);

        if plotWhat.modelMC
            countPosParams = 0;
            for i = 1:size(R{yearIndex},1)
                %don't plot negative parameter values
                if R{yearIndex}(i,6) > 0
                %plot models
                    h3(i) = plot(modelT{yearIndex}(modelY_MC(i,:)~=0),...
                    modelY_MC(i,modelY_MC(i,:)~=0),...
                    '-',...
                    'color', [0.5 0.5 0.5],...
                    'lineWidth', lineWidth); hold on;
                %lump all data for setting axis limits
                allData = [allData modelY_MC(i,modelY_MC(i,:)~=0)];
                countPosParams = countPosParams + 1;
                end
            end
            legendStrings{3} = [modelName ' model'];
        end
        
        if plotWhat.rawData
            %plot raw data
            h1 = plot(Traw{yearIndex}, Yraw{yearIndex},...
                '.', 'color', 0.3*[1 1 1],...
                'markerSize', markerSize,...
                'lineWidth', lineWidth/2);
            legendStrings{1} = 'raw data';
            %lump all data for setting axis limits
            allData = [allData Yraw{1}'];
        end
        
        if plotWhat.processedData
        %plot processed data
        h2 = plot(T{yearIndex}, Y{yearIndex},...
            'o', 'color', [0 0.5 0],...
            'markerSize', markerSize,...
            'lineWidth', lineWidth); hold on;
        legendStrings{2} = 'processed data';
        %lump all data for setting axis limits
        allData = [allData Y{1}];
        end
        
        if plotWhat.model
        %plot model
        h3 = plot(modelT{yearIndex}(modelY{yearIndex}~=0),...
            modelY{yearIndex}(modelY{yearIndex}~=0),...
            '-',...
            'color', [1 0 0],...
            'lineWidth', lineWidth);
        legendStrings{3} = [modelName ' model'];
        %lump all data for setting axis limits
        allData = [allData modelY{yearIndex}];
        end
        
        if plotWhat.weighting
        %plot model
        mask = weighting{yearIndex}.weightMask;
        mask = logical(mask);
        h5 = plot(modelT{yearIndex}(mask),...
            modelY{yearIndex}(mask),...
            '-',...
            'color', [1 1 0],...
            'lineWidth', lineWidth);
        legendStrings{3} = [modelName ' model'];
        %lump all data for setting axis limits
        allData = [allData modelY{1}];
        end
        
        if plotWhat.phenoDates
        %plot pheno dates, throwing out zeros put in for error checking
        for j = 1:6
            if sixDates(j,yearIndex) ~= 0
            h4 = plot([sixDates(j,yearIndex) sixDates(j,yearIndex)],...
                [min([Y{yearIndex} modelY{yearIndex}])...
                max([Y{yearIndex} modelY{yearIndex}])],...
                'color', [0 0 1],...
                'lineWidth', lineWidth*0.5);
            end
        legendStrings{4} = [dateMethod ' method'];
        end
        end
        
        %annotate
            title([site ' ' num2str(unYears)]);
            xlabel('DOY'); ylabel(remotelySensedQuantity);

            %concatenate object handles for legend
            h = [h1 h2 h3(1) h4];
            %what legend strings are empty? get rid of them
            A = cellfun('isempty', legendStrings);
            A = 1 - A;
            A = logical(A);
            legendStrings = legendStrings(A);
            legend(h, legendStrings,...
                'Location', legendLoc);
            clear legendStrings

    
    %Set all axes limits
        set(gca, 'Ylim', [min(allData(allData~=0)),...
            max(allData(allData~=0))],...
            'Xlim', [0 365], 'xminorgrid', 'on');