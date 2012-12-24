function [] = MODIS_load_NBAR(fname, loadDir, savename, saveDir, filter)

load([loadDir fname]);

%% save site info files
siteNames{1} = savename;
sites{1} = savename;
nSites = length(sites);

remotelySensedQuantity = 'NDVI';
save([savename '-' remotelySensedQuantity '-NBAR-siteInfo'],...
    'siteNames', 'nSites', 'remotelySensedQuantity',...
    'loadDir', 'saveDir', 'sites', 'filter');

remotelySensedQuantity = 'EVI';
save([savename '-' remotelySensedQuantity '-NBAR-siteInfo'],...
    'siteNames', 'nSites', 'remotelySensedQuantity',...
    'loadDir', 'saveDir', 'sites', 'filter');

remotelySensedQuantity = 'GCC';
save([savename '-' remotelySensedQuantity '-NBAR-siteInfo'],...
    'siteNames', 'nSites', 'remotelySensedQuantity',...
    'loadDir', 'saveDir', 'sites', 'filter');

remotelySensedQuantity = 'ExG';
save([savename '-' remotelySensedQuantity '-NBAR-siteInfo'],...
    'siteNames', 'nSites', 'remotelySensedQuantity',...
    'loadDir', 'saveDir', 'sites', 'filter');


%% start here
%% preprocessing tasks
% product = {'MCD12Q1'
%     'MCD12Q2'
%     'MCD43A2'
%     'MCD43A4'};
% 
% band{1} = {'Land_Cover_Type_1'};
% band{2} = {'Onset_Greenness_Minimum.Num_Modes_01'
%     'Onset_Greenness_Decrease.Num_Modes_01'
%     'Onset_Greenness_Maximum.Num_Modes_01'
%     'Onset_Greenness_Increase.Num_Modes_01'};
% band{3} = {'BRDF_Albedo_Quality'
%     'Snow_BRDF_Albedo'};
% band{4} = {'Nadir_Reflectance_Band1'	%r
%     'Nadir_Reflectance_Band2'		%nir
%     'Nadir_Reflectance_Band3'		%b
%     'Nadir_Reflectance_Band4'};		%g

%% preprocess data
for siteLoop = 1:length(sites)
    fname = [loadDir filesep sites{siteLoop} 'MODIS_NBAR_data'];
    load(fname);
%     'data', 'product', 'band',...
%     'coords', 'dateRange',...
%     'kmAboveBelow', 'kmLeftRight');

%% MCD43A2 Snow_BRDF_Albedo mask
% # reclass 255 values and 0 values (bad BRDF and snow data) to NA leave the rest
% actually Koen, it looks like 0 is the one to keep.  from the MODIS
% products website
% "Byte Word.	 Snow_BRDF_Albedo*
% 1	 Snow albedo retrieved
% 0	 Snow-free albedo retrieved
% 255	 Fill Value"
% QC[QC==255] <- NA
% QC[QC==1] <- NA
% QC[QC==0] <- 1
snowMask = data{3}{2}.data ~= 0;

%% MCD12Q1_Land_Cover_Type_1
%# set classes water and urban areas, ice and water to NA the rest to 1 
% # convert to matrix formatting, repeat for the number of lines in the
% # nbar data file, and use matrix() to fill a mask with the rep() data
% Landcover[Landcover==15] <- NA
% Landcover[Landcover==13] <- NA
% Landcover[Landcover==0] <- NA
% Landcover[Landcover > 0] <- 1
%looks like Koen was using first land cover classification (IGBP)
landCoverMask = (data{1}{1}.data(1,:) == 15) |...
    (data{1}{1}.data(1,:) == 13) |...
    (data{1}{1}.data(1,:) == 0);
nPixels = size(landCoverMask,2);
recordLength = size(snowMask,1);
landCoverMask = repmat(landCoverMask, recordLength, 1);

%print land cover of 3x3 to screen
IGBP = reshape(data{1}{1}.data(1,:), 5, 5);
disp(IGBP(2:4, 2:4));

%% Perform masking, apply multiplier, make indices
%mask each band
mask = snowMask | landCoverMask;
mult = 1e-4;

red = data{4}{1}.data;
nir = data{4}{2}.data;
blue = data{4}{3}.data;
green = data{4}{4}.data;

red(mask) = NaN;
nir(mask) = NaN;
blue(mask) = NaN;
green(mask) = NaN;

red = red*mult;
nir = nir*mult;
blue = blue*mult;
green = green*mult;

