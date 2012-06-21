function RGBGCC = testphotocalculation(imgfiles,maskfile)

% matlab function to perform simple calculation of ROI means for RGB
% brightness as well as calculate GCC for testing and evalution with other
% programs
% 
% SYNTAX: RGBGCC  = testphotocalculation(imgfiles,maskfile);
%                   where "imgfiles" is a structure containing filenames and
%                   metadata for photos to be evaluated. the structure can
%                   be created using the "dir" command, as opposed to "ls", 
%                   which produces a character array. 
%                   "maskfile" is the filename for a TIFF-format mask file
%  
% OUTPUTS: RGBGC is a n x 4 array containing the R, G, B means and GCC mean 
%          for the input mask    
%
% EXAMPLE: imgfiles = dir('*.jpg');
%          RGBGCC  = testphotocalculation(imgfiles,'harvard_deciduous_0001.tif');
%
% by Michael Toomey, mtoomey@fas.harvard.edu
% last modified on June 21, 2012
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% read in TIFF mask file
mask = imread(maskfile,'tif');

% create output file, RGBGCC, to receive results
RGBGCC = zeros(numel(imgfiles),4); 

for i=1:size(imgfiles);
        
    % read in image, print out error message if file is corrupted
    try 
        img = imread(imgfiles(i).name);
    catch
        error(cat(2,'Unable to open image: ',imgfiles(i).name))
    end
    % make sure they are the same dimensions
    if size(img,1) ~= size(mask,1) || size(img,2) ~= size(mask,2)  
        error(cat(2,'Mask and input image are not the same dimensions: ',...
            imgfiles(i).name))
    end
    
    % split image into its components
    red = img(:,:,1);
    green = img(:,:,2);
    blue = img(:,:,3);
    
    % calculate green chromatic coordinates    
    % load individual band values to RGBGCC columns 1-3
    meanred = mean(mean(red(mask == 0)));
    RGBGCC(i,1) = meanred;
    meangreen = mean(mean(green(mask == 0)));
    RGBGCC(i,2) = meangreen;
    meanblue = mean(mean(blue(mask == 0)));
    RGBGCC(i,3) = meanblue;

    % calculate green chromatic coordinates
    gcc = meangreen ./ (meanred + meangreen + meanblue);

    % put gcc values in RGBGCC
    RGBGCC(i,4) =  gcc;
    
end