function [years, T, Y] = GCC_load(site, ROI, product, index)
%============================================
% Stephen Klosterman
% 1/28/2015
% steve.klosterman@gmail.com
%============================================
%Build url from site and ROI name
% site = 'bartlett';
% ROI = 'DB_0004';
% product = '3day';

options = weboptions('CertificateFilename','');
url = ['https://phenocam.sr.unh.edu/data/archive/'...
    site '/ROI/' site '_' ROI '_' product '.csv'];
data = webread(url, options);

%Column headers
%date,year,doy,image_count,midday_filename,midday_r,midday_g,midday_b,
%midday_gcc,midday_rcc
%r_mean,r_std,g_mean,g_std,b_mean,b_std
%gcc_mean,gcc_std,gcc_50,gcc_75,gcc_90
%rcc_mean,rcc_std,rcc_50,rcc_75,rcc_90,
%max_solar_elev,snow_flag,outlierflag_gcc_mean,outlierflag_gcc_50,
%outlierflag_gcc_75,outlierflag_gcc_90

%Example problem observation:
%2014-02-23,2014,54,0,None,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA,NA
C = textscan(data, ['%s%d%d%d%s%f%f%f'...
    '%f%f'...
    '%f%f%f%f%f%f'...
    '%f%f%f%f%f'...
    '%f%f%f%f%f'...
    '%f%s%s%s%s%s'],...
    'HeaderLines', 23,...
    'Delimiter', ',',...
    'TreatAsEmpty', {'none', 'NA'});

%Next step here would be outlier removal; These points are labeled.

% %Test GCC plot
% plot(C{21}) %GCC90
% % Seems to work

%% get number of years in time series
all_dates_years = C{2};
years = unique(all_dates_years);

%% extract data from cell array and discard NaNs
for i = 1:length(years)
    year_logical = all_dates_years == years(i);
    temp_T = C{3}(year_logical);  %DOY
    
    if strcmp(index, 'gcc')
        temp_Y = C{21}(year_logical);    %gcc90
    elseif strcmp(index, 'rcc')
        temp_Y = C{26}(year_logical);    %rcc90
    end

    %get rid of NaNs, transform to double precision data type
    NaNmask = isfinite(temp_Y);
    Y{i} = double(temp_Y(NaNmask));
    T{i} = double(temp_T(NaNmask));
end