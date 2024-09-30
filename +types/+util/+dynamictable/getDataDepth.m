function depth = getDataDepth(candidate, varargin)
    %GETDATADEPTH given candidate column or row data, returns the depth (number of indices required)
    %to represent it in a Dynamic Table object.

    Parser = inputParser;
    Parser.addParameter('dataPipeDimension', [], @(x)isnumeric(x) && (isempty(x) || isscalar(x)));
    Parser.parse(varargin{:});

    depth = 1;
    subData = candidate;
    while iscell(subData) && ~iscellstr(subData)
        depth = depth + 1;
        subData = subData{1};
    end

    % special case where the final data is in fact multiple rows to begin
    % with.
    if isempty(Parser.Results.dataPipeDimension)
        if ischar(subData)
            isMultiRow = 1 < size(subData, 1);
        else
            isMultiRow = (ismatrix(subData) && 1 < size(subData, 2)) ...
                || (isvector(subData) && 1 < length(subData));
        end
    else
        isMultiRow = 1 < size(subData, Parser.Results.dataPipeDimension);
    end
    if isMultiRow
        depth = depth + 1;
    end
end

