function [params, modelT, modelY, cutOffDates, resnorm, initGuess,...
    initGuessY, weighting, residual, jacobian] = ...
    estParamsSeparateSigmoids(fhandle, modelName, dataT, dataY)
%============================================
% [] = [params, modelT, modelY, cutOffDates, resnorm] = ...
%    estParamsSeparateSigmoids(fhandle, dataT, dataY, weighting)
%
%% description
% This function constructs an initial guess for parameters for separate
% sigmoid curves of the form (Y = c ./ (1 + exp(a+b*X)) + d) based on on
% the input data, then uses lsqnonlin.m to estimate the parameters.
%
%% inputs
% fhandle is a function handle of the model to be estimated, an individual
% sigmoid which is used both for spring and fall
%
% dataT is the time vector for the input data
%
% dataY is a vector of input data
%
%
%============================================
% Stephen Klosterman
% 11/20/2011
% steve.klosterman@gmail.com
%============================================

%% default arguments
% set non-default options for matlab's parameter estimation algorithm
options = optimset('MaxFunEvals', 4*1e3, 'MaxIter', 4*1e3,...
    'Display', 'off' );
weighting.type = 'none';
weighting.weight = 1;

%Initial cut to divide the year into two seasons
halfYear = 200;

%%============================================
%% Spring
%%============================================
%% subset the data
%Fit spring data first, by itself
%get data indices for the first half of the year
firstHalfYearIndices = dataT <= halfYear;
firstHalfYearTime = dataT(firstHalfYearIndices);
firstHalfYearData = dataY(firstHalfYearIndices);

%% initial guess for parameters
% only do this if there is enough spring time in the data set
if ~isempty(springTime)

%***Create an initial guess for the parameter vector of the form
%initGuess1 = [a b c d];

%% see how initial guess is
figh = figure;
temp1 = fhandle(initGuess1, springTime);
plot(springTime, temp1, springTime, springData);
%*** Breakpoint the below line to see the plot before it disappears!
close(figh);

%% error checking:  onset and offset dates should not be the same
% if onsetIndex == peakIndex
%     params(1,:) = [0 0 0 0];
%     resnorm(1) = 0;
% else
    %% parameter estimation
    %non-linear least squares
    [params(1,:), resnorm(1),residual{1},~,~,~,jacobian{1}]...
        = lsqnonlin(@(params)...
        dataDiff(params,springData,springTime,fhandle,modelName,...
        weighting), initGuess1,...
        -Inf*ones(size(initGuess1)), Inf*ones(size(initGuess1)), options);
% end
else params(1,:) = NaN*ones(1,4); cutOffDates(1) = NaN; resnorm(1) = NaN;
    residual{1} = NaN; jacobian{1} = NaN;
end

%%============================================
%% Fall
%%============================================

%%
weighting.type = 'none';

%% subset the data
%get data indices for the second half of the year
secondHalfYearIndices = dataT >= halfYear;
secondHalfYearTime = dataT(secondHalfYearIndices);
secondHalfYearData = dataY(secondHalfYearIndices);


%% initial guess for parameters
% only do this if there is enough fall in the data set
if ~isempty(fallTime)

%*** form 'initGuess2' similar to 'initGuess1'.

%% see how initial guess is
figh = figure;
temp2 = fhandle(initGuess2, fallTime);
plot(fallTime, temp2, fallTime, fallData);
close(figh);

%% error checking:  peak and offset dates should not be the same
% if peakFallIndex == offsetIndex
%     params(2,:) = [0 0 0 0];
%     resnorm(2) = 0;
% else
%% parameter estimation
%non-linear least squares
[params(2,:), resnorm(2),residual{2},~,~,~,jacobian{2}]...
    = lsqnonlin(@(params)...
    dataDiff(params,fallData,fallTime,fhandle,modelName,...
    weighting), initGuess2,...
    -Inf*ones(size(initGuess2)), Inf*ones(size(initGuess2)), options);
% end
else params(2,:) = NaN*ones(1,4); cutOffDates(2) = NaN; resnorm(2) = NaN;
    residual{2} = NaN; jacobian{2} = NaN;
end

%% stitch together spring and fall models for output

%Create output if both spring and fall worked
if (~isempty(springTime) && ...
        (springTime(length(springTime))-springTime(1) >= changeTime)) &&...
        (~isempty(fallTime) && ...
        (fallTime(length(fallTime))-fallTime(1) >= changeTime))
    cutOffDates = [max(springTime) min(fallTime)];
    initGuess = [initGuess1; initGuess2];
    initGuessY = [temp1; temp2];
    modelT = [springTime; fallTime];
    modelY = [fhandle(params(1,:), springTime); fhandle(params(2,:), fallTime)];
%Or just spring
elseif (~isempty(springTime) && ...
        (springTime(length(springTime))-springTime(1) >= changeTime)) &&...
        (isempty(fallTime) || ...
        (fallTime(length(fallTime))-fallTime(1) < changeTime))
    cutOffDates = [max(springTime) NaN];
    initGuess = [initGuess1; NaN*ones(1,4)];
    initGuessY = [temp1];
    modelT = springTime;
    modelY = fhandle(params(1,:), springTime);
%Or just fall
elseif (isempty(springTime) || ...
        (springTime(length(springTime))-springTime(1) < changeTime)) &&...
        (~isempty(fallTime) && ...
        (fallTime(length(fallTime))-fallTime(1) >= changeTime))
    cutOffDates = [NaN min(fallTime)];
    initGuess = [NaN*ones(1,4); initGuess2];
    initGuessY = [temp2];
    modelT = fallTime;
    modelY = fhandle(params(2,:), fallTime);
%Or just spring
end

%If neither worked
if (isempty(springTime) || ...
        (springTime(length(springTime))-springTime(1) < changeTime)) &&...
        (isempty(fallTime) || ...
        (fallTime(length(fallTime))-fallTime(1) < changeTime))
    params = NaN*ones(2,4);
    modelT = NaN*ones(size(dataT));
    modelY = NaN*ones(size(dataY));
    cutOffDates = [NaN NaN];
    initGuess = NaN*ones(2,4);
    initGuessY = NaN*ones(size(dataY));
end
%% see how parameter estimation worked
% figh = figure;
% plot(modelT, modelY, dataT, dataY);
% close(fhandle);