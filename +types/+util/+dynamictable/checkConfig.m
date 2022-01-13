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
% do not check specified columns - useful for classes that build on DynamicTable class 
columns = setdiff(DynamicTable.colnames,ignoreList);
% keep track of last non-ragged column index; to prevent looping over array twice
c = 1;
lastStraightCol = 0;
lengths = zeros(length(columns),1);
while c <= length(columns)
    found_cv = 0; %reset flag
    cn = columns{c};
    % ignore columns that have an index (i.e. ragged), length will be unmatched
    indexName = types.util.dynamictable.getIndex(DynamicTable, cn);
    if isempty(indexName)
        % retrieve data vector
        if isprop(DynamicTable, cn)
            cv = DynamicTable.(cn);
            found_cv = 1;
        else
            if ~isempty(keys(DynamicTable.vectordata))
                try
                    cv = DynamicTable.vectordata.get(cn);
                    found_cv = 1;
                catch % catch legacy table instance
                    cv = DynamicTable.vectorindex.get(cn);
                    found_cv = 1;
                end
            end
        end
        if found_cv && ~isempty(cv)
            % figure out vector height
            if isa(cv.data,'types.untyped.DataStub')
                colHeight = cv.data.dims(end);
            elseif isa(cv.data,'types.untyped.DataPipe')
                if length(cv.data.internal.maxSize) == 1
                    % catch 1D column
                    rank = 1;
                elseif ismatrix(cv.data.internal.maxSize) && ...
                        cv.data.internal.maxSize(2) == 1
                    % catch column vector
                    rank = 1;
                else
                    rank = length(cv.data.internal.maxSize);
                end
                selectInd = cell(1, rank);
                selectInd(1:end) = {':'};
                colHeight = size(cv.data(selectInd{:}),rank);
            else
                if iscolumn(cv.data)
                    %catch column vector
                    colHeight = length(cv.data);
                else
                    colHeight = size(cv.data,ndims(cv.data));% interested in last dimension
                end
            end
            lengths(c) = colHeight;
        end
        if lastStraightCol > 0 && any(lengths>0)
            if min(lengths(lengths>0)) > 1
                % skip assertion if we can infer this a table with single row.
                % In that case, multidimensional columns can be  ambiguous
                assert(lengths(c)==lengths(lastStraightCol), ...
                    'NWB:DynamicTable', ...
                    'All columns must be the same length.' ...
                    );
            end
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
                'data', int64((1:min(lengths(lengths>0)))-1)' ...
            );
        else % legacy Element Identifiers
            DynamicTable.id = types.core.ElementIdentifiers( ...
                'data', int64((1:min(lengths(lengths>0)))-1)' ...
            );
        end
    else
        if lastStraightCol > 0 && any(lengths>0)
            if min(lengths(lengths>0)) > 1 && ...
                    length(lengths)>1 
                % skip assertion if we can infer this a table with single row.
                % In that case, multidimensional columns can be  ambiguous
                assert(lengths(lastStraightCol) == length(DynamicTable.id.data(:)), ...
                    'NWB:DynamicTable', ...
                    'Must provide same number of ids as length of columns.' ...
                );
            elseif length(lengths)==1 && ...
                    length(DynamicTable.id.data(:)) ~= lengths(lastStraightCol)
                % skip if single column and id height matches column height
                assert(length(DynamicTable.id.data(:))==1, ... % single-entry case
                    'NWB:DynamicTable', ...
                    'Must provide same number of ids as length of columns.' ...
                );
            end
        end
    end
else
    if 8 == exist('types.hdmf_common.ElementIdentifiers', 'class')
        DynamicTable.id = types.hdmf_common.ElementIdentifiers();
    else% legacy Element Identifiers
        DynamicTable.id = types.core.ElementIdentifiers();
    end
end
end
function in = removeNulls(in)
in(double(in) == 0) = [];
end