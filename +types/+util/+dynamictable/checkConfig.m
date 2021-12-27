function checkConfig(DynamicTable, varargin)
% CHECKCONFIG Given a DynamicTable object, this functions checks for proper
% DynamicTable configuration
%
%   checkConfig(DYNAMICTABLE) runs without error if the DynamicTable is 
%   configured correctly
%
%   checkConfig(DYNAMICTABLE,IGNORELIST) performs checks on columns not in 
%   IGNORELIST cell array
%   
%
%  A properly configured DynamicTable should meet the following criteria:
%  1) The length of all columns in the dynamic table is the same.
%  2) All rows have a corresponding id. If none exist, this function creates them.
if nargin<2
    ignoreList = {};
else
    ignoreList = varargin{1};
end
% remove null characters from column names
if ~isempty(DynamicTable.colnames)
    if iscell(DynamicTable.colnames)
        DynamicTable.colnames = cellfun(...
            @removeNulls, DynamicTable.colnames, ...
            'UniformOutput',false ...
        );
    else
        DynamicTable.colnames = removeNulls(DynamicTable.colnames);
    end
end
end
function in = removeNulls(in)
in(double(in) == 0) = [];
end