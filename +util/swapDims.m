function data = swapDims(data, dims)
% SWAPDIMS swaps first and last dimensions of a MATLAB array. Useful
% function to deal with rows-last convention for DynamicTable format and
% rows-first convention of MATLAB API.
% Examples:
%   DATA = SWAPDIMS(DATA) Swaps first and last dimensions of DATA array.
%   Use when dimensions of array accurately reflected by size(DATA).
%
%   DATA = SWAPDIMS(DATA, DIMS) Swaps first and last dimensions of DATA
%   array. Use when trailing singleton dimensions present in DATA array
%   (e.g., 3x2x1).
if nargin<2
    dims = ndims(data);
end
dim_order = 1:dims;
dim_order(1) = dims;
dim_order(end) = 1;
data = permute(data,dim_order);
end