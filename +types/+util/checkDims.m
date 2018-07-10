function checkDims(valsize, validSizes)
    if any(valsize == 0)
        return; %ignore empty arrays
    end
    
    for i=1:length(validSizes)
        vs = validSizes{i};
        
        if numel(vs) == 1
            vs = [vs 1];
        end
        
        try
            if (all(valsize == 1) && all(vs == 1)) ...
                    || all(vs >= valsize)
                return;
            end
        catch ME
            %dimensions disagreeing is an expected error here.
            %rethrow all else
            if ~strcmp(ME.identifier, 'MATLAB:dimagree')
                rethrow(ME);
            end
        end
    end
    
    valsizef = ['[' sizeFormatStr(valsize) ']'];
    
    %format into cell array of strings of form `[Inf]` then join
    validSizesStrings = cell(size(validSizes));
    for i=1:length(validSizes)
        validSizesStrings{i} = ['[' sizeFormatStr(validSizes{i}) ']'];
    end
    validSizesf = ['{' strjoin(validSizesStrings, ' ') '}'];
    
    error(['Values size ' valsizef ' is invalid.  Must be one of ' validSizesf],...
        valsize, validSizes{:});
end

function s = sizeFormatStr(sz)
    s = strjoin(repmat({'%d'}, size(sz)), ' ');
end