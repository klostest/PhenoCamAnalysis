function [] = plotPicRois(maskName, picName,outfolder)
% maskName is the file name of the .mat file produced by ROICreation.m
% picName is the file name of the .jpg

%load mask, create boundary of ROI
data = load(maskName);
boundary = bwboundaries(data.mask);

%plot picture
pic = imread(picName);
figure;
h = imagesc(pic);
hold on;

%plot ROI boundary
linewidth = 4;
lineStyle = '-';
color = [1 0 0];
for i = 1:numel(boundary)
    plot(boundary{i}(:,2),...
        boundary{i}(:,1),...
        lineStyle,...
        'LineWidth',linewidth,...
        'Color', color);
end
cd(outfolder)
parts = regexp(maskName,filesep,'split');
saveas(h,strrep(parts{end},'mat','jpg'),'jpg')