function phenotimeseries(indir,outdir,maskfiles,masktype,windowsize,sttime,endtime,...
                         threshold,smoothtechnique,varargin)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Function to run a non-GUI version of the phenocamimageprocessor created
% by Koen Hufkens. In short, the code generates a simple spectral index,
% the green chromatic coordinate, for a large database (1+ years) of webcam
% imagery. The main inputs are the imagery archive and ROI, as created by
% Matlab function, ROICreation. If created otherwise, one must ensure that
% the input binary mask file has only one variable, named "mask", which
% serves as the binary ROI/mask. The function also needs the accompanying
% functions, date2jd, isleapyear, and myquantile to be in the search path.
% The easiest way to do this is make sure that those source files are in
% the same folder as this function, since the code corrects for this.
%
% SYNTAX:
%     phenotimeseries(indir,outdir,maskfiles,masktype,windowsize)
%         indir = input directory with images (JPEG only) and mask
%         outdir = output directory where ASCII results will be written
%         maskfile = Matlab *mat format binary mask/ROI
%         windowsize = window size for smoothing, in days, use 0 if no smoothing
% 
%     phenotimeseries(indir,outdir,maskfiles,masktype,windowsize,sttime,endtime)
%         indir = input directory with images (JPEG only) and mask
%         outdir = output directory where ASCII results will be written
%         maskfile = Matlab *mat format binary mask/ROI
%         windowsize = window size for smoothing, in days, use 0 if no smoothing
%         sttime, endtime = starting and ending hour for processing images, 
%                           default is 7h00 and 17h00
%
%     phenotimeseries(indir,outdir,maskfiles,masktype,windowsize,sttime,endtime,threshold,smoothtechnique)
%         indir = input directory with images (JPEG only) and mask
%         outdir = output directory where ASCII results will be written
%         maskfile = Matlab *mat format binary mask/ROI
%         windowsize = window size for smoothing, in days, use 0 if no smoothing
%         sttime, endtime = starting and ending hour for processing images, 
%                           default is 7h00 and 17h00
%         nroi = number of binary mask files, default is 1
%         threshold = darkness threshold, in percentage
%         smoothtechnique = smoothing techique to get daily values, where 
%                        1 = 90th percentile, 2 = mean, 3 = median
%                        default value is 1 (90th percentile)
%         mo = two-number vector of beginning and ending months, where 1=Jan 
%                        and 12=Dec
%
% EXAMPLE:
%     phenotimeseries('C:\data\harvard\2009','C:\data\harvard','harvardmask.mat',
%     3, 8, 16, 1, 15, 1, 0,[2 11])
%       This use of the function finds images and the binary mask in
%       'C:\data\harvard\2009', outputs to 'C:\data\harvard\', uses the
%       binary mask, 'harvardmask.mat'; the window size for smoothing is 3
%       days, the hours of valid data are 8:00 to 16:00, there is one ROI,
%       the darkness threshold is 15% and the smoothing technique is #1, or
%       90th percentile thresholding, 0 specifies no ROI sorting and [2 11]
%       specify the beginning and end months for analysis, Feb and
%       November.
%
% Original code written by Koen Hufkens, khufkens@bu.edu, Sept. 2011,
% published under a GPLv2 license and is free to redistribute.
%
% Last modified on December 10, 2012 to require TIFF format masks.
%
% Matlab function file written by Michael Toomey, mtoomey@fas.harvard.edu,
% January 27, 2012
%
% Please reference the necessary publications when using the
% the 90th percentile method:
% Sonnentag et al. 2011 (Agricultural and Forest Management)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


if nargin < 5 % check input arguments
    error('Not enough input arguments. Please see help file for phenotimeseries')
elseif nargin == 5
    if ischar(indir) == 0
        error('Input directory must be string')
    end
    if ischar(outdir) == 0
        error('Output directory must be string')
    end
    if isstruct(maskfiles) == 0
        error('Maskfile must be structure')        
    end
    if ischar(masktype) == 0
        error('Masktype must be a character string')
    end
    if isnumeric(windowsize) == 0
       error('windowsize must be a number')
    end
elseif nargin == 6
    error('Must include both sttime and endtime')
elseif nargin == 7
    if ischar(indir) == 0
        error('Input directory must be string')
    end
    if ischar(outdir) == 0
        error('Output directory must be string')
    end
    if isstruct(maskfiles) == 0
        error('Maskfile must be structure')        
    end
    if ischar(masktype) == 0
        error('Masktype must be a character string')
    end
    if isnumeric(windowsize) == 0
       error('windowsize must be a number')
    end
    if isnumeric(sttime) == 0
       error('sttime must be a number')
    end
    if isnumeric(endtime) == 0
       error('endtime must be a number')
    end
elseif nargin == 8
    error('Not enough input arguments. Please see help file for phenotimeseries')
elseif nargin == 9
    if ischar(indir) == 0
        error('Input directory must be string')
    end
    if ischar(outdir) == 0
        error('Output directory must be string')
    end    
    if isstruct(maskfiles) == 0
        error('Maskfile must be structure')        
    end
    if ischar(masktype) == 0
        error('Masktype must be a character string')
    end
    if isnumeric(windowsize) == 0
       error('windowsize must be a number')
    end
    if isnumeric(sttime) == 0
       error('sttime must be a number')
    end
    if isnumeric(endtime) == 0
       error('endtime must be a number')
    end    
    if isnumeric(threshold) == 0
       error('threshold must be a number')
    end
    if isnumeric(smoothtechnique) == 0
       error('smoothtechnique must be a number')
    end    
end

% open masks
cd(outdir)
cd ROI
masks = cell(numel(maskfiles),1);
for j=1:numel(maskfiles)
    if isempty(strfind(maskfiles(j).name,'.tif')) == 1
        error('Warning: Mask file must be in TIFF format')
    end
    masks{j} = imread(maskfiles(j).name); 
end


% set current directory and add to search path
cd(indir) 
addpath(indir)

% list all jpeg files in valid directory
% and get the number of jpegs in the directory
% all files located in monthly subdirectories, so have to fish each month's
% photos out
for i=1:12    
    tmp_files = dir(cat(2,sprintf('%02d',i),'/*.jpg'));
    if i == 1
        jpeg_files = tmp_files;
    elseif i > 1
        jpeg_files = [jpeg_files; tmp_files];
    end
end

% get rid of infrared photos ("*_IR_*")
tmp = zeros(numel(jpeg_files),1);
for i=1:numel(jpeg_files)    
   if isempty(strfind(jpeg_files(i).name,'_IR_')) == 0
    tmp(i) = 1;    
   end
end
jpeg_files(tmp == 1) = [];

% calculate number of JPEGs
nrjpegs = size(jpeg_files,1);

if isempty(jpeg_files)
    error('Contains no valid images, please select another directory')
else

    % define containing matrices for year/month/day/hour/min variables
    year = zeros(nrjpegs,1);
    month = zeros(nrjpegs,1);
    day = zeros(nrjpegs,1);
    hour = zeros(nrjpegs,1);
    minutes = zeros(nrjpegs,1);
    seconds = zeros(nrjpegs,1);
    
    % extract date/time values from filename using string manipulation
    for i=1:nrjpegs
       % split strings by the underscore       
       parts = regexp(jpeg_files(i,1).name,'_','split');
       year(i) =  str2double(char(parts(2)));
       month(i) =  str2double(char(parts(3)));
       day(i) =  str2double(char(parts(4)));
       time = char(parts(5));
       hour(i) = str2double(time(1:2));
       minutes(i) = str2double(time(3:4));
       seconds(i) = str2double(time(5:6));
    end

    % calculate the range of hours of the images (min / max)
    min_hour = min(hour);
    max_hour = max(hour);
    mean_hour = round((min_hour + max_hour) / 2);

    AM = min_hour : (mean_hour-1);
    PM = mean_hour : max_hour;
    
end

% make a subsetted list of jpegs to be processed within the valid
% processing window, defined by "sttime" and "endtime"
subset_images = char(jpeg_files.name);
cpsubimg = subset_images;
% get length of each file name
lgthfname = size(subset_images,2);
% append folder names at the front of each entry
for i=1:size(subset_images,1)    
    subset_images(i,1:3) = cat(2,sprintf('%02d',month(i)),'/');
    subset_images(i,4:lgthfname+3) = cpsubimg(i,:);
end
subset_images = subset_images(hour >= sttime & hour <= endtime,:);

% get the length of this list
size_subset_images = size(subset_images,1);

% subset year / month / day / hour / min
subset_year = year(hour >= sttime & hour <= endtime,:);
subset_month = month(hour >= sttime & hour <= endtime,:);
subset_day = day(hour >= sttime & hour <= endtime,:);
subset_hour = hour(hour >= sttime & hour <= endtime,:);
subset_min = minutes(hour >= sttime & hour <= endtime,:);
subset_sec = seconds(hour >= sttime & hour <= endtime,:);

% convert year / month / day / hour / min ... sec to matlab date
subset_year = unique(subset_year');
subset_month = subset_month';
subset_day = subset_day';
subset_hour = subset_hour';
subset_min = subset_min';
subset_sec = subset_sec';

% calculate doy from year / month / ...

subset_doy = date2jd(subset_year,subset_month,subset_day,subset_hour,subset_min,...
    subset_sec);
max_doy = max(unique(subset_doy));
min_doy = min(unique(subset_doy));

% make a matrix to contain the results (length list, indices - 5)
results = zeros(size_subset_images,6);

% fill year column
results(:,1,:) = subset_year;

% open I FOR loop to extract image values and apply GCC to each photo
for i=1:size_subset_images;
    
    % calculate DOY 
    results(i,2) = date2jd(subset_year, subset_month(i), subset_day(i),...
        subset_hour(i), subset_min(i),subset_sec(i));  
    imgdate = subset_year + results(i,2)./366;
    
    % determine which mask to use and assign to "mask"        
    for j = 1:numel(maskfiles)        
        if imgdate >= maskfiles(j).beg && imgdate <= maskfiles(j).end     
            mask = masks{j};            
        end        
    end
    
    % read in image, print out error message if file is corrupted
    try 
        img = imread(subset_images(i,:));
    catch
        error(cat(2,'Unable to open image: ',subset_images(i,:)))
    end
    % make sure they are the same dimensions
    if exist('mask','var') == 0
        disp(subset_images(i,:))
        disp(imgdate) 
    end
    if size(img,1) ~= size(mask,1) || size(img,2) ~= size(mask,2)  
        error(cat(2,'Mask and input image are not the same dimensions: ',...
            subset_images(i,:)))    
    end
    
    % split image into its components
    red = img(:,:,1);
    green = img(:,:,2);
    blue = img(:,:,3);
    
    % calculate green chromatic coordinates    
    % load individual band values to results columns 3-5
    meanred = mean(mean(red(mask == 0)));
    results(i,3) = meanred;
    meangreen = mean(mean(green(mask == 0)));
    results(i,4) = meangreen;
    meanblue = mean(mean(blue(mask == 0)));
    results(i,5) = meanblue;

    % calculate green chromatic coordinates
    gcc = meangreen ./ (meanred + meangreen + meanblue);

    % put gcc values in results
    results(i,6) =  gcc;
    
end

% create vector of days-of-year 
DOY = floor(results(:,2));
uniqDOY = unique(DOY);
smoothDOY = uniqDOY(2:windowsize:end);
l = numel(smoothDOY);

% create filter for smoothing
windowsize = floor(windowsize/2);

% make matrix to dump smoothed results in
gccsmooth = zeros(l,2);

% set threshold (dark images)
threshold = 255*(threshold/100);

% smooth time series and enforce darkness thresholds

% now, run window filtering for all days 
for n=1:l;
    
    gccsmooth(n,1) = smoothDOY(n);
    % if windowsize = 0, just compute for data on that same day and
    % enforce threshold
    if windowsize == 0;
    subset = results(DOY == smoothDOY(n) & results(:,3) > threshold & results(:,4)...
        > threshold & results(:,5) > threshold,6);
    % if windowsize <= 1, then impose window and enforce threshold 
    else
    subset = results(DOY >= smoothDOY(n)-windowsize & DOY < smoothDOY(n)+windowsize+1 & results(:,3)...
        > threshold & results(:,4) > threshold & results(:,5) > threshold,6);
    end

    % impose GCC smoothing technique
    % 90th percentile
    if smoothtechnique == 1
        gccsmooth(n,2)=myquantile(subset,0.9);
        smoothstr = '90th';
    % mean
    elseif smoothtechnique == 2
        gccsmooth(n,2)=nanmean(subset);        
        smoothstr = 'mean';
    % median
    elseif smoothtechnique == 3
        gccsmooth(n,2)=nanmedian(subset);
        smoothstr = 'median';
    end
end


% save results in output folder
cd(outdir)
cd outputs
% determine the year that was processed
year = unique(year);

% save raw results
filenameraw = char(strcat('raw-',masktype,'_',num2str(year),'.txt'));
rawdata = results(:,:,1);
dlmwrite(filenameraw,rawdata);

% save raw results with filenames, too
filenameraw = char(strcat('raw-',masktype,'_',num2str(year),'_names.txt'));
fid = fopen(filenameraw, 'w');
% create cell array, wnames, to handle numeric and filename data
wnames = cell(size(results,1),7);
% assign numeric data to columns 1-6
for i = 1:size(results,1) 
    for j=1:6; 
        wnames{i,j} = results(i,j);
    end
end
% assign file names to column 7
for i=1:size(results,1)
    wnames{i,7} = subset_images(i,:);
end
% now, output wnames to 
for z=1:size(wnames, 1)
    for s=1:size(wnames, 2)
        
        var = eval(['wnames{z,s}']);
        % If numeric -> String
        if isnumeric(var)
            var = num2str(var);            
        end                
        % OUTPUT value
        fprintf(fid, '%s', var);
        
        % OUTPUT separator
        if s ~= size(wnames, 2)
            fprintf(fid, ',');
        end
    end
    if z ~= size(wnames, 1) % prevent a empty line at EOF
        % OUTPUT newline
        fprintf(fid, '\n');
    end
end
% Closing file
fclose(fid);
disp(smoothstr)
% save smoothed results
filenamesmooth = char(strcat('smooth',smoothstr,'-',masktype,'_',num2str(year),'.txt'));
smoothdata = gccsmooth(:,:);
% add year to smoothed data
l = size(smoothdata,1);
years = zeros(l,1);
years(:,1) = year;
smoothdata = [years, smoothdata];
dlmwrite(filenamesmooth,smoothdata);

cd ..
disp(cat(2,'Done with year ',num2str(year)))
