function [] = getPhenoDatesMC(saveDir, loadName, modelName, dateMethod, n)
%============================================
% [] = getPhenoDates(loadName, modelName, dateMethod)
%
%% description
% This function uses a modeled timeseries of a vegetation index to estimate
% phenological transition dates.  Results are saved in the directory where
% the data and modeled time series results are.
%
%% inputs
% loadName is a string which is the filename of a .mat file in the current
% directory containing information about the site, the type of vegetation
% index, and where the data is stored.  See 'example arguments' below for
% appropriate arguments to work with the sample data.
% loadName = 'phenocam-siteInfo-Umich';

% loadName = 'phenocam-siteInfo-HarvardTree3GWW';

% loadName = 'ArbutusBroad-EVI-siteInfo';
% modelName is a string used to indicate which model the data has been fit
% to.  Possible arguments are 'separateSigmoids'.
% modelName = 'separateSigmoids';
% modelName = 'greenDownSigmoid';
%
% dateMethod is a string indicating the method used to extract phenology
% dates 'secondDeriv' and 'CCR'
% dateMethod = 'CCR';
%
% n is the number of samples from the parameter space to generate
% n = 100;
%% notes
% The functions secondDeriv.m and CCR.m produce the .mat files containing
% the formulas used to extract phenology dates, secondDeriv_formula.mat and
% CCR_formula.mat.
%
%============================================
% Stephen Klosterman
% 11/20/2011
% steve.klosterman@gmail.com
%============================================

%% Load the names and number of sites, where the data came from, and what
%% kind of data it is
load(loadName); %Ex. 'MODIS-EVI-siteInfo'
%contains 'siteNames', 'nSites', 'remotelySensedQuantity',...
%    'loadDir', 'saveDir'

%% load or define formula for calculating dates
switch modelName
    case 'separateSigmoids'
        switch dateMethod
            case 'secondDeriv'
                load('secondDeriv_formula', 'minMax');
            case 'CCR'
                load('CCR_formula.mat', 'Kprime');
        end
    case 'fullYearSigmoid'
        switch dateMethod
            case 'secondDeriv'
                load('secondDeriv_formula', 'minMax');
            case 'CCR'
                load('CCR_formula.mat', 'Kprime');
        end
    case 'greenDownSigmoid'
        switch dateMethod
            case 'secondDeriv'
                load('secondDeriv_formula', 'minMax');
            case 'CCR'
                load('CCR_formula.mat', 'Kprime');
        end
    %to be added
    %case 'separateGompertz'
    %case 'pieceWiseLinear'
    %case 'spline'
    %case 'Richards'
end
    
%% get pheno dates
for i = 1:nSites    

    site = sites{i};
    siteInfoSplit = regexp(loadName, '-', 'split');
    loadname = [modelName '-params-' site...
        '-' siteInfoSplit{2}];
    load([saveDir loadname]);
    clear sixDates temp

    for j = 1:nYears
        
    %% workflow
    % get covariance matrix for a given year
