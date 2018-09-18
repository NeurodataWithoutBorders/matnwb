function h5idx = idx2h5(idx, matSize)
    if islogical(idx)
        idx = find(idx);
    end
    %transform indices to cell array containing linear index bounds
    idx = unique(idx);
    rangeParts = find(diff(idx) > 1);
    startIdx = 1;
    ranges = cell(length(rangeParts)+1,1);
    for i=1:length(rangeParts)
        ranges{i} = [idx(startIdx);idx(rangeParts(i))];
        startIdx = rangeParts(i) + 1;
    end
    ranges{end} = [idx(startIdx);idx(end)];
    
    %transform linear ranges to subscripts
    %compress matSize dimensions
    if nargin == 1 || all(matSize == 1) || (numel(matSize == 2) && any(matSize == 1))
        matSize = 1;
    else
        matSize = matSize(1:find(matSize > 1, 1, 'last'));
    end
    
    for i=1:length(ranges)
        subRange = zeros(2,length(matSize));
        subRange(1,:) = ind2sub(matSize, ranges{i}(1));
        subRange(2,:) = ind2sub(matSize, ranges{i}(2));
        ranges{i} = fliplr(subRange - 1);
    end
    h5idx = ranges;
end