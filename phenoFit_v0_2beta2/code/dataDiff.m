function [resid] = dataDiff(params,data,X,fhandle,modelName,weighting)

[Y] = fhandle(params, X);

switch weighting.type
    case 'none'
        resid = (Y - data);
    case 'timeExponential'  %exponential time ramp
        resid = (Y - data) .^ X.^weighting{2};
    case 'timeTrigger'  %weight values after certain time
        if strcmp(modelName, 'separateSigmoids') || strcmp(modelName, 'separateSigmoids_new')
            %this needs to be redone, ensure that both spring and fall
            %weighting criteria are indices and not data points, and clean
            %up estParamsSeparateSigmoids.m
            resid = abs(Y-data) + ...
                abs( (Y - data) ...
                .* double( (X>=weighting.times(1) )...
                .* double( (X<=weighting.times(2)) ) )...
                *weighting.weight);
        elseif strcmp(modelName, 'fullYearSigmoid') || ...
                strcmp(modelName, 'greenDownSigmoid')
            tempResid = abs(Y-data);
            
            resid = tempResid + weighting.weightMask.*...
                tempResid*weighting.weight;

        end
end

% resid = 1e6*(Y - data);  %Make differences bigger for
%optimization algorithm?