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
loadName{1} = 'umichbiological-EVI-siteInfo';
loadName{2} = 'phenocam-siteInfo-UMich';
% loadName{1} = 'bartlett-EVI-siteInfo';
% loadName{2} = 'phenocam-siteInfo-Bartlett';
% loadName{1} = 'smokylook-EVI-siteInfo';
% loadName{2} = 'phenocam-siteInfo-SmokyLook';
% loadName{1} = 'arbutuslake-EVI-siteInfo';
% loadName{2} = 'phenocam-siteInfo-ArbutusLake';
year = 2010;  %year
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
markerSize = 12;
fontsize = 18;
% position vector or string for legend location
legendLoc = [0.4 0.9 0.2 0.1];
%screen size
lineStyles = {'-', '.', '--'};
markers = {'x', 'o', 'square'};

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
        
        dataX{outerLoop} = T{unYears==year};
        dataY{outerLoop} = Y{unYears==year};
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

        
%% for plotting separate sigmoids        
%         tempX = 1:200;
%         plotModelX{outerLoop} = tempX;
%         plotModelY{outerLoop} = singleSigmoid(params{year}(1,:), tempX);
%         tempX = 201:365;
%         tempY = singleSigmoid(params{year}(2,:), tempX);
%         plotModelX{outerLoop} = [plotModelX{outerLoop} tempX];
%         plotModelY{outerLoop} = [plotModelY{outerLoop} tempY];
%% for plotting greendown sigmoid
        plotModelX{outerLoop} = 1:365;
        plotModelY{outerLoop} = greenDownSigmoid(params{unYears==year}, plotModelX{outerLoop});
        
%         h3 = plot(X1, Y1, X2, Y2,...
%             'color', [0 0 0],...
%             'lineWidth', lineWidth,...
%             'lineStyle', lineStyles{outerLoop});
%         legendStrings{3} = [modelName ' model'];
%         %lump all data for setting axis limits
%         allData = [allData modelY{year}];
%         end
        
        %plot pheno dates, throwing out zeros put in for error checking
        phenoDates(:,outerLoop) = sixDates(:,unYears==year);
%         phenoDate2(outerLoop) = sixDates(4,year);
end

scrsz = get(0,'ScreenSize');
figure('Position',[1 1 scrsz(3) scrsz(4)])
colors = [0, 0, 1
    1, 0, 0];
[AX, H1, H2] = plotyy(plotModelX{1}, plotModelY{1}, plotModelX{2}, plotModelY{2});

linewidth = 2;
set(H1, 'LineWidth', linewidth, 'LineStyle', '-');
set(H2, 'LineWidth', linewidth, 'Color', 'red', 'LineStyle', '-');

padding = 0.2;
ylims(1,1) = min(plotModelY{1}) - padding * ( max(plotModelY{1}) - min(plotModelY{1}) );
ylims(1,2) = max(plotModelY{1}) + padding * ( max(plotModelY{1}) - min(plotModelY{1}) );
ylims(2,1) = min(plotModelY{2}) - padding * ( max(plotModelY{2}) - min(plotModelY{2}) );
ylims(2,2) = max(plotModelY{2}) + padding * ( max(plotModelY{2}) - min(plotModelY{2}) );

set(AX(1), 'FontSize', fontsize,...
    'xlim', [0 365], 'ylim', ylims(1,:));
set(AX(2), 'FontSize', fontsize,...
    'YColor', 'red',...
    'xlim', [0 365], 'ylim', ylims(2,:));

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
    'linewidth', lineWidth,...
    'color', 'red',...
    'parent', AX(2));

plot(dataX{1}, dataY{1}, 'o',...
    'markerSize', markerSize,...
    'linewidth', lineWidth,...
    'color', 'blue',...
    'parent', AX(1));

for i = 1:size(phenoDates,2)
    for j = 1:size(phenoDates,1)
        tempH = plot([phenoDates(j,i) phenoDates(j,i)],...
            [0 1],...
            [phenoDates(j,i) phenoDates(j,i)],...
            [0 1],...
            'linewidth', 2,...
            'parent', AX(i));
        if i == 2
            set(tempH, 'linestyle', '--');
        end
        set(tempH, 'color', colors(i,:));
        hold on
    end
end

% title('Bartlett 2009');
% title('Smoky Look 2004');
title([site ' ' num2str(year)]);