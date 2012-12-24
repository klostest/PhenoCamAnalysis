function [] = compareModelRes()

site{1} = 'acadia';  %no 2010
site{2} = 'arbutuslake';   %good
site{3} = 'bartlett';  %no 2010
site{4} = 'boundarywaters';    %no 2011 fall
site{5} = 'dollysods'; %no 2004, 10, 11 (disregard 11 for median)
site{6} = 'groundhog'; %good
site{7} = 'harvard';   %good
site{8} = 'mammothcave';   %good
site{9} = 'queens';  %no 2009, 2010 (need to disregard 2010 fall for SV)
site{10} = 'smokylook';   %good
site{11} = 'umichbiological';   % need to disregard 2011 for SV
site{12} = 'upperbuffalo';  %good

% site{13} = 'bartlettir';

% modelName = 'greenDownRichards';
% modelName = 'greenDownSigmoid';
modelName = 'separateSigmoids';
% index = 'GCC';
% dir = './PhenoCam/';
index = 'EVI';
dir = './MODIS_NBAR/';

count = 1;
for i = 1:length(site)
    paramFile = [dir modelName '-params-' site{i} '-' index];
    data = load(paramFile, 'residual', 'T');
    for j = 1:length(data.residual)
        
        if strcmp(modelName, 'separateSigmoids')
            temp = [data.residual{j}{1} data.residual{j}{2}];
            if data.residual{j}{1} == 0
                T = data.T{j}(end:-1:length(temp));
                T = fliplr(T);
            elseif data.residual{j}{2} == 0
                T = data.T{j}(1:length(temp));
            else
                T = data.T{j};
            end
        else
            temp = data.residual{j};
            T = data.T{j};
        end
        
        
        if length(temp) > 1
        RMSE{i}{j} = sqrt( mean(( temp ).^2) );
        RMSE_spring{i}{j} = sqrt( mean( (temp( T<200 ) ).^2) );
        RMSE_fall{i}{j} = sqrt( mean( (temp( T>=200 ) ).^2) );
        all_spring_RMSE(count) = RMSE_spring{i}{j};
        all_fall_RMSE(count) = RMSE_fall{i}{j};
        all_RMSE(count) = RMSE{i}{j};
        count = count + 1;
        end
    end
end

meanSpring = mean(all_spring_RMSE);
% hist(all_spring_RMSE)
meanFall = mean(all_fall_RMSE);
% hist(all_fall_RMSE)
fprintf(1, [dir ' ' index ' ' modelName ' mean spring RMSE: \n'...
    num2str(meanSpring) ', mean fall RMSE: ' num2str(meanFall) '\n']);

% yearLongMean = mean([meanSpring meanFall])
% mean(all_RMSE)