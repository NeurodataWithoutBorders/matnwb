function data = swapDims(data)
% SWAPDIMS swaps first and last dimensions of a MATLAB array. Useful
% function to deal with rows-last convention for DynamicTable format and
% rows-first convention of MATLAB API.
%
%   DATA = SWAPDIMS(DATA) Swaps first and last dimensions of DATA array.
dims = ndims(data);
dim_order = 1:dims;
dim_order(1) = dims;
dim_order(end) = 1;
data = permute(data,dim_order);
end