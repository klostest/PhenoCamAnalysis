function [] = phenoPlotOneYear(saveDir, loadname, modelName, dateMethod, plotWhat)
%% Plot attributes
lineWidth = 2;
markerSize = 8;
fontSize = 14;
% position vector or string for legend location
legendLoc = [0.4 0.9 0.2 0.1];
%screen size
scrsz = get(0,'ScreenSize');

% %% Load the names and number of sites, where the data came from, and what
% %% kind of data it is
% load(loadName); %Ex. 'MODIS-EVI-siteInfo'
% %contains 'siteNames', 'nSites', 'remotelySensedQuantity',...
% %    'loadDir', 'saveDir'
% siteNamesToPlot = sites;

% plotWhat.rawData = 0;
% plotWhat.processedData = 1;
% plotWhat.model = 0;
% plotWhat.phenoDates = 1;

%% load model parameters and phenodates

%     site = 'groundhog';
%     site = 'harvard';
%     site = 'acadia';
%     modelName = 'greenDownSigmoid';
%     modelName = 'greenDownRichards';
%     modelName = 'separateSigmoids';
% modelName = 'smoothInterp';
%     dateMethod = 'CCR';
% dateMethod = 'fallRedMax';
%     saveDir = '../results/';
%     loadname = [modelName '-params-' site '-RCC.mat'];
    load([saveDir loadname]);
    
    site = sites{1};
    
    %get pheno dates
    phenoLoadName = [site '-RCC' ...
        '-phenoDates-' modelName ...
        '-' dateMethod];
    load([saveDir phenoLoadName], 'sixDates', 'unYears',...
        'Y', 'T', 'Yraw', 'Traw', 'params', 'modelT', 'modelY');
        
    year = 2011;
    i = (unYears == year);
%     %make figure window
%     figure('Position',[1 1 scrsz(3) scrsz(4)])
    
    %initialize object handles, array to hold all data
    h1 = []; h2 = []; h3 = []; h4 = []; h5 = [];
    allData = [];

%% For each year
%     for i = 1:nYears
        
        set(gca, 'FontSize', fontSize);

        if plotWhat.rawData
            %plot raw data
            h1 = plot(Traw{i}, Yraw{i},...
                '.', 'color', 0.3*[0 0 0],...
                'markerSize', markerSize,...
                'lineWidth', lineWidth); hold on;
            legendStrings{1} = 'raw data';
            %lump all data for setting axis limits
            allData = [allData Yraw{i}'];
        end
        
        if plotWhat.processedData
        %plot processed data
        h2 = plot(T{i}, Y{i},...
            'o', 'color', [0 0 0],...
            'markerSize', markerSize,...
            'lineWidth', 1); hold on;
        legendStrings{2} = 'processed data';
        %lump all data for setting axis limits
        allData = [allData Y{i}];
        end
        
        if plotWhat.model
        %plot model
        h3 = plot(modelT{i}(modelY{i}~=0), modelY{i}(modelY{i}~=0),...
            '-',...
            'color', [0 0 0],...
            'lineWidth', lineWidth);
        legendStrings{3} = [modelName ' model'];
        %lump all data for setting axis limits
        allData = [allData modelY{i}];
        end
        
%         if plotWhat.weighting
%         %plot model
%         mask = weighting{i}.weightMask; mask = logical(mask);
%         h5 = plot(modelT{i}(mask),...
%             modelY{i}(mask),...
%             '.',...
%             'color', [1 1 0],...
%             'lineWidth', lineWidth);
%         legendStrings{3} = [modelName ' model'];
%         %lump all data for setting axis limits
%         allData = [allData modelY{i}];
%         end
        
        if plotWhat.phenoDates
        %plot pheno dates, throwing out zeros put in for error checking
        for j = 1:6
            if sixDates(j,i) ~= 0
            h4 = plot([sixDates(j,i) sixDates(j,i)],...
                [min([Y{i} modelY{i}])...
                max([Y{i} modelY{i}])],...
                'color', [0 0 0],...
                'lineWidth', lineWidth);
            end
        legendStrings{4} = [dateMethod ' method'];
        end
        end
        
        %annotate
%         title([num2str(unYears(i))]);
        xlabel('DOY 2011');
        ylabel(remotelySensedQuantity);
        
%         if (i == nYears) && (plotWhat.legendSwitch)
%             %concatenate object handles for legend
%             h = [h1 h2 h3 h4];
%             %what legend strings are empty? get rid of them
%             A = cellfun('isempty', legendStrings);
%             A = 1 - A;
%             A = logical(A);
%             legendStrings = legendStrings(A);
%             legend(h, legendStrings,...
%                 'Location', legendLoc);
%             clear legendStrings
%         end
               
    
    %Set all axes limits
    for i = 1:nYears
        set(gca, 'Ylim', [min(allData(allData~=0)),...
            max(allData(allData~=0))],...
            'Xlim', [0 365]);
    end
    %pause to allow graph settings to be made
    set(gca, 'FontSize', 18);
    xlabel('DOY 2011');
        ylabel(remotelySensedQuantity);
    pause(0.2);