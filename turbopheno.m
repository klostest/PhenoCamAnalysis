function turbopheno(outdir,maskguide,windowsize,sttime,endtime,threshold,smoothtechnique)
%%%%%%%%%%%%%%%  turbopheno.m  %%%%%%%%%%%%%%%%%%%%%%%%%%%
% matlab code to drive phenotimeseries.m. this script 
% this code is intended to be run by turbophenomaster.m, which enables the
% batch processing of all site directories. however, this code can
% also easily be run on its own; if so, be sure to uncomment
% the user-defined variables below
%
% 
% by Michael Toomey, mtoomey@fas.harvard.edu
% last modified April 23, 2012
%%%%%%%%%%%%%%%%%%%%%%%% USER DEFINED VARIABLES %%%%%%%%%%%%%%%%%%%%%%%%%%% 
% site directory, this is where outputs will be recorded, too
% outdir = 'C:\OEB\PhenoCam\webcam\umichbiological2';
% mask file name
% maskguide = 'umichbiological2_deciduous_roi.csv';
% size of window for smoothing
% windowsize = 3;
% % start and ending time (military time/24h), default is 7 and 17 
% sttime  = 7;
% endtime = 19;
% % minimum brightness threshold, in percentage, default is 15
% threshold = 15;
% % smoothing technique, where 1 = 90th percentile, 2 = mean, 3 = median
% smoothtechnique = 1;
%%%%%%%%%%%%%%%%%%%% END OF USER DEFINED VARIABLES %%%%%%%%%%%%%%%%%%%%%%%%

% change directory to "outdir"
cd(outdir)

% display the site being worked on 
% first, detect operating system's folder separator
sep = filesep;
exprsn = regexp(outdir,sep,'split');
% display the site in the command window
disp(cat(2,'Working on site: ',exprsn{end}))

% populate list of all folders beginning with '20'
allfiles = dir('20*');

% get names of all year folders, there should be no other type of folders
% present
for i=1:numel(allfiles)
   if allfiles(i).isdir == 1
       folders{i} = allfiles(i).name;
   end
end

% initialize structure, maskfiles
maskfiles = struct();
% initialize counter in "i"
i = 0;
% change directory to ROI folder
cd ROI
% open maskguide file using low level I/O
fid = fopen(maskguide,'r');
tline = 'scrap';
% go through all lines until EOF
while ischar(tline)    
    tline = fgetl(fid);
    % make sure input is a character and not a comment (#)
    if ischar(tline) == 1 && tline(1) ~= '#' && strcmp(tline(1:10),'start_date') == 0
        % increment i by 1
        i = i+1;
        % parse line by commas
        parts = regexp(tline,',','split');
        % assign decimal dates beg = beg and end = end
        % parse out year, month, day 
        tmp  = char(parts{1});
        year = str2num(tmp(1:4)); month= str2num(tmp(6:7)); day  = str2num(tmp(9:10));
        % parse out hour, minute, second
        tmp  = char(parts{2}); 
        hour = str2num(tmp(1:2)); minute=str2num(tmp(4:5)); second=str2num(tmp(7:8));
        % assign to maskfiles.beg
        maskfiles(i).beg = year + date2jd(year,month,day,hour,minute,second)./366;
        % parse out year, month, day 
        tmp  = char(parts{3});
        year = str2num(tmp(1:4)); month= str2num(tmp(6:7)); day  = str2num(tmp(9:10));
        % parse out hour, minute, second
        tmp  = char(parts{4}); 
        hour = str2num(tmp(1:2)); minute=str2num(tmp(4:5)); second=str2num(tmp(7:8));
        % assign to maskfiles.end
        maskfiles(i).end = year + date2jd(year,month,day,hour,minute,second)./366;
        % assign mask name
        maskfiles(i).name= char(parts(5));
    end
end
% close file and move up one folder
fclose(fid);
cd ..
% assign mask type to masktype
tmp = regexp(maskguide,'_','split');
masktype = cat(2,char(tmp{1}),'_',char(tmp{2}));

% for all folders in "folders", open each and execute phenotimeseries, only
% the input directory will change (folders{i})
% open Matlab pool to enable parallel processing using the parallel
% computing toolbox

for i=1:numel(folders)
    indir = cat(2,outdir,sep,folders{i});
    phenotimeseries(indir,outdir,maskfiles,masktype,windowsize,sttime,endtime,...
        threshold,smoothtechnique)
end



