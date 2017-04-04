function [beginWindowTime, endWindowTime, beginWindowData,...
    endWindowData, beginWindowIndex, endWindowIndex] = ...
    seasonalChange(changeTime, T, Y)

%step through first half of year to find three week window of time with
%maximum variance.  This seems likely to be greenup
endChangeWindow = T + changeTime;   %days
for i = 1:length(T)
    %if the time window is within the first half of the year
    if endChangeWindow(i) <= max(T)
        %get index closests to end of window
        [~, endWindowIndices(i)] = min( abs (...
            (T(i)+changeTime) - T ) );
        %subset based on window of time likely to contain greenup
        changeData = Y(i:endWindowIndices(i));
        %Changed from 'var' to 'nanvar' to deal with Min's LAI data which
        %has nans.
        windowVar(i) = nanvar(changeData);
    else
        break
    end
end

%what window has the maximum variance?
[~, beginWindowIndex] = max(windowVar);
endWindowIndex = endWindowIndices(beginWindowIndex);
%what is the time at the beginning of the window?
beginWindowTime = T(beginWindowIndex);
%what is the time and data at the end of the window?
endWindowTime = T(endWindowIndex);
%what are the corresponding data points?
beginWindowData = Y(beginWindowIndex);
endWindowData = Y(endWindowIndex);