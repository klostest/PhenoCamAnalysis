%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% wrapper for plotPicRois
maskfolder = 'C:\OEB\PhenoCam\webcam\bartlett\ROI';
maskguide  = 'bartlett_deciduous_0001_roi.csv';
outfolder  = 'C:\OEB\PhenoCam\webcam\bartlett\ROI';
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% initialize counter in "i"
i = 0;
% open maskguide file using low level I/O
cd(maskfolder)
fid = fopen(maskguide,'r');
tline = 'scrap';
% go through all lines until EOF
while ischar(tline)    
    cd(maskfolder)
    tline = fgetl(fid);
    % make sure input is a character and not a comment (#)
    if ischar(tline) == 1 && numel(tline) > 0 && tline(1) ~= '#' && strcmp(tline(1:10),'start_date') == 0
        % increment i by 1
        i = i+1;
        % trim white space
        tline = strtrim(tline);
        % parse line by commas
        parts = regexp(tline,',','split');
        % mask name
        maskname = parts{5};
        % photo name
        photoname = parts{6};
        % split photo name to get location
        parts = regexp(photoname,'_','split');
        cd ..
        cd(parts{2})
        cd(parts{3})
        photofolder = pwd;
        photopath = cat(2,photofolder,filesep,photoname);
        maskpath = cat(2,maskfolder,filesep,maskname);
        plotPicRois(maskpath,photopath,outfolder)
    end
end
% close file and move up one folder
fclose(fid);