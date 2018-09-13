function checkDims(valsize, validSizes)
    if any(valsize == 0)
        return; %ignore empty arrays
    end
    
    for i=1:length(validSizes)
        vs = validSizes{i};
        if length(vs) > length(valsize)
            continue;
        end
        
        if isscalar(vs)
            if max(valsize) == prod(valsize) && all(valsize(3:end) == 1) && ...
                    (isinf(vs) || vs == max(valsize))
                return;
            end
        else
            nonInf = find(~isinf(vs));
            if all(vs(nonInf) == valsize(nonInf)) &&...
                    all(valsize(length(vs)+1:end) == 1)
                return;
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