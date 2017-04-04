function [] = pheno_plot_one_year(years, year_index,...
    index, T, Y, modelT,...
    modelY, six_dates,...
    model_name, date_method, site, ROI, base_green)
%% Plot attributes
lineWidth = 2;
markerSize = 8;
fontSize = 14;
% position vector or string for legend location
legendLoc = [0.4 0.9 0.2 0.1];
%screen size
scrsz = get(0,'ScreenSize');
   
%make figure window
figure('Position',[1 1 scrsz(3) scrsz(4)])
    
%initialize object handles, array to hold all data
h1 = []; h2 = []; h3 = []; h4 = []; h5 = [];
allData = [];

%% For one year
i = year_index;
        
    axh(i) = axes;    %for one plot
    set(gca, 'FontSize', fontSize);

    h2 = plot(T{i}, Y{i},...
        'o', 'color', [0 0.5 0],...
        'markerSize', markerSize,...
        'lineWidth', lineWidth); hold on;
    legendStrings{2} = 'gcc_90';
    %lump all data for setting axis limits
    allData = vertcat(allData, Y{i});
        
    %plot model
    h3 = plot(modelT{i}(modelY{i}~=0), modelY{i}(modelY{i}~=0),...
        '.',...
        'color', [1 0 0],...
        'MarkerSize', markerSize);
    legendStrings{3} = [model_name ' model'];
    %lump all data for setting axis limits
    allData = vertcat(allData, modelY{i});
    
    %plot pheno dates, throwing out zeros put in for error checking
    for j = 1:6
        if six_dates(j,i) ~= 0
        h4 = plot([six_dates(j,i) six_dates(j,i)],...
            [min(vertcat(Y{i}, modelY{i}))...
            max(vertcat(Y{i}, modelY{i}))],...
            'color', [0 0 1],...
            'lineWidth', lineWidth*0.5);
        end
        legendStrings{4} = [date_method ' method'];
    end
    
    %% Temporary, plot base greenness for smooth interp model
    plot([0 365], [base_green(i) base_green(i)], 'k-');
    %annotate
    if i == 1
        title_str = [site '_' ROI ' ' num2str(years{i})];
        title_str = strrep(title_str, '_', '-');
        title(title_str);
        xlabel('DOY'); ylabel(index);
    else
        title(years{i});
    end
        
    if (i == n_years)
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
               
    
%Set axes limits
    set(axh(i), 'Ylim', [min(allData(allData~=0)),...
        max(allData(allData~=0))],...
        'Xlim', [0 365], 'xminorgrid', 'on');