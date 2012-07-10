function [] = MODIS_load()
%% session name
% sessionName = 'UmichBroad';
% sessionName = 'Umich';
% sessionName = 'BartlettBroad';
% sessionName = 'Bartlett';
sessionName = 'Arbutus';
% sessionName = 'ArbutusBroad';
% sessionName = 'Harvard';
% sessionName = 'HarvardBroad';
% sessionName = 'HarvardTower';
% sessionName = 'HarvardTowerBroad';

%% data source
loadDir = '../../modisClient/';
% sites = {'bartlett-Broad-reshaped'};
% sites = {'bartlett'};
% sites = {'umichbiological-Broad-reshaped'};
% sites = {'umichbiological'};
sites = {'arbutuslake'};
% sites = {'arbutuslake-Broad-reshaped'};
% sites = {'harvard'};
% sites = {'harvard-Broad-reshaped'};
% sites = {'harvardTower'};
% sites = {'harvardTower-Broad-reshaped'};

%% make a directory to save results
saveDir = ['MODIS' filesep];
% mkdir(saveDir);

%% save site info files
siteNames = sites; nSites = length(sites);

remotelySensedQuantity = 'NDVI';
saveName = [sessionName '-' remotelySensedQuantity '-siteInfo'];
save(saveName,...
    'siteNames', 'nSites', 'remotelySensedQuantity',...
    'loadDir', 'saveDir', 'sites');

remotelySensedQuantity = 'EVI';
saveName = [sessionName '-' remotelySensedQuantity '-siteInfo'];
save(saveName,...
    'siteNames', 'nSites', 'remotelySensedQuantity',...
    'loadDir', 'saveDir', 'sites');

%% preprocess data
for siteLoop = 1:length(sites)
    fname = [loadDir sites{siteLoop} '_MODIS_data'];
    load(fname);
    
%% make QA and year mask
for i = 1:length(satNames)
        for k = 1:length(site.coordNames)
            QAdata = site.data{i}{1}{k}.data;
                %more restrictive QA criteria for sites over broad areas,
                %since pixels may not be over land
                %which was this done for?  Arbutus? or maybe it should be
                %the same for all.  Doing for:  Arbutus, 
                parts = regexp(sites{siteLoop},'-','split');
                if (length(parts) == 3) && (strcmp(parts{2}, 'Broad'))
                    for m = 1:length(site.years)
                        mask{i}{k}{m} = ((QAdata == 0)' | (QAdata == 1)')& ...
                            strncmp(['A' num2str(site.years{m})],...
                            site.data{i}{1}{k}.dateList, 5);
                    end
                else %less restrictive QA for just one pixel
                    for m = 1:length(site.years)
                        mask{i}{k}{m} = ((QAdata == 0)' | (QAdata == 1)')& ...
                            strncmp(['A' num2str(site.years{m})],...
                            site.data{i}{1}{k}.dateList, 5);
                    end
                end
                clear QAdata mult dateList
        end
end

%% combine data from different satellites
for m = 1:length(site.years)
    counter = 1;
    for i = 1:length(satNames)
        for k = 1:length(site.coordNames)        

            if counter == 1
                T{m} = site.data{i}{5}{k}.data(mask{i}{k}{m})';
                EVI{m} = 1e-4*site.data{i}{4}{k}.data(mask{i}{k}{m})';
                NDVI{m} = 1e-4*site.data{i}{3}{k}.data(mask{i}{k}{m})';
            else
                T{m} = [T{m} site.data{i}{5}{k}.data(mask{i}{k}{m})'];
                EVI{m} = [EVI{m} 1e-4*site.data{i}{4}{k}.data(mask{i}{k}{m})'];
                NDVI{m} = [NDVI{m} 1e-4*site.data{i}{3}{k}.data(mask{i}{k}{m})'];
            end
            
            counter = counter + 1;
            
        end
    end
    %sort data for each year
    [T{m}, IX] = sort(T{m});
    EVI{m} = EVI{m}(IX);
    NDVI{m} = NDVI{m}(IX);
    nDays(m) = length(T{m});
end

%save
nYears = length(site.years);
unYears = [site.years{:}];

Y = EVI;
savename = [sites{siteLoop} '-EVI'];
save([saveDir savename], 'T', 'Y', 'nDays', 'nYears', 'unYears');
clear Y;

Y = NDVI;
savename = [sites{siteLoop} '-NDVI'];
save([saveDir savename], 'T', 'Y', 'nDays', 'nYears', 'unYears');
    
clear T Y nDays nYears unYears

end