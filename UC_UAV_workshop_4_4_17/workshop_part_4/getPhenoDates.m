function [six_dates] = ...
    getPhenoDates(years, model_name, params, modelT, modelY,...
    T, Y,...
    date_method, percentiles,...
    cut_off_dates,...
    fhandle, site, ROI, index)
%============================================
%
%% description
% This function uses a modeled timeseries of a vegetation index to estimate
% phenological transition dates.  Results are saved in the directory where
% the data and modeled time series results are.
%
%% inputs
% model_name is a string used to indicate which model the data has been fit
% to.  Possible arguments are 'separateSigmoids'.
% model_name = 'separateSigmoids';
% model_name = 'greenDownSigmoid';
%
% date_method is a string indicating the method used to extract phenology
% dates 'secondDeriv' and 'CCR'
% date_method = 'CCR';
% 
% percentiles are used by the 'percentiles' and 'dataPercentiles'
% date_methods.  If using other methods, this variable must be assigned a
% value but it will be ignored.
%if using 'percentiles' date_method, specify 4 percentiles for beginning of
%spring, middle of spring, middle of fall, and end of fall.  CCR is used
%for end of spring and beginning of fall.  Dates are calculated as the date
%of crossing the value at this percentile between baseline and CCR value.
% e.g.
% percentiles = [0.10 0.50 0.50 0.10];
%if using 'dataPercentiles' date_method, specify 3 percentiles for
%beginning, middle, and end of spring, e.g.
% percentiles = [0.10 0.50 0.90];   %for dataPercentiles
%
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
%% load or define formula for calculating dates
switch model_name
    case 'separateSigmoids'
        switch date_method
            case 'secondDeriv'
                load('secondDeriv_formula', 'minMax');
            case 'CCR'
                load('CCR_formula.mat', 'Kprime');
        end
    case 'fullYearSigmoid'
        switch date_method
            case 'secondDeriv'
                load('secondDeriv_formula', 'minMax');
            case 'CCR'
                load('CCR_formula.mat', 'Kprime');
        end
    case 'greenDownSigmoid'
        switch date_method
            case 'secondDeriv'
                load('secondDeriv_formula', 'minMax');
        end
    case 'greenDownRichards'
        switch date_method
            case 'secondDeriv'
                load('secondDeriv_formula', 'minMax');
            case 'CCR'
                load('CCR_formula.mat', 'Kprime');
        end
end
    
%% get pheno dates
for i = 1:length(years)
    switch model_name
        case 'separateSigmoids'
            switch date_method
                case 'percentiles'
                        six_dates(1:3,i) = ...
                            percentileDates(params{i}(1,:), ...
                            modelT{i}( modelT{i} <= cut_off_dates{i}(1) ),...
                            fhandle, percentiles, model_name);
                        %fall
%                         percentiles = [0.10 0.50 0.50 0.10];
                        six_dates(4:6,i) = ...
                            percentileDates(params{i}(2,:), ...
                            modelT{i}( modelT{i} >= cut_off_dates{i}(2) ),...
                            fhandle, percentiles, model_name);
                    case 'secondDeriv'
                        six_dates(:,i) = secondDeriv(params{i}, minMax,...
                            T{i}, cut_off_dates{i});

                    case 'CCR'
                        %spring
                        temp = CCR(params{i}(1,:),...
                            modelT{i}( modelT{i} <= cut_off_dates{i}(1) ),...
                            Kprime, fhandle)';
                        six_dates(1:3,i) = temp;
                        %fall
                        temp = CCR(params{i}(2,:),...
                            modelT{i}( modelT{i} >= cut_off_dates{i}(2) ),...
                            Kprime, fhandle)';
                        six_dates(4:6,i) = temp;
                end
            case 'fullYearSigmoid'
                switch date_method
                    case 'secondDeriv'
                        six_dates(:,i) = secondDeriv(params{i}, minMax,...
                            T{i}, cut_off_dates{i});

                    case 'CCR'
                        %spring
                        springParams = [params{i}(3) params{i}(4)...
                            params{i}(2) params{i}(1)];
                        temp = CCR(springParams,...
                            modelT{i},...
                            Kprime)';
                        six_dates(1:3,i) = temp;
                        %fall
                        fallParams = [params{i}(5) params{i}(6)...
                            params{i}(2) params{i}(1)];
                        temp = CCR(fallParams,...
                            modelT{i},...
                            Kprime)';
                        six_dates(4:6,i) = temp;
                end
            case 'greenDownSigmoid'
                switch date_method
                    case 'percentiles'
                        six_dates(:,i) = percentileDates(params{i}, modelT{i},...
                            fhandle, percentiles, model_name);
                        
                    case 'secondDeriv'
                        tempParams = [params{i}(3)/params{i}(4)...
                            -1/params{i}(4);
                            -params{i}(5)/params{i}(6)...
                            1/params{i}(6)];
                            
                        six_dates(:,i) = secondDeriv(tempParams, minMax,...
                            T{i}, cut_off_dates{i});

                    case 'CCR'
                        six_dates(:,i) = CCRgd(params{i}, modelT{i},...
                            fhandle);
                        six_dates;
                end
                
            case 'greenDownRichards'
                switch date_method
                    case 'CCR'
                        six_dates(:,i) = CCRgd(params{i}, modelT{i},...
                            fhandle);
                    case 'percentiles'
                        six_dates(:,i) = percentileDates(params{i}, modelT{i},...
                            fhandle, percentiles, model_name);
                        
%                         %% Temporary fix to throw out year with missing
%                         %fall data from Bartlett
%                         if i == 3
%                             six_dates(4:6,i) = NaN*ones(3,1);
%                         end

                end
                
            case 'smoothInterp'
                switch date_method
                    case 'percentiles'
                        six_dates(:,i)...
                            = dataPercentileDates(modelT{i},...
                            modelY{i},...
                            percentiles);
                        
                        %% Temporary fix to throw out year with missing
                        %fall data from Bartlett
                        if i == 3
                            six_dates(4,i) = NaN*ones(1,1);
                        end
                    case 'fallRedMax'
                        six_dates(:,i) = fallRedMax(modelT{i},...
                            modelY{i});
                end     
    end
    fprintf('generated phenodates for %s %s\n', site,...
        num2str(years(i)));
end

% %% Print results to CSV file
% data_out = six_dates;
% year_nums = cellfun(@str2num, years);
% data_out = vertcat(year_nums, six_dates);
% data_out = num2cell(data_out);
% row_headers = {'year'; 'SOS'; 'MOS'; 'EOS'; 'SOF'; 'MOF'; 'EOF'};
% data_out = [row_headers, data_out];
% xlswrite(['.' filesep 'output' filesep ...
%     index '_phenology_dates_' site '_' ROI '_' model_name], data_out);
% 
% save(['.' filesep 'output' filesep ...
%     index '_phenology_dates_' site '_' ROI '_' model_name], 'six_dates');