% EVI <-  2.5 * (NIR.nbar - Red.nbar)/(NIR.nbar + (6*Red.nbar) - (7.5*Blue.nbar) + 1)
% NDVI <- (NIR.nbar - Red.nbar) / (NIR.nbar + Red.nbar)
% # normalize over three channels (
% total <- Green.nbar + Blue.nbar + Red.nbar
% Green.pc <- Green.nbar / total
% Blue.pc <- Blue.nbar / total
% Red.pc <- Red.nbar / total
% # calculate excess green / formerly known as VEG1
% VEG1 <- 2 * Green.nbar - Red.nbar - Blue.nbar
% # calculate mean across pixels in ROI
% EVI <- rowMeans(EVI,na.rm=TRUE)
% NDVI <- rowMeans(NDVI,na.rm=TRUE)
% VEG1 <- rowMeans(VEG1,na.rm=TRUE)*10
% GCC <- rowMeans(Green.pc,na.rm=TRUE)

EVI_raw = 2.5 * (nir - red) ./ (nir + (6*red) - (7.5*blue) + 1);
NDVI_raw = (nir - red) ./ (nir + red);
GCC_raw = green ./ (red + green + blue);
ExG_raw = 2 * green - red - blue;

%% ???
% # exact evi/ndvi values are rare so these are overlooked faulty values
% EVI[EVI==0] <- NA
% NDVI[NDVI==0] <- NA
% VEG1[VEG1==0] <- NA

% # removing values bigger than 1 (not possible, faulty)
% EVI[EVI>1] <- NA
% NDVI[NDVI>1] <- NA
% VEG1[VEG1>1] <- NA

% # removing values smaller than 0 (this is water or no vegetation)
% EVI[EVI<0] <- NA
% NDVI[NDVI<0] <- NA
% VEG1[VEG1<0] <- NA

%% median of 3x3 window
%subset 3x3 window (see plotModisDataSpatial.m, contact Tristan Quaife to
%confirm correct usage)
%seems like reshaping into square matrix is good enough.  don't need to
%rotate because center square of pixels wouldn't be different, just in a
%different order.

for i = 1:size(EVI_raw, 1)
    EVI_reshaped(i,:,:) = reshape(EVI_raw(i,:), 5, 5);
    NDVI_reshaped(i,:,:) = reshape(NDVI_raw(i,:), 5, 5);
    GCC_reshaped(i,:,:) = reshape(GCC_raw(i,:), 5, 5);
    ExG_reshaped(i,:,:) = reshape(ExG_raw(i,:), 5, 5);
    
    %median
    EVI_median(i) = nanmedian(reshape(EVI_reshaped(i,2:4,2:4),1,9));
    NDVI_median(i) = nanmedian(reshape(NDVI_reshaped(i,2:4,2:4),1,9));
    GCC_median(i) = nanmedian(reshape(GCC_reshaped(i,2:4,2:4),1,9));
    ExG_median(i) = nanmedian(reshape(ExG_reshaped(i,2:4,2:4),1,9));
    
    %mean
%     EVI_median(i) = nanmean(reshape(EVI_reshaped(i,2:4,2:4),1,9));
%     NDVI_median(i) = nanmean(reshape(NDVI_reshaped(i,2:4,2:4),1,9));
%     GCC_median(i) = nanmean(reshape(GCC_reshaped(i,2:4,2:4),1,9));
%     ExG_median(i) = nanmean(reshape(ExG_reshaped(i,2:4,2:4),1,9));
    
    %center pixel
%     EVI_median(i) = nanmedian(EVI_reshaped(i,3,3));
%     NDVI_median(i) = nanmedian(NDVI_reshaped(i,3,3));
%     GCC_median(i) = nanmedian(GCC_reshaped(i,3,3));
%     ExG_median(i) = nanmedian(ExG_reshaped(i,3,3));
end

%% arrange by time

%use dateList from red band
for i = 1:length(data{4}{1}.dateList)
    T_year(i,:) = data{4}{1}.dateList{i}(2:5);
    T_day(i,:) = data{4}{1}.dateList{i}(6:8);
end
T_year = str2num(T_year);
T_day = str2num(T_day);
unYears = unique(T_year);
unYears = unYears';
nYears = length(unYears);

for i = 1:nYears
    yearMask = T_year == unYears(i);
    tempT = T_day(yearMask);
    
    tempEVI = EVI_median(yearMask);
    EVI_nanMask = ~isnan(tempEVI) & tempEVI>0 & tempEVI<1;
    EVI_T{i} = tempT(EVI_nanMask)';
    EVI{i} = tempEVI(EVI_nanMask);
    nDaysEVI(i) = length(EVI_T{i});
    switch filter.type
        case 'median'
        for j = 1:length(EVI{i})
            if j < round(filter.window/2)
                EVI_filt{i}(j) = median(EVI{i}(1:filter.window));
            elseif (j >= round(filter.window/2)) &&...
                    (j <= (length(EVI{i})-floor(filter.window/2)));
                EVI_filt{i}(j) = median(EVI{i}...
                    (j-floor(filter.window/2):j+floor(filter.window/2)));
            elseif j > (length(EVI{i})-floor(filter.window/2))
                EVI_filt{i}(j) = median(EVI{i}...
                    (length(EVI{i})-filter.window:length(EVI{i})));
            end
        end
        EVI{i} = EVI_filt{i};
        
        case 'SV'
            fhandle = figure;
            plot(EVI{i}, 'x'); hold on
            EVI{i} = ...
                (smooth(EVI{i}, filter.window, 'sgolay', filter.SVdeg))';
            plot(EVI{i})
            close(fhandle);
    end
    
    tempNDVI = NDVI_median(yearMask);
    NDVI_nanMask = ~isnan(tempNDVI) & tempNDVI>0 & tempNDVI<1;
    NDVI_T{i} = tempT(NDVI_nanMask)';
    NDVI{i} = tempNDVI(NDVI_nanMask);
    nDaysNDVI(i) = length(NDVI_T{i});
    switch filter.type
        case 'median'
        for j = 1:length(NDVI{i})
            if j < round(filter.window/2)
                NDVI_filt{i}(j) = median(NDVI{i}(1:filter.window));
            elseif (j >= round(filter.window/2)) &&...
                    (j <= (length(NDVI{i})-floor(filter.window/2)));
                NDVI_filt{i}(j) = median(NDVI{i}...
                    (j-floor(filter.window/2):j+floor(filter.window/2)));
            elseif j > (length(NDVI{i})-floor(filter.window/2))
                NDVI_filt{i}(j) = median(NDVI{i}...
                    (length(NDVI{i})-filter.window:length(NDVI{i})));
            end
        end
        NDVI{i} = NDVI_filt{i};
        
        case 'SV'
            NDVI{i} = ...
                (smooth(NDVI{i}, filter.window, 'sgolay', filter.SVdeg))';
    end
    
    tempGCC = GCC_median(yearMask);
    GCC_nanMask = ~isnan(tempGCC) & tempGCC>0 & tempGCC<1;
    GCC_T{i} = tempT(GCC_nanMask)';
    GCC{i} = tempGCC(GCC_nanMask);
    nDaysGCC(i) = length(GCC_T{i});
    switch filter.type
        case 'median'
        for j = 1:length(GCC{i})
            if j < round(filter.window/2)
                GCC_filt{i}(j) = median(GCC{i}(1:filter.window));
            elseif (j >= round(filter.window/2)) &&...
                    (j <= (length(GCC{i})-floor(filter.window/2)));
                GCC_filt{i}(j) = median(GCC{i}...
                    (j-floor(filter.window/2):j+floor(filter.window/2)));
            elseif j > (length(GCC{i})-floor(filter.window/2))
                GCC_filt{i}(j) = median(GCC{i}...
                    (length(GCC{i})-filter.window:length(GCC{i})));
            end
        end
        GCC{i} = GCC_filt{i};
        
        case 'SV'
            GCC{i} = ...
                (smooth(GCC{i}, filter.window, 'sgolay', filter.SVdeg))';
    end
    
    
    tempExG = ExG_median(yearMask);
    ExG_nanMask = ~isnan(tempExG) & tempExG>0 & tempExG<1;
    ExG_T{i} = tempT(ExG_nanMask)';
    ExG{i} = tempExG(ExG_nanMask);
    nDaysExG(i) = length(ExG_T{i});
    switch filter.type
        case 'median'
        for j = 1:length(ExG{i})
            if j < round(filter.window/2)
                ExG_filt{i}(j) = median(ExG{i}(1:filter.window));
            elseif (j >= round(filter.window/2)) &&...
                    (j <= (length(ExG{i})-floor(filter.window/2)));
                ExG_filt{i}(j) = median(ExG{i}...
                    (j-floor(filter.window/2):j+floor(filter.window/2)));
            elseif j > (length(ExG{i})-floor(filter.window/2))
                ExG_filt{i}(j) = median(ExG{i}...
                    (length(ExG{i})-filter.window:length(ExG{i})));
            end
        end
        ExG{i} = ExG_filt{i};
        
        case 'SV'
            ExG{i} = ...
                (smooth(ExG{i}, filter.window, 'sgolay', filter.SVdeg))';
    end
    
end
    

Y = EVI; T = EVI_T; nDays = nDaysEVI;
savename = [sites{siteLoop} '-EVI'];
save([saveDir savename], 'T', 'Y', 'nDays', 'nYears', 'unYears');
clear Y;

Y = NDVI; T = NDVI_T; nDays = nDaysNDVI;
savename = [sites{siteLoop} '-NDVI'];
save([saveDir savename], 'T', 'Y', 'nDays', 'nYears', 'unYears');

Y = GCC; T = GCC_T; nDays = nDaysGCC;
savename = [sites{siteLoop} '-GCC'];
save([saveDir savename], 'T', 'Y', 'nDays', 'nYears', 'unYears');
clear Y;

Y = ExG; T = ExG_T; nDays = nDaysExG;
savename = [sites{siteLoop} '-ExG'];
save([saveDir savename], 'T', 'Y', 'nDays', 'nYears', 'unYears');
    
clear T Y nDays nYears unYears

end