%     Jacobian = full(Jacobian);  %lsqnonlin returns the Jacobian as a sparse matrix
%     varp = resnorm*inv(Jacobian'*Jacobian)/N;
switch modelName
    case 'separateSigmoids'
        %spring and fall done separately
        for season = 1:2
        if residual{j}{season} ~= 0
            nObs{season} = size(jacobian{j}{season},1);
            nParams{season} = size(jacobian{j}{season},2);
            jacobian{j}{season} = full(jacobian{j}{season});
            covar{j}{season} = resnorm{j}(season) *...
                inv(jacobian{j}{season}' * jacobian{j}{season}) ...
                / (nObs{season}-nParams{season});
            %flag negative eigenvalues indicating mvnrnd will not work
            eigV = eig(covar{j}{season});
            if sum(eigV<=0) > 0, R{j}{season} = 0; continue;
            else
                R{j}{season} = mvnrnd(params{j}(season,:),...
                    covar{j}{season},n);
            end
        end
        end

    case 'greenDownSigmoid'
        if residual{j} ~= 0
            nObs = size(jacobian{j},1);
            nParams = size(jacobian{j},2);
            jacobian{j} = full(jacobian{j});
            covar{j} = resnorm{j} * inv(jacobian{j}' * jacobian{j}) ...
                / (nObs-nParams);
            %flag negative eigenvalues indicating mvnrnd will not work
            eigV = eig(covar{j});
            if sum(eigV<=0) > 0, R{j} = 0; continue;
            else
                R{j} = mvnrnd(params{j},covar{j},n);
            end
        end
end
%     if residual{j} ~= 0
%     tempci = nlparci(params{j},residual{j},'jacobian',jacobian{j});

%     ci = nlparci(beta,resid,'jacobian',J)
    
%     nObs = size(jacobian{j},1);
%     nParams = size(jacobian{j},2);
%     jacobian{j} = full(jacobian{j});
%     covar{j} = resnorm{j} * inv(jacobian{j}' * jacobian{j}) ...
%         / (nObs-nParams);
%     R{j} = mvnrnd(params{j},covar{j},n);
    
    %throw out any parameter sets where any of the parameters is more than
    %1.96 standard deviations away from the optimal estimate
    %now doing this based on dates
%     std = sqrt(diag(covar{j}));
%     confMult = 1.96;
%     confLow = params{j} - confMult*std';
%     confHigh = params{j} + confMult*std';
    
%     ci = nlparci(params{j},residual{j},'covar',covar{j});
    
%     for k = 1:size(R{j},1)
%         lowFlag = R{j}(k,:) < ci(:,1)';
%         highFlag = R{j}(k,:) > ci(:,2)';
%         if sum(lowFlag)>0 || sum(highFlag)>0
%             confMask(k) = false;
%         else
%             confMask(k) = true;
%         end
%     end
    
%     R{j} = R{j}(confMask,:);
%     end
%     R{j} = R{j}';
        
    
%     covar{j} = (jacobian{j}' * jacobian{j})^-1;
%     % randomly generate n parameter sets for this year
%     R{j} = mvnrnd(params{j},covar{j},n);
    % loop below to get pheno dates for each parameter set
    % save each set along with its pheno dates
    % save 95% confidence bounds on pheno dates
    % make plotting function to visualize
        
        switch modelName
            case 'separateSigmoids'
                switch dateMethod
                    case 'secondDeriv'
                        sixDates(:,j) = secondDeriv(params{j}, minMax,...
                            T{j}, cutOffDates{j});

                    case 'CCR'
                        %spring
                        temp = CCR(params{j}(1,:),...
                            modelT{j}( modelT{j} <= cutOffDates{j}(1) ),...
                            Kprime, fhandle)';
                        sixDates(1:3,j) = temp;
                        %fall
                        temp = CCR(params{j}(2,:),...
                            modelT{j}( modelT{j} >= cutOffDates{j}(2) ),...
                            Kprime, fhandle)';
                        sixDates(4:6,j) = temp;
                        
                        %% generate phenodates for each parameter sample
                        %first spring, then fall
                        sixDatesMC{j} = zeros(6,size(R{j},1));
                        if (length(residual{j}{1})>1) && (length(R{j}{1})>1)
                        for k = 1:size(R{j}{1},1)
                        temp = CCR(R{j}{1}(k,:),...
                            modelT{j}( modelT{j} <= cutOffDates{j}(1) ),...
                            Kprime, fhandle)';
                        sixDatesMC{j}(1:3,k) = temp;
                        end
                        end
                        %fall
                        if (length(residual{j}{2})>1) && (length(R{j}{2})>1)
                        for k = 1:size(R{j}{2},1)
                        temp = CCR(R{j}{2}(k,:),...
                            modelT{j}( modelT{j} >= cutOffDates{j}(2) ),...
                            Kprime, fhandle)';
                        sixDatesMC{j}(4:6,k) = temp;
                        end
                        end
                end
            case 'fullYearSigmoid'
                switch dateMethod
                    case 'secondDeriv'
                        sixDates(:,j) = secondDeriv(params{j}, minMax,...
                            T{j}, cutOffDates{j});

                    case 'CCR'
                        %spring
                        springParams = [params{j}(3) params{j}(4)...
                            params{j}(2) params{j}(1)];%[m1 m2 vamp vmin]
                        temp = CCR(springParams,...
                            modelT{j},...
                            Kprime)';
                        sixDates(1:3,j) = temp;
                        %fall
                        fallParams = [params{j}(5) params{j}(6)...
                            params{j}(2) params{j}(1)];%[m3 m4 vamp vmin]
                        temp = CCR(fallParams,...
                            modelT{j},...
                            Kprime)';
                        sixDates(4:6,j) = temp;
                end
            case 'greenDownSigmoid'
                switch dateMethod
                    case 'secondDeriv'
                        tempParams = [params{j}(3)/params{j}(4)...
                            -1/params{j}(4);
                            params{j}(5)/params{j}(6)...
                            -1/params{j}(6)];
                            
                        sixDates(:,j) = secondDeriv(tempParams, minMax,...
                            T{j}, cutOffDates{j});

                    case 'CCR'
                        sixDates(:,j) = CCRgd(params{j}, modelT{j},...
                            Kprime, fhandle);
                        
                    %% generate phenodates for each parameter sample
                        if residual{j} ~= 0
                            
                        sixDatesMC{j} = zeros(6,size(R{j},1));
                        for k = 1:size(R{j},1)
                        sixDatesMC{j}(:,k) = CCRgd(R{j}(k,:), modelT{j},...
                            Kprime, fhandle)';
                        %remove dates where parameters 4 or 6 are non positive
                        if (sixDatesMC{j}(4,k) <= 0) ||...
                                (sixDatesMC{j}(6,k) <= 0)
                            sixDatesMC{j}(:,k) = zeros(6,1);
                        end
                        end
                        
                        end

%                         %spring
%                         springParams = [params{j}(3)/params{j}(4)...
%                             -1/params{j}(4)...
%                             params{j}(2) params{j}(1)];%[m1 m2 vamp vmin]
%                         temp = CCR(springParams,...
%                             modelT{j},...
%                             Kprime)';
%                         sixDates(1:3,j) = temp;
%                         %fall
%                         fallParams = [params{j}(5)/params{j}(6)...
%                             -1/params{j}(6)...
%                             params{j}(2) params{j}(1)];%[m3 m4 vamp vmin]
%                         temp = CCR(fallParams,...
%                             modelT{j},...
%                             Kprime)';
%                         sixDates(4:6,j) = temp;

%                         %% generate phenodates for each parameter sample
%                         if residual{j} ~= 0
%                             
%                         sixDatesMC{j} = zeros(6,size(R{j},1));
%                         for k = 1:size(R{j},1)
%                             springParams = [R{j}(k,3)/R{j}(k,4)...
%                             -1/R{j}(k,4)...
%                             R{j}(k,2) R{j}(k,1)];%[m1 m2 vamp vmin]
%                         temp = CCR(springParams,...
%                             modelT{j},...
%                             Kprime)';
%                         sixDatesMC{j}(1:3,k) = temp;
%                         %fall
%                         fallParams = [R{j}(k,5)/R{j}(k,6)...
%                             -1/R{j}(k,6)...
%                             R{j}(k,2) R{j}(k,1)];%[m3 m4 vamp vmin]
%                         temp = CCR(fallParams,...
%                             modelT{j},...
%                             Kprime)';
%                         sixDatesMC{j}(4:6,k) = temp;
%                         end
%                         
%                         end
                end
        end
%         sixDatesMC_low95(j,:) = quantile(sixDatesMC{j}', 0.025);
%         sixDatesMC_high95(j,:) = quantile(sixDatesMC{j}', 0.975);
        fprintf('Done with phenodates for %s %d\n', site, unYears(j));
    end
    
    savename = [site '-' siteInfoSplit{2} '-phenoDatesMC-' modelName ...
        '-' dateMethod];
    %save results in new directory
%     saveDir = './phenoDatesMC_NBAR_filterOnDate_n100/';
%     saveDir = './phenoDatesMC_PhenoCam_filterOnDate_n100/';
    save([saveDir savename]);
end