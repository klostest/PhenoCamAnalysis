%%%%%%%%%%%%%%%%%%%%%% turbophenomaster %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Matlab script to control all processing of "phenotimeseries.m" for
% calculating RGB means and green chromatic coordinate for photo time
% series. This code handles multiple ROI masks for a given sites, by means
% of a "maskguide", a CSV file which contains the date ranges and
% corresponding mask files. All files must adhere to Phenocam guidelines
% with yearly and monthly subfolders and all photos must have the following
% filenaming convention:
% site_YYYY_MM_DD_hhmmss.jpg
%   where YYYY - year, MM - is month, DD is day, hh is hour, mm is minute 
%   and ss is second.
% Below is an example maskguide file:
% #
% # ROI file for umichbiological2 site
% #
% # site: umichbiological2
% # description: "deciduous trees in foreground"
% #
% start_date,start_time,end_date,end_time,maskfile,sample_image
% 2008-11-24,11:01:39,2009-08-07,08:31:37,umichbiological2_deciduous_2008-11-24_2009-08-07.tif,umichbiological2_2009_07_16_150137.jpg
% 2009-09-03,14:02:24,9999-12-31,23:59:59,umichbiological2_deciduous_after_2009-09-03.tif,umichbiological2_2010_10_11_133126.jpg
%
% To execute, assign all user-defined variables in the next section below.
% The key variables are the folder variables, "basedir" and "sites", as
% well as "maskguidefilter". For most uses, the remaining variables can be
% left as defaults.
%
% last modified on December 10, 2012
% by Michael Toomey, mtoomey@fas.harvard.edu, based on the original code by
% Koen Hufkens
%%%%%%%%%%%%%%%%%%%%%%%% USER DEFINED VARIABLES %%%%%%%%%%%%%%%%%%%%%%%%%%%
% base directory, the one that contains all site directories
basedir = 'C:\OEB\PhenoCam\webcam\';
% filter for maskguide files, which should have the endings, "*roi.csv"
maskguidefilter = '*deciduous*roi.csv';
% sites to process, in a cell array
sites = {'bartlett'};
% size of window for smoothing - default is 3
windowsize = 3;
% start and ending time (military time/24h), default is 6 and 18
sttime  = 6;
endtime = 18;
% minimum brightness threshold, in percentage, default is 15
threshold = 15;
% smoothing technique, where 1 = 90th percentile, 2 = mean, 3 = median,
% default is 1
smoothtechnique = 1;
%%%%%%%%%%%%%%%%%%%%% END OF USER DEFINED VARIABLES %%%%%%%%%%%%%%%%%%%%%%%

% change directory to "basedir"
cd(basedir)
tic
%matlabpool open
for i=1:numel(sites)
%parfor i=1:numel(sites)
    % change to site directoryl assign to outdir
    cd(sites{i})
    outdir = pwd;
    % get name of maskguide file in subdirectory, ROI
    cd ROI
    maskguide = dir(maskguidefilter);
    maskguide = char(maskguide.name);
    cd ..
    % execute turbopheno, which prepares all inputs for the given site
    % folder for phenotimeseries    
    turbopheno(outdir,maskguide,windowsize,sttime,endtime,...
        threshold,smoothtechnique)
    % move current directory back up to "basedir"
    cd(basedir)
end
%matlabpool close
toc