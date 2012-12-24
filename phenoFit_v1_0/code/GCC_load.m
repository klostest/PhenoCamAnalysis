function [] = GCC_load(saveDir, outName, rawData, threshold,...
    filter, temporal, index)
% function [] = GCC_load(outName, rawData, temporal, threshold, filter)
%============================================
% GCC_load(outName, rawData, temporal, threshold, filter)
%
%% description
% This function loads raw GCC data, preprocesses, and saves for curve
% fitting.
% Raw data needs to be in the following format:
% 'YYYY DDD HH MM GCC', where YYYY is the four digit year, DDD is the day
% of year, HH is the one or two digit hour of day in military time, MM is
% the one or two digit minute, and GCC is the green chromatic coordinate.
% For example, a line of a text file should look like:
% '2008  164    8   16 0.396041'
% After loading data from text files and creating a directory for saving,
% any desired preprocessing is performed and data is saved in Matlab
% format.
%
%% inputs
% 'outName' is a string that will be appended to the end of the directory
% created to store results, which will be named 'phenocam-<outName>'
% in the current directory, as well as appended to the end of the .mat file
% containing information about this preprocessing session, which will be
% called 'phenocam-siteInfo-<outName>.mat'.

% outName = 'Umich';
% outName = 'Bartlett';
% outName = 'Niwot';
% outName = 'Arbutus';
% outName = 'HarvardTower';
% outName = 'HarvardTree3GWW';
% outName = 'MammothCave';
% outName = 'Acadia';
% outName = 'BartlettIR';
% outName = 'HarvardOaks';

%
% 'rawData' is a structure containing information about the raw GCC data to
% be loaded
% -'rawData.dir' is a relative path to a directory containing the site
% directories, e.g. '../../../phenoCamImages'
% -'rawData.maskName' is a string describing the mask used in creation of 
% raw time series data, e.g. 'deciduous'.
% rawData.sites = e.g. {'bartlett'};
% rawData.years = e.g. {2005:2012};

% rawData.sites = {'umichbiological'};
% rawData.maskName = '250m-MODIS-pixel-1';
% rawData.years = {2008:2012};

% rawData.sites = {'bartlett'};
% rawData.maskName = '250m-MODIS-pixel-1';
% rawData.years = {2005:2012};

% rawData.sites = {'harvardNearNoonGoodWeatherWeekly'};
% rawData.maskName = 'tree3';
% rawData.years = {2011};

% rawData.sites = {'mammothcave'};
% rawData.maskName = '250m-MODIS-pixel-1';
% rawData.years = {2002:2011};

% rawData.sites = {'acadia'};
% rawData.maskName = '250m-MODIS-pixel-1';
% rawData.years = {2007:2011};

% rawData.sites = {'arbutuslake'};
% rawData.maskName = '250m-MODIS-pixel-1';
% rawData.years = {2008:2012};

% rawData.sites = {'harvard'};
% rawData.maskName = '250m-MODIS-pixel-3';
% rawData.years = {2008:2012};

% rawData.sites = {'bartlettir'};
% rawData.maskName = '250m-MODIS-pixel-1';
% rawData.years = {2008:2011};

% rawData.sites = {'harvard'};
% rawData.maskName = 'oaks.csv';
% rawData.years = {2012};

% rawData.sites = {'harvardhemlock'};
% rawData.maskName = 'hemlocks.csv';
% rawData.years = {2012};

% rawData.dir = '../../../phenoCamImages';
% rawData.dir = '../../../../../../Volumes/FreeAgent GoFlex Drive/phenoCamImages';
% rawData.dir = '../../../ROI_info2';
%
% 'temporal' is a structure containing the temporal limitations placed on
% the raw data
% -'temporal.beginYear' is the day of year to start processing files, e.g.
% 0 for the beginning of the year
% -'temporal.endYear' is the day of year to stop processing files, e.g.
% 365 for the end of the year
% -'temporal.beginDay' is the hour of day in military format to start
% processing files, e.g. 9 for 9am
% -'temporal.endDay' is the hour of day in military format to stop
% processing files, e.g. 17 for 5pm
%fAPAR
% temporal.beginYear = 0;
% temporal.endYear = 365;

%phenocam
% temporal.beginYear = 0;
% temporal.endYear = 365;
% temporal.beginDay = 0;
% temporal.endDay = 24;
%
% -'threshold' is the fraction of the highest possible DN (255) that
% will be the minimum for R, G, and B DNs, e.g. 0.15
% threshold = 0.08;  %0.08 for acadia (?), 0.1 for upperbuffalo
%
% 'filter' is a structure containing instructions for filtering:
% -'filter.type' is a string indicating the type of filter to be used:
% 'none', 'quantile', 'mean', 'median'.
% -'filter.window' is the size in days of the moving window used for
% filtering. Sonnentag et al (2011, AFM) recommend a 3 day window for the
% per90 0.9 quantile filter.
% -'filter.quantile' is the desired quantile for the quantile filter.  Use
% 0.9 for a per90 filter, as described by Sonnentag et al.
% filter.type = 'quantile';
% filter.window = 3;
% filter.quantile = 0.9;
%
%% notes
% various spots in the code can be uncommented to visualize the results of
% thresholding or filtering in comparison to the raw data.  breakpoint
% before 'clf' commands to pause the code and view the plot, then step
% through.
%
%============================================
% Stephen Klosterman
% 3/24/2012
% steve.klosterman@gmail.com
%============================================

%% make a directory to save results
% saveDir = './PhenoCam/';
% mkdir(saveDir);

%% get file names of gcc time series

for i = 1:length(rawData.sites)
    loadDir = [rawData.dir filesep rawData.sites{i}];
    for j = 1:length(rawData.years{i})
        fNames{i}{j} = ['raw-' rawData.sites{i} '_' rawData.maskName '_'...
            num2str(rawData.years{i}(j)) '.txt'];
    end
end
% raw-bartlett_deciduous_2005.txt
% yyyy, DOY, R DN, G DN, B DN, GCC
% 2005,277.5,121.72,120.4,104.16,0.34769
nSites = length(rawData.sites); sites = rawData.sites;
remotelySensedQuantity = index;
%% Save info about this preprocessing session
save(outName,...
   'loadDir', 'saveDir', 'rawData', 'temporal', 'threshold', 'filter',...
   'nSites', 'remotelySensedQuantity', 'sites');

%% load data from text files into cell array for target sites

for i = 1:length(rawData.sites)
    for j = 1:length(rawData.years{i})
        
        %% load data
        tempData = ...
            importdata([loadDir filesep fNames{i}{j}]);
%         %*****Mike use this one******
%         tempData = ...
%             importdata(fNames{i}{j});
        DOY = tempData(:,2);
        RDN{j} = tempData(:,3);
        GDN{j} = tempData(:,4);
        BDN{j} = tempData(:,5);
        GCC = tempData(:,6);
        ExG = 2*GDN{j} - (RDN{j} + BDN{j});
        RCC = RDN{j} ./ (RDN{j} + GDN{j} + BDN{j});
        BCC = BDN{j} ./ (RDN{j} + GDN{j} + BDN{j});

        %% threshold
        maskLevel = threshold*255;
        mask = (RDN{j} > maskLevel) & ...
            (GDN{j} > maskLevel) & ...
            (BDN{j} > maskLevel);
        
        tempTraw = DOY;
        tempT = DOY(mask);
        
        scrsz = get(0,'ScreenSize');
        fhandle = figure('Position',[1 1 scrsz(3) scrsz(4)]);
        subplot(2,1,1)
        plot(tempT, GCC(mask), 'g', tempT, RCC(mask), 'r');
        title('GCC, RCC'); grid minor;
        subplot(2,1,2)
        plot(tempT, ExG(mask), 'g');
        title('ExG'); grid minor;
        close(fhandle);
        
        switch index
            case 'GCC'
                tempYraw = GCC;
                tempY = GCC(mask);
            case 'RCC'
                tempYraw = RCC;
                tempY = RCC(mask);
            case 'ExG'
                tempYraw = ExG;
                tempY = ExG(mask);
        end
        
        %% filter
        %window size of filter
        dayBlock = filter.window;   %3;
        %vector of days of year by window size
        dayVec = temporal.beginYear:dayBlock:temporal.endYear;
        % quantile for quantile filter
        quant = filter.quantile;   %0.9;
        
        switch filter.type
            case 'quantile'
                for k = 1:(length(dayVec)-1)
                    window = ((tempT >= dayVec(k)) & ...
                        (tempT < dayVec(k+1)));
                    tempYf(k) = quantile(tempY(window),quant);
                    tempTf(k) = dayVec(k+1) - 0.5*dayBlock;
                end

            case 'mean'
                for k = 1:(length(dayVec)-1)
                    window = ((tempT >= dayVec(k)) & ...
                        (tempT < dayVec(k+1)));
                    tempYf(k) = mean(tempY(window));
                    tempTf(k) = dayVec(k+1) - 0.5*dayBlock;
                end
            
            case 'median'
                for k = 1:(length(dayVec)-1)
                    window = ((tempT >= dayVec(k)) & ...
                        (tempT < dayVec(k+1)));
                    tempYf(k) = median(tempY(window));
                    tempTf(k) = dayVec(k+1) - 0.5*dayBlock;
                end
                
            case 'none'
                tempYf = tempY';
                tempTf = tempT';
        end
        
        %get rid of NaNs and times for which there is no data
        NaNmask = isfinite(tempYf);
        tempYf = tempYf(NaNmask);
        tempTf = tempTf(NaNmask);
        
        Y{j} = tempYf;
        T{j} = tempTf;
        
        Yraw{j} = tempYraw;
        Traw{j} = tempTraw;
        
        fhandle = figure;
        plot(Traw{j}, Yraw{j}, T{j}, Y{j});
        close(fhandle);
        
    end
    %% save results in new file for each site
    fprintf(1, 'done filtering site %d of %d\n', i, length(rawData.sites));
    
    %number of years at this site
    nYears = length(rawData.years{i});
    %which years at this site
    unYears(1,:) = rawData.years{i};
    
    savename = rawData.sites{i};
    save([saveDir savename '-' index], 'T', 'Y', 'Traw', 'Yraw',...
        'nYears', 'unYears');
    clear T Y Yraw Traw nYears unYears
end