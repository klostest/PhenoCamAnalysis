function [i] = getSigDate(data, threshold, trigger, direction)
%============================================
% [i] = getSigDate(data, threshold, trigger, direction)
%
%% description
% This function helps constructs an initial guess for parameters for a
% sigmoid model.  The specific goal is to find the date after which a time
% series has accumulated a certain number of values greater or less than
% some threshold.  This is used for a rough estimate of the onset of some
% greenness regime.
%
%% inputs
% data is a monotonic vector containing the greenness data
%
% threshold is the threshold after which to start accumulating days
%
% trigger is the number of accumulated days signifying the onset of a
% greenness regime
%
% direction is a string containing either 'increase' or 'decrease',
% indicating the direction of the monotonic vector contained in 'data'
%
%% outputs
% i is the index of the vector 'data' after which 'trigger' observations
% above or below 'threshold' have occurred
%
%
%============================================
% Stephen Klosterman
% 11/20/2011
% steve.klosterman@gmail.com
%============================================


lenData = length(data);
count = 0;

switch direction
    case 'increase'
        for i = 1:lenData
            if data(i) >= threshold
                count = count + 1;
            end
            if count == trigger, break; end
        end
        
    case 'decrease'
        for i = 1:lenData
%         for i = lenData:-1:1
            if data(i) <= threshold
%             if data(i) >= threshold
                count = count + 1;
            end
            if count == trigger, break; end
        end
end