function [] = ...
    getPhenoDatesMC(years, model_name, params, modelT, modelY,...
    T, Y,...
    date_method, percentiles,...
    cut_off_dates,...
    fhandle, site, ROI, index,...
    jacobian, resnorm)
%============================================
% [] = getPhenoDates(loadName, modelName, dateMethod)
%
%% description
% This function uses a modeled timeseries of a vegetation index to estimate
% phenological transition dates.  Results are saved in the directory where
% the data and modeled time series results are.
%
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

    
%% get pheno dates
for j = 1:length(years)
    
%% get covariance matrix for a given year, draw n samples of parameter sets
%     Jacobian = full(Jacobian);  %lsqnonlin returns the Jacobian as a sparse matrix
%     varp = resnorm*inv(Jacobian'*Jacobian)/N;
switch model_name
    case 'greenDownSigmoid'
        if ~isnan(resnorm{j})  %If optimization worked
            nObs = size(jacobian{j},1);
            nParams = size(jacobian{j},2);
            jacobian{j} = full(jacobian{j});
            temp1 = jacobian{j}' * jacobian{j};
%             %As seen here:  http://www.gnu.org/software/gsl/manual/html_node/Computing-the-covariance-matrix-of-best-fit-parameters.html
%             %eliminate rows and columns with a small diagonal element from
%             %this matrix and set the corrsponding rows and columns of the
%             %covariance matrix to zero
%             %throw out rows and columns with small diag entries
%             smallCovarTol = 0.1;   %experiment with this.  on website
%             %it was defined in terms of other parameter sensitivities
%             %For greendown sigmoid, tried 1, but parameter variances wound
%             %up being extremely small.
%             smallDiag = diag(temp1)<smallCovarTol;
% %             nSmallDiag = sum(smallDiag);
%             for k = nParams:-1:1
%                 if smallDiag(k) == 1
%                     temp1(k,:) = [];
%                     temp1(:,k) = [];
%                 end
%             end
            
            %compute (reduced) covariance matrix
            temp2 = inv(temp1);
            tempCovar{j} = resnorm{j} * temp2 ... %\eye(size(jacobian{j},2)) ...
                / (nObs-nParams);
%             
%             %add zeros back in for insensitive parameters
%             covarMask = ones(nParams);
%             for k = 1:nParams
%                 if smallDiag(k) == 1
%                     covarMask(k,:) = zeros(1,nParams);
%                     covarMask(:,k) = zeros(nParams,1);
%                 end
%             end
%             covarMask = logical(covarMask);
%             covar{j} = zeros(nParams);
%             covar{j}(covarMask) = tempCovar{j};

            covar{j} = tempCovar{j};
            
            %are any elements of the covariance matrix NaN or Inf?
            if sum(sum(isfinite(covar{j}))) == size(covar{j},1)*...
                    size(covar{j},2)

%             flag negative eigenvalues indicating mvnrnd will not work
            eigV = eig(covar{j});
            if sum(eigV<=0) > 0, R{j} = NaN;
            else
                n = 100;
                %***
            %The covariance matrix for the jth year of data has been put in
            %'covar{j}' at this point.  Compute the Monte Carlo ensemble of
            %parameter sets using 100 random draws from the multivariate
            %normal distribution of parameters.  Hint:  this only takes one
            %line of code.
                
                %throw out sets where parameters 4 or 6 are negative
                certainParamsPos = (R{j}(:,4)>0) & (R{j}(:,6)>0);
                zeroParamMask = repmat(certainParamsPos, 1, 7);
%                 zeroParamMask = double(zeroParamMask);
                R{j} = R{j}(zeroParamMask);
                R{j} = reshape(R{j}, length(R{j})/7, 7);
            end
            
            else
            R{j} = NaN;
            end
            
            
            
        end
end

%% Calculate phenology dates
%For optimal parameters, as well as Monte Carlo samples
switch model_name
     case 'greenDownSigmoid'
        switch date_method
            case 'CCR'
            if ~isnan(resnorm{j})  %If optimization worked
                sixDates(:,j) = CCRgd(params{j}, modelT{j},...
                    fhandle);
            else
                sixDates(:,j) = NaN*ones(6,1);
            end
                
            %% generate phenodates for each parameter sample
            if ~isnan(resnorm{j}) & ~isnan(R{j})
                %If optimization worked and
                %If covariance matrix could be calculated
                tic
                for k = 1:size(R{j},1)
                sixDatesMC{j}(:,k) = CCRgd(R{j}(k,:),...
                    modelT{j},...
                    fhandle);
                end
                fprintf(1,'Calculated uncertainties\n'); 
                toc
                else
                    fprintf(1,'Could not calculate valid covariance matrix\n'); 
                    sixDatesMC{j} = NaN;
            end     
         end
end
        if ~isnan(sixDatesMC{j})
            sixDatesMC_low95(j,:) = quantile(sixDatesMC{j}', 0.025);
            sixDatesMC_high95(j,:) = quantile(sixDatesMC{j}', 0.975);
            monte_carlo_widths(j,:) = ...
                sixDatesMC_high95(j,:) - sixDatesMC_low95(j,:);
        else
            monte_carlo_widths(j,:) = NaN*ones(1,6);
        end
        fprintf('Done with %s %s\n', site,...
            num2str(years(j)));
end

%% Save results as formatted CSV file
fid = fopen(['./output/' site '_' ROI '_CIs.csv'], 'w');
fprintf(fid, 'year, SOS, MOS, EOS, SOF, MOF, EOF\n');

for i = 1:length(years)

    fprintf(fid, ['dates ' num2str(years(i)) ', ']);
    for j = 1:6
        fprintf(fid, num2str(sixDates(j,i)));
        if j ~= 6, fprintf(fid, ', '); end
    end
    fprintf(fid, '\n');
    
    fprintf(fid, ['95%% CI ' num2str(years(i)) ', ']);
    for j = 1:6
        fprintf(fid, num2str(monte_carlo_widths(i,j)));
        if j ~= 6, fprintf(fid, ', '); end
    end
    fprintf(fid, '\n');
    
end
0;

%% 
%     case 'greenDownRichards'
%         if ~isnan(resnorm{j})  %If optimization worked
%             nObs = size(jacobian{j},1);
%             nParams = size(jacobian{j},2);
%             jacobian{j} = full(jacobian{j});
%             temp1 = jacobian{j}' * jacobian{j};
%             %As seen here:  http://www.gnu.org/software/gsl/manual/html_node/Computing-the-covariance-matrix-of-best-fit-parameters.html
%             %eliminate rows and columns with a small diagonal element from
%             %this matrix and set the corrsponding rows and columns of the
%             %covariance matrix to zero
%             %throw out rows and columns with small diag entries
%             smallCovarTol = 1;   %experiment with this.  on website
%             %it was defined in terms of other parameter sensitivities
%             smallDiag = diag(temp1)<smallCovarTol;
% %             nSmallDiag = sum(smallDiag);
%             for k = nParams:-1:1
%                 if smallDiag(k) == 1
%                     temp1(k,:) = [];
%                     temp1(:,k) = [];
%                 end
%             end
%             
%             %compute reduced covariance matrix
%             temp2 = inv(temp1);% + 0.0001*eye(size(temp1,1)));
%             tempCovar{j} = resnorm{j} * temp2 ... %\eye(size(jacobian{j},2)) ...
%                 / (nObs-nParams);
%             
%             %add zeros back in for insensitive parameters
%             covarMask = ones(nParams);
%             for k = 1:nParams
%                 if smallDiag(k) == 1
%                     covarMask(k,:) = zeros(1,nParams);
%                     covarMask(:,k) = zeros(nParams,1);
%                 end
%             end
%             covarMask = logical(covarMask);
%             covar{j} = zeros(nParams);
%             covar{j}(covarMask) = tempCovar{j};
% 
% %             %flag negative eigenvalues indicating mvnrnd will not work
% %             eigV = eig(covar{j});
% %             if sum(eigV<=0) > 0
% %                 R{j} = NaN;
% %                 continue;
% %             else
% %                 n = 100;
% %                 R{j} = mvnrnd(params{j},covar{j},n);
% %             end
%             n = 100;
%             try
%                 R{j} = mvnrnd(params{j},covar{j},n);
%             catch
%                 R{j} = NaN;
%             end
%             
% %             R{j} = mvnrnd(params{j},covar{j},n);
% %             R;
%         end
%         
%             case 'greenDownRichards'
%         switch date_method
%             case 'CCR'
%               fprintf(1, ['Error, only use ''percentiles'' method with'...
%                   'generalized sigmoid']);
%             case 'percentiles'
% %                 percentiles = [0.10 0.50 0.50 0.10];
%             if ~isnan(resnorm{j})  %If optimization worked
%                 sixDates(:,j) = percentileDates(params{j}, modelT{j},...
%                     fhandle, percentiles, model_name);
%             else
%                 sixDates(:,j) = NaN*ones(6,1);
%             end
%                 
%             %% generate phenodates for each parameter sample
%             if ~isnan(resnorm{j}) & ~isnan(R{j})
%                 %If optimization worked and
%                 %If covariance matrix could be calculated
%             tic
%             for k = 1:size(R{j},1)
%             sixDatesMC{j}(:,k) = percentileDates(R{j}(k,:),...
%                 modelT{j},...
%                 fhandle, percentiles, model_name);
%             end
%             fprintf(1,'Calculated uncertainties\n'); 
%             toc
%             else
%                 fprintf(1,'Could not calculate valid covariance matrix\n'); 
%                 sixDatesMC{j} = NaN;
%             end     
%         end