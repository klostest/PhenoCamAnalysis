function [] = phenoPlotMultiRun(loadName, modelName, dateMethod)
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
% loadName = 'phenocam-siteInfo-Umich';
loadName{1} = 'Bartlett-EVI-siteInfo';
% loadName{2} = 'UmichBroad-EVI-siteInfo';
loadName{2} = 'phenocam-siteInfo-Bartlett';
%
% modelName is a string used to indicate which model the data has been fit
% to
modelName = 'separateSigmoids';
% modelName = 'greenDownSigmoid';
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
lineStyles = {'-', '.', '--'};
markers = {'x', 'o', 'square'};

year = 5;  %year index
%% For each site
for outerLoop = 1:length(loadName)
    load(loadName{outerLoop}); %Ex. 'MODIS-EVI-siteInfo'
    site = sites{1};
    loadname = [modelName '-params-' site];
    load([saveDir loadname]);
    
    %get pheno dates
    phenoLoadName = [site ...
        '-phenoDates-' modelName ...
        '-' dateMethod];
    load([saveDir phenoLoadName], 'sixDates');
    
    %initialize object handles, array to hold all data
    h1 = []; h2 = []; h3 = []; h4 = []; h5 = [];
    allData = [];

%% For one year
        
%         set(gca, 'FontSize', fontSize);
        
        dataX{outerLoop} = T{year};
        dataY{outerLoop} = Y{year};
%             'color', [0 0 0],...
%             'lineStyle', 'none',...
%             'marker', markers{outerLoop},...
%             'markerSize', markerSize,...
%             'lineWidth', lineWidth); hold on;
%         legendStrings{2} = 'processed data';
%         %lump all data for setting axis limits
%         allData = [allData Y{year}];
        
%         if plotWhat.model
        %plot model
        tempX = 1:200;
        plotModelX{outerLoop} = tempX;
        plotModelY{outerLoop} = singleSigmoid(params{year}(1,:), tempX);
        tempX = 201:365;
        tempY = singleSigmoid(params{year}(2,:), tempX);
        plotModelX{outerLoop} = [plotModelX{outerLoop} tempX];
        plotModelY{outerLoop} = [plotModelY{outerLoop} tempY];
        
%         h3 = plot(X1, Y1, X2, Y2,...
%             'color', [0 0 0],...
%             'lineWidth', lineWidth,...
%             'lineStyle', lineStyles{outerLoop});
%         legendStrings{3} = [modelName ' model'];
%         %lump all data for setting axis limits
%         allData = [allData modelY{year}];
%         end
        
        %plot pheno dates, throwing out zeros put in for error checking
        phenoDate1(outerLoop) = sixDates(1,year);
        phenoDate2(outerLoop) = sixDates(4,year);   
               
end

[AX, H1, H2] = plotyy(plotModelX{1}, plotModelY{1}, plotModelX{2}, plotModelY{2});

linewidth = 2; fontsize = 14;
set(H1, 'LineWidth', linewidth, 'LineStyle', '-');
set(H2, 'LineWidth', linewidth, 'Color', 'red', 'LineStyle', '-');

set(AX(1), 'FontSize', fontsize,...
    'xlim', [0 365]);
set(AX(2), 'FontSize', fontsize,...
    'YColor', 'red',...
    'xlim', [0 365]);

hold(AX(1), 'on');
hold(AX(2), 'on');

set(get(AX(1), 'YLabel'), 'String',...
    'MODIS EVI', 'FontSize', fontsize);
set(get(AX(2), 'YLabel'), 'String',...
    'camera GCC', 'FontSize', fontsize);
set(get(AX(2), 'XLabel'), 'String',...
    'DOY', 'FontSize', fontsize);

plot(dataX{2}, dataY{2}, 'x',...
    'markerSize', markerSize,...
    'color', 'red',...
    'parent', AX(2));

plot(dataX{1}, dataY{1}, 'x',...
    'markerSize', markerSize,...
    'color', 'blue',...
    'parent', AX(1));

plot([phenoDate1(2) phenoDate1(2)],...
    [0 1],...
    [phenoDate2(2) phenoDate2(2)],...
    [0 1],...
    'linewidth', 1,...
    'color', 'red',...
    'parent', AX(2));

plot([phenoDate1(1) phenoDate1(1)],...
    [0 1],...
    [phenoDate2(1) phenoDate2(1)],...
    [0 1],...
    'linewidth', 1,...
    'color', 'blue',...
    'parent', AX(1));

title('Bartlett 2009');