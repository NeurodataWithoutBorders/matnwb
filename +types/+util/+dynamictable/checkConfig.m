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
% do not check specified columns - useful for classes that build on DynamicTable class 
columns = setdiff(DynamicTable.colnames,ignoreList);
% keep track of last non-ragged column index; to prevent looping over array twice
c = 1;
lastStraightCol = 0;
lengths = zeros(length(columns),1);
while c <= length(columns)
    cn = columns{c};
    % ignore columns that have an index (i.e. ragged), length will be unmatched
    indexName = types.util.dynamictable.getIndex(DynamicTable, cn);
    if isempty(indexName)
        if isprop(DynamicTable, cn)
            cv = DynamicTable.(cn);
            if ~isempty(cv)
                lengths(c) = length(cv.data(:));
            end
        else
            if ~isempty(keys(DynamicTable.vectordata))
                try
                    cv = DynamicTable.vectordata.get(cn);
                catch % catch legacy table instance
                    cv = DynamicTable.vectorindex.get(cn);
                end
                if isa(cv.data,'types.untyped.DataStub') || isa(cv.data,'types.untyped.DataPipe')
                    data = cv.data(:);
                else
                    data = cv.data;
                end
                lengths(c) = size(data,1);% interested in number of rows
            end
        end
        if lastStraightCol > 0
            assert(lengths(c)==lengths(lastStraightCol), ...
                'NWB:DynamicTable', ...
                'All columns must be the same length.' ...
                );
        end
        lastStraightCol = c;
    else
        if ~any(strcmp(columns,indexName))
            columns{length(columns)+1} = indexName;
            
        end
    end
    c = c+1;
end

if ~isempty(lengths)
    if isempty(DynamicTable.id) || isempty(DynamicTable.id.data(:))
        if 8 == exist('types.hdmf_common.ElementIdentifiers', 'class')
            DynamicTable.id = types.hdmf_common.ElementIdentifiers( ...
                'data', int64((1:lengths(lastStraightCol))-1)' ...
            );
        else % legacy Element Identifiers
            DynamicTable.id = types.core.ElementIdentifiers( ...
            'data', int64((1:lengths(lastStraightCol))-1)' ...
        );
        end
    
    else
        assert(lengths(lastStraightCol) == length(DynamicTable.id.data(:)), ...
            'NWB:DynamicTable', ...
            'Must provide same number of ids as length of columns.' ...
        );
    end
else
    if 8 == exist('types.hdmf_common.ElementIdentifiers', 'class')
        DynamicTable.id = types.hdmf_common.ElementIdentifiers();
    else % legacy Element Identifiers
        DynamicTable.id = types.core.ElementIdentifiers();
    end
end