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
%***
%Use 'site', 'ROI', and 'product' inputs to build a URL to the data.
%Example URL:
%https://phenocam.sr.unh.edu/data/archive/uwmfieldsta/ROI/uwmfieldsta_DB_0001_3day.csv

url = NaN; %Change this to the URL
data = webread(url, options);

%***
%Use the Matlab function 'textscan' to extract the data into Matlab
%variables from the text string 'data'.  See documentation on web (i.e.
%google "matlab textscan".
%Suggestion:  visit the URL and observe the data file
%Pay attention to:  number of header lines, which values are treated as
%empty (hint, it's more than just 'NA'), and the format string.
C = textscan(...

%***
%Now that the data is in Matlab variables, we can work with it.  Create a
%plot with:  time on the x axis, and 'gcc_90' on the y axis.  This is a
%widely used metric of greenness phenology from PhenoCam.  What does it
%look like?  Does it make sense?
plot(...


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