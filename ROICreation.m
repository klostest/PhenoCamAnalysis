function ROICreation(dir,imgfname,maskfilename,ROItype)

% Function to facilitate ROI creation on imagery. The function opens an
% image window and waits for the user to draw the ROI on the image. The ROI
% may be moved around and expanded as required by the user. Double clicking 
% finishes the process, saving the mask and opening a window clearly
% depicting the mask.
%
% SYNTAX:
%     ROICreation(dir,imgfname,maskfilename,ROItype)
%         dir = directory containing images
%         imgfname = image to draw ROI on
%         maskfilename = output file name for Matlab .MAT mask file; the
%             .mat extension is not necessary, so only use the argument
%             'maskfile' to have an output file named 'maskfile.mat'.
%         ROItype = ROI type, where 1 =  free hand, 2 = ellipse, 3 =  rectangle
%
% EXAMPLE:
%     ROICreation('C:\data\harvard\2009','harvard_2009_06_17_133139.jpg','harvardmask',2)
%         This example creates facilitates ROI creation for the image, 
%         harvard_2009_06_17_133139.jpg, in directory,
%         C:\data\harvard\2009; the ROI type is an ellipse, and the output
%         file name will be 'harvardmask.mat' (the .MAT extension not
%         necessary)
%
% Written by Michael Toomey, mtoomey@fas.harvard.edu, January 27, 2012,
% based on code by Koen Hufkens, khufkens@bu.edu.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if nargin < 4 % check input arguments
    error('Not enough input arguments. Please see help file')
elseif nargin > 4
    error('Too many input arguments. Please see help file')
elseif nargin == 4
    if ischar(dir) == 0
        error('Input directory must be string')
    end
    if ischar(imgfname) == 0
        error('Image filename must be string')
    end
    if ischar(maskfilename) == 0
        error('Image filename must be string')
    end
    if isnumeric(ROItype) == 0
        error('ROItype must be a number')
    end
end

% set current directory
cd(dir) 

% open image filename
img = imread(imgfname);

% open figure
figure
h_im = image(img);

% enable ROI creation and conversion to mask based on "ROItype"
if ROItype == 1
    % create freehand ROI using "getline"
    % Koen uses "getline" and poly2mask in lines 273-289
    [xcoord, ycoord] = getline(gcf,'closed');
    % overplot the polygon
    hold on
    plot(xcoord,ycoord,'Color',[1 1 1],'LineWidth',2)
    hold off
    % convert polygon to binary mask
    mask = poly2mask(xcoord, ycoord, size(img,1), size(img,2));
elseif ROItype == 2
    % create ellipse ROI using imellipse
    ellps = imellipse;
    position = wait(ellps);
    mask = createMask(ellps,h_im);
elseif ROItype == 3
    % create rectangular ROI using imrect
    rect = imrect;
    position = wait(rect);
    mask = createMask(rect,h_im);    
else 
    error('ROItype must equal either 1, 2, or 3');    
end

% plot mask
figure
imagesc(mask); colormap(gray)

% save mask
save(maskfilename,'mask')