function [] = MODIS_load2(fname, loadDir, savename, saveDir)

load([loadDir fname]);
mult = 1e-4;
    
%% make QA and year mask
for i = 1:length(satNames)
                %use pixel reliability
                QAdata = data{i}{1}.data;
                
                %make list of years for this satellite for this site
                beginYear = num2str(dateRange(1));
                beginYear = str2num(beginYear(1:4));
                endYear = num2str(dateRange(2));
                endYear = str2num(endYear(1:4));
                yearList = beginYear:endYear;
                
                %combined pixel reliability and individual year mask for
                %each satellite for each year
                
                if strfind(savename, '_km')
                
                %be more restrictive with QC for kilometer scale data since
                %there's more of it
                for m = 1:length(yearList)
                    mask{i}{m} = (QAdata == 0)' & ...
                        strncmp(['A' num2str(yearList(m))],...
                        data{i}{1}.dateList, 5);
                end
                
                else
                
                for m = 1:length(yearList)
                    mask{i}{m} = ( (QAdata == 0)' )&...| (QAdata == 1)' ) & ...
                        strncmp(['A' num2str(yearList(m))],...
                        data{i}{1}.dateList, 5);
                end
                
                end
end

%% organize and save data
for m = 1:length(yearList)
    counter = 1;
    for i = 1:length(satNames)     

            if counter == 1
                T{m} = data{i}{5}.data(mask{i}{m});
                EVI{m} = data{i}{4}.data(mask{i}{m});
                NDVI{m} = data{i}{3}.data(mask{i}{m});
            else
                T{m} = [T{m}; data{i}{5}.data(mask{i}{m})];
                EVI{m} = [EVI{m}; data{i}{4}.data(mask{i}{m})];
                NDVI{m} = [NDVI{m}; data{i}{3}.data(mask{i}{m})];
            end
            
            counter = counter + 1;
    end
    %sort data for each year
    [T{m}, IX] = sort(T{m});
    EVI{m} = EVI{m}(IX);
    NDVI{m} = NDVI{m}(IX);
    nDays(m) = length(T{m});
    
    %transpose and multiply indices by multiplier
    T{m} = T{m}';
    EVI{m} = EVI{m}' * mult;
    NDVI{m} = NDVI{m}' * mult;
end

%save
nYears = length(yearList);
unYears = yearList;
siteNames{1} = savename;
sites{1} = savename;
nSites = 1;

%% EVI
Y = EVI;
save([saveDir savename '-EVI'], 'T', 'Y', 'nDays', 'nYears', 'unYears');
clear Y;

remotelySensedQuantity = 'EVI';
save([savename '-' remotelySensedQuantity '-siteInfo'],...
    'siteNames', 'nSites', 'remotelySensedQuantity',...
    'loadDir', 'saveDir', 'sites');

%% NDVI
Y = NDVI;
save([saveDir savename '-NDVI'], 'T', 'Y', 'nDays', 'nYears', 'unYears');

remotelySensedQuantity = 'NDVI';
save([savename '-' remotelySensedQuantity '-siteInfo'],...
    'siteNames', 'nSites', 'remotelySensedQuantity',...
    'loadDir', 'saveDir', 'sites');
    
clear T Y nDays nYears unYears