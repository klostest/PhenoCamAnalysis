%% change matlab *mat mask to *tiff
files = dir('*mat');
for i=1:numel(files)
   load(files(i).name)
   out = zeros(size(mask,1),size(mask,2));
   out(mask == 1) = 0; 
   out(mask == 0) = 255;
   imwrite(out,strrep(char(files(i).name),'mat','tif'),'tif');
end

%% change TIFF mask to matlab
files = dir('*.tif');
for i=1:numel(files)
   in = imread(files(i).name); 
   mask = zeros(size(in,1),size(in,2)); 
   mask(in == 255) = 0;
   mask(in == 0) = 1;
   save(strrep(char(files(i).name),'.tif',''),'mask')
end