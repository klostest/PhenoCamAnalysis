function out = read_klima_output(filename, windowsize,sttime,endtime,threshold,smoothtechnique,varargin)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Function to read Klima data output in comma-separated-value format and 
% return double-precision array with conventional Phenocam-style format
% GCC and DN data. The code also produces Phenocam-style yearly CSV files.
% 
% Dependencies: date2jd.m and IndexFilter.m
%
% INPUTS: Reads text file with the following fields:
% date,time,brt,brt_roi,gcc,rcc,bcc,exg,filename
% This format is standard for all Klima ROI products, as of February 4, 2013.  
%
% SYNTAX: out = read_roi_ts_csv(filename, windowsize,sttime,endtime,threshold,smoothtechnique,varargin)
%   
%   where:
%   filename = input file name
%   windowsize = size of window for smoothing
%   sttime and endtime = start and ending time (military time/24h), default is 7 and 17 
%   threshold = minimum brightness threshold, in percentage, default is 15
%   smoothtechnique = smoothing technique, where 1 = 90th percentile, 2 = mean, 3 = median 
%
% EXAMPLE: 
%   out = read_klima_output('bartlett_deciduous_0001_timeseries.csv',3,6,18,15,1);
%
%
% by Michael Toomey, mtoomey@fas.harvard.edu
% last modified on February 4, 2013
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fh=fopen(filename);
%
% read comment lines before column header
while 1
  myline = fgetl(fh);
  if strfind(myline,'#') == 1
    continue;
  else
    hdr=myline;
    break;
  end
end
%
% read data into cell array
C = textscan(fh, '%s%s%f%f%f%f%f%f%s','Delimiter',',');
%
% set up returned data structure
data.datestr=C{1};
data.timestr=C{2};
data.brt=C{3};
data.brtroi=C{4};
data.gcc=C{5};
data.rcc=C{6};
data.bcc=C{7};
data.exg=C{8};
data.filename=C{9};

% allocate memory to double-precision array
% this array will contain the year, day of year, RGB DNs and GCC for every
% single photo in the archive
out = nan(size(data.gcc,1),6);

for i = 1:size(data.gcc,1)
    % parse out the date string
    tmp = char(data.datestr(i)); 
    year = single(str2double(tmp(1:4)));
    month = single(str2double(tmp(6:7)));
    day = single(str2double(tmp(9:10)));
    % parse out the time string
    tmp = char(data.timestr(i));
    hour = single(str2double(tmp(1:2)));
    minute = single(str2double(tmp(4:5)));
    second = single(str2double(tmp(7:8)));
    % get the day of the year using date2jd.m (a dependency)
    doy = date2jd(year, month, day, hour, minute, second);
    % assign year
    out(i,1) = year;
    % assign day of year
    out(i,2) = doy;
    % assign red DN
    out(i,3) = data.rcc(i).*data.brtroi(i);
    % assign green DN 
    out(i,4) = data.gcc(i).*data.brtroi(i);
    % assign blue DN
    out(i,5) = data.bcc(i).*data.brtroi(i);
    % assign GCC
    out(i,6) = data.gcc(i);    
end

% write the output raw files
% first, parse out the input file name
parts = regexp(filename,'_','split');

% identify total number of years of data
allyears = unique(out(:,1));
% loop on all years, producing "raw" and "smoothed" Phenocam-style CSV
% files
for i = allyears(1):allyears(end)
    % subset that year's data
    sub = out(out(:,1) == i,:);
    % create output file name
    outfname = ['raw-' char(parts{1}) '_' char(parts{2}) '_' char(parts{3}) '_' num2str(i) '.txt'];
    % write "raw" output file name
    csvwrite(outfname, sub)
    % smooth the data using the IndexFilter function (a dependency)
    indexsmooth = IndexFilter(sub,windowsize,sttime,endtime,threshold,smoothtechnique);
    % create output file name, based on smoothing function used
    if smoothtechnique == 1
        outfname = ['smooth90th-' char(parts{1}) '_' char(parts{2}) '_' char(parts{3}) '_' num2str(i) '.txt'];
    elseif smoothtechnique == 2
        outfname = ['smoothmean-' char(parts{1}) '_' char(parts{2}) '_' char(parts{3}) '_' num2str(i) '.txt'];
    else
        outfname = ['smoothmedian-' char(parts{1}) '_' char(parts{2}) '_' char(parts{3}) '_' num2str(i) '.txt'];
    end
    % write "smooth" CSV file
    csvwrite(outfname,indexsmooth)
end

return;
