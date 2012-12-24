function [] = phenoModisOneYear(loadName, modelName, dateMethod, plotWhat)
%% Plot attributes
lineWidth = 2;
markerSize = 12;
fontSize = 18;
% position vector or string for legend location
legendLoc = [0.4 0.9 0.2 0.1];
%screen size
scrsz = get(0,'ScreenSize');
% figure('Position', [0 0 700 300]);
figh = figure('Position',[1 1 scrsz(3) scrsz(4)]);

%annotate
% xlabel('Day of year 2011');
left = 0.15;
bottom = 0.17;
top = 0.57;
width = 0.75;
height = 0.4;

% %% Load the names and number of sites, where the data came from, and what
% %% kind of data it is
% load(loadName); %Ex. 'MODIS-EVI-siteInfo'
% %contains 'siteNames', 'nSites', 'remotelySensedQuantity',...
% %    'loadDir', 'saveDir'
% siteNamesToPlot = sites;

plotWhat.rawData = 0;
plotWhat.processedData = 1;
plotWhat.model = 1;
plotWhat.phenoDates = 1;

%% load model parameters and phenodates

    site = 'upperbuffalo';
    year = 2006;
%     site = 'acadia';
    modelName = 'greenDownRichards';
%     modelName = 'greenDownSigmoid';
%     modelName = 'separateSigmoids';
    dateMethod = 'CCR';
%     saveDir = 'PhenoCamSingleTrees/';
    titles = {'PhenoCam', 'MODIS'};
paramFiles{2} = ['./MODIS_NBAR/' modelName '-params-'...
    site '-EVI.mat'];
paramFiles{1} = ['./PhenoCam/' modelName '-params-'...
    site '-GCC.mat'];
dateFiles{2} = ['./MODIS_NBAR/'...
    site '-EVI-phenoDates-' modelName '-CCR.mat'];
dateFiles{1} = ['./PhenoCam/'...
    site '-GCC-phenoDates-' modelName '-CCR.mat'];
for j = 1:2
    axh(j) = subplot(2,1,j);
    loadname = [modelName '-params-' site '.mat'];
    load(paramFiles{j});
    
    i = (unYears == year);
    
    %get pheno dates
    load(dateFiles{j}, 'sixDates');
        
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
                'lineWidth', lineWidth/2); hold on;
            legendStrings{1} = 'raw data';
            %lump all data for setting axis limits
            allData = [allData Yraw{i}'];
        end
        
        if plotWhat.processedData
        %plot processed data
        h2 = plot(T{i}, Y{i},...
            'x', 'color', [0 0 0],...
            'markerSize', markerSize,...
            'lineWidth', 1); hold on;
        legendStrings{2} = 'processed data';
        %lump all data for setting axis limits
        allData = [allData Y{i}];
        end
        
        if plotWhat.model
        %plot model

            modelTsmooth = min(modelT{i}):max(modelT{i});
            modelYsmooth = fhandle(params{i}, modelTsmooth);

        
%         %accumulated greeness
%         for k = 1:length(T{i})
%             if k == 1
%                 modelYsmooth(k) = Y{i}(k)*T{i}(k);
%             else
%                 modelYsmooth(k) = Y{i}(k)*(T{i}(k)-T{i}(k-1)) + ...
%                     modelYsmooth(k-1);
%             end
%         end
%         modelTsmooth = T{i};
        if strcmp(modelName, 'separateSigmoids')
            h3 = plot(modelT{i}, modelY{i},...
            '-',...
            'color', [0 0 0],...
            'lineWidth', lineWidth);
        else
        h3 = plot(modelTsmooth, modelYsmooth,...
            '-',...
            'color', [0 0 0],...
            'lineWidth', lineWidth);
        end
%         clear modelTsmooth modelYsmooth
%         h3 = plot(modelT{i}(modelY{i}~=0), modelY{i}(modelY{i}~=0),...
%             '-',...
%             'color', [0 0 0],...
%             'lineWidth', lineWidth);
        legendStrings{3} = [modelName ' model'];
        %lump all data for setting axis limits
        allData = [allData modelY{i}];
%         [R, P] = corrcoef(modelY{i}, Y{i}); rSq(j) = R(2,1)^2; disp(rSq(j));
%         p(j) = P(2,1);
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
        for k = 1:6
            if sixDates(k,i) ~= 0
            h4 = plot([sixDates(k,i) sixDates(k,i)],...
                [min([Y{i} modelY{i}])...
                max([Y{i} modelY{i}])],...
                'color', [0 0 0],...
                'lineWidth', 1);
            end
        legendStrings{4} = [dateMethod ' method'];
        end
        end
        
        
        
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
%     textH = text(155, 0.37, ...
%         [titles{j} ': r^2 = ' num2str(rSq(j), '%3.2f')]);
%     set(textH, 'fontSize', fontSize);
    ylabel(remotelySensedQuantity);
    pause(0.2);
    if (j == 1)
    set(gca, 'XTick', []);
    else
        xlabel(['Day of year ' num2str(year) ', Upper Buffalo']);
    end
end

set(axh(1), 'position', [left top width height]);
set(axh(2), 'position', [left bottom width height]);