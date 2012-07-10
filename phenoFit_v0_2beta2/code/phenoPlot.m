function [] = phenoPlot(loadName, modelName, dateMethod, plotWhat)
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
loadName = 'phenocam-siteInfo-HarvardTower';
% loadName = 'Bartlett-EVI-siteInfo';
%
% modelName is a string used to indicate which model the data has been fit
% to
% modelName = 'separateSigmoids';
modelName = 'greenDownSigmoid';
%
% dateMethod is a string indicating the method used to extract phenology
% dates
dateMethod = 'CCR';
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
load(loadName); %Ex. 'MODIS-EVI-siteInfo'
%contains 'siteNames', 'nSites', 'remotelySensedQuantity',...
%    'loadDir', 'saveDir'

%% ask user which sites to plot
% for i = 1:length(sites)
%     askUser{i} = [num2str(i) '. ' sites{i}];
% end
% 
% fprintf(1, 'Which sites would you like to plot?\n');
% for i = 1:length(sites)
%     disp(askUser{i});
% end
% userWants = ...
%     input('Enter a comma separated list, e.g. 1,3,7,...\n or 0 to plot all sites:\n',...
%     's');
% 
% userWants = str2num(userWants);
% if userWants == 0
   siteNamesToPlot = sites;
% else
%    siteNamesToPlot = sites(userWants);
% end

%% For each site
for outerLoop = 1:length(siteNamesToPlot)
    site = siteNamesToPlot{outerLoop};
    loadname = [modelName '-params-' site];
    load([saveDir loadname]);
    
    %get pheno dates
    phenoLoadName = [site ...
        '-phenoDates-' modelName ...
        '-' dateMethod];
    load([saveDir phenoLoadName], 'sixDates');
        
    %make figure window
    figure('Position',[1 1 scrsz(3) scrsz(4)])
    
    %initialize object handles, array to hold all data
    h1 = []; h2 = []; h3 = []; h4 = []; h5 = [];
    allData = [];

%% For each year
    for i = 1:nYears
        
        axh(i) = subplot(round(nYears/2),2,i);
        set(gca, 'FontSize', fontSize);

        if plotWhat.rawData
            %plot raw data
            h1 = plot(Traw{i}, Yraw{i},...
                '.', 'color', 0.3*[1 1 1],...
                'markerSize', markerSize,...
                'lineWidth', lineWidth/2); hold on;
            legendStrings{1} = 'raw data';
            %lump all data for setting axis limits
            allData = [allData Yraw{i}'];
        end
        
        if plotWhat.processedData
        %plot processed data
        h2 = plot(T{i}, Y{i},...
            'o', 'color', [0 0.5 0],...
            'markerSize', markerSize,...
            'lineWidth', lineWidth); hold on;
        legendStrings{2} = 'processed data';
        %lump all data for setting axis limits
        allData = [allData Y{i}];
        end
        
        if plotWhat.model
        %plot model
        h3 = plot(modelT{i}(modelY{i}~=0), modelY{i}(modelY{i}~=0),...
            '.',...
            'color', [1 0 0],...
            'lineWidth', lineWidth);
        legendStrings{3} = [modelName ' model'];
        %lump all data for setting axis limits
        allData = [allData modelY{i}];
        end
        
        if plotWhat.weighting
        %plot model
        mask = weighting{i}.weightMask; mask = logical(mask);
        h5 = plot(modelT{i}(mask),...
            modelY{i}(mask),...
            '.',...
            'color', [1 1 0],...
            'lineWidth', lineWidth);
        legendStrings{3} = [modelName ' model'];
        %lump all data for setting axis limits
        allData = [allData modelY{i}];
        end
        
        if plotWhat.phenoDates
        %plot pheno dates, throwing out zeros put in for error checking
        for j = 1:6
            if sixDates(j,i) ~= 0
            h4 = plot([sixDates(j,i) sixDates(j,i)],...
                [min([Y{i} modelY{i}])...
                max([Y{i} modelY{i}])],...
                'color', [0 0 1],...
                'lineWidth', lineWidth*0.5);
            end
        legendStrings{4} = [dateMethod ' method'];
        end
        end
        
        %annotate
        if i == 1
            title([siteNamesToPlot{outerLoop} ' ' num2str(unYears(i))]);
            xlabel('DOY'); ylabel(remotelySensedQuantity);
        else
            title(num2str(unYears(i)));
        end
        
        if (i == nYears) && (plotWhat.legendSwitch)
            %concatenate object handles for legend
            h = [h1 h2 h3 h4];
            %what legend strings are empty? get rid of them
            A = cellfun('isempty', legendStrings);
            A = 1 - A;
            A = logical(A);
            legendStrings = legendStrings(A);
            legend(h, legendStrings,...
                'Location', legendLoc);
            clear legendStrings
        end
               
    end
    
    %Set all axes limits
    for i = 1:nYears
        set(axh(i), 'Ylim', [min(allData(allData~=0)),...
            max(allData(allData~=0))],...
            'Xlim', [0 365], 'xminorgrid', 'on');
    end
    %pause to allow graph settings to be made
    pause(0.2);
end