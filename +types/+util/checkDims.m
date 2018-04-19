function checkDims(valsize, validSizes)
    validSizesStrings = cell(size(validSizes));
    for i=1:length(validSizes)
        vs = validSizes{i};
        if length(valsize) ~= length(vs)
            continue;
        end
        
        noninf = ~isinf(vs);
        if ~any(noninf) || all(valsize(noninf) == vs(noninf))
            %has a valid size
            return;
        end
        validSizesStrings{i} = ['[' sizeFormatStr(vs) ']'];
    end
    valsizef = ['[' sizeFormatStr(valsize) ']'];
    validSizesf = ['{' strjoin(validSizesStrings, ' ') '}'];
    error(['Values size ' valsizef ' is invalid.  Must be one of ' validSizesf],...
        valsize, validSizes{:});
end

function s = sizeFormatStr(sz)
    s = strjoin(repmat({'%d'}, size(sz)), ' ');
end