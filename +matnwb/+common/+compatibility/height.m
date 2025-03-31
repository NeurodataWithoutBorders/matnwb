function result = height(value)
% height - Number of rows in an array.
%
% From R2020b: height returns the number of rows of an array

    if verLessThan('matlab', '9.9') && (isnumeric(value) || iscell(value)) %#ok<VERLESSMATLAB> - MATLAB < R2020b
        valueSize = size(value);
        result = valueSize(1);
    else
        result = height(value);
    end
end
