function nwbtable = compound2dynamic(T, varargin)
%TABLE2DYNAMIC converts from a MATLAB table to an NWB DynamicTable
%   NWBTABLE = COMPOUND2DYNAMIC(T) converts table T into a
%   types.core.DynamicTable
%
%   NWBTABLE = COMPOUND2DYNAMIC(T, CLASSNAME) converts table T into a specific subclass of
%   of DynamicTable specified by CLASSNAME
%
%   NWBTABLE = COMPOUND2DYNAMIC(__, 'path', PATH) converts table T with ragged array given
%   expected location of the table
%
%   NWBTABLE = COMPOUND2DYNAMIC(__, 'TableDescription', DESCRIPTION) includes the DESCRIPTION in the
%   description field of the DynamicTable
%
%   NWBTABLE = COMPOUND2DYNAMIC(__, 'ColumnDescriptions', DESCRIPTIONS) includes the DESCRIPTIONS
%   containers.Map or struct with each column description by label.
%
%EXAMPLE
%   T = table([.1, 1.5, 2.5]', [1., 2., 3.]', [0, 1, 0]', ...
%       'VariableNames', {'start', 'stop', 'condition'});
%nwbfile.trials = compound2dynamic(T, 'TableDescription', 'my description')

parser = inputParser;
parser.addRequired('T', @(t) istable(t) || isstruct(t) || isa(t, 'containers.Map'));
parser.addOptional('classname', 'types.core.DynamicTable', @(cnm) ischar(cnm));
parser.addParameter('path', '', @(p) ischar(p));
parser.addParameter('TableDescription', 'no description', @(td) ischar(td));
parser.addParameter('ColumnDescriptions', struct(),...
    @(col_d) isstruct(col_d) || isa(col_d, 'containers.Map'));
parse(parser, T, varargin{:});

classname = parser.Results.classname;
if ~any(strcmp('classname', parser.UsingDefaults))    
    %check that DynamicTable is a superclass
    mc = metaclass(classname);
    supers = [mc.SuperclassList];
    while ~any(strcmp({supers.Name}, parentName))
        supers = [supers.SuperclassList];
        assert(~isempty(supers),...
            'MATNWB:INVALIDARG',...
            'class `%s` must be a `types.core.DynamicTable` or its descendent',...
            classname);
    end
end

nwbtable = eval([classname...
    '(''colnames'', T.Properties.VariableNames, '...
    '''description'', parser.Results.TableDescription)']);

%certain dynamic tables have specially named properties that need to be checked
% before being dumped into vectordata or vectorindex
% Ignore DynamicTable-specific fields like `vectordata` or `vectorindex` (as ugly as it may be).
tbl_props = setdiff(properties('types.core.DynamicTable'), properties(nwbtable));
usingDefaultDescr = any(strcmp('ColumnDescriptions', parser.UsingDefaults));
for colind = 1:width(T)
    col = T(:,colind);
    colname = col.Properties.VariableNames{1};
    vals = col.Variables;
    if iscell(vals) && ~iscellstr(vals)
        [vind, vdat] = processRaggedColumn(colname, vals);
    else
        vind = [];
        vdat = vals;
    end
    
    if usingDefaultDescr
        col_descr = 'no description';
    elseif isstruct(parser.Results.ColumnDescriptions)
        col_descr = parser.Results.ColumnDescriptions.(colname);
    else
        col_descr = parser.Results.ColumnDescriptions(colname);
    end
    
    vector_data = types.core.VectorData('data', vdat,...
        'description', col_descr);
    
    if any(strcmp(colname, tbl_props))
        nwbtable.(colname) = vector_data;
    else
        nwbtable.vectordata.set(colname, vector_data);
    end
    
    if ~isempty(vind)
        colind_name = [colname '_index'];
        assert(~any(strcmp('path', p.UsingDefaults)), 'MATNWB:RAGGEDARRAYPATH',...
            ['Your table has a ragged array (`%s`) in it '...
            'which requires a full HDF5 path to the returned Dynamic Table object '...
            'for the index column (`%s`).'],...
            colname, colind_name);
        
        vector_index = types.core.VectorIndex(...
            'target', types.untyped.ObjectView(path),...
            'data', vind);
        if any(strcmp(colind_name, tbl_props))
            nwbtable.(colind_name) = vector_index;
        else
            nwbtable.vectorindex.set(colind_name, vector_index);
        end
    end
end

if isempty(nwbtable.id)
    nwbtable.id = types.core.ElementIdentifiers('data', [0:height(T)-1] .');
end
end

% deserializes the table to a struct array with column name and values under ('Name', 'Value')
function map = deserializeCompound(T)
if istable(T)
elseif isa(T, 'containers.Map')
elseif isstruct(T) && isscalar(T)
    %scalar struct where 'name' -> 'value'
else
    map = T;
end    
end

% takes in a ragged column, returns it as concatenated data with cumsum indices
function [vind, vdat] = processRaggedColumn(colname, vals)
valtype = class(vals{1});
assert(all(cellfun('isclass', vals, class(vals{1}))),...
    'MATNWB:RAGGEDARRAYTYPE', 'Your table''s ragged array (`%s`) must all be of the same type.',...
    colname);
assert(all(cellfun('prodofsize', vals) == cellfun('length', vals)),...
    'MATNWB:RAGGEDARRAYDIMS', 'Your table''s ragged array (`%s`) must all be vectors.',...
    colname);

%find dimension of these vectors
coldim = 1; %minimal case would be scalar or empty objects in which case assume the first dimension.
col_lengths = 0;
colndims = max(cellfun('ndims', vals));
invalidateDims = false;
for i=1:colndims
    valsz = cellfun('size', vals, i);
    if any(valsz > 1)
        %check that all vectors are using the same dims.
        assert(~invalidateDims, 'MATNWB:RAGGEDARRAYDIMS',...
            'Vectors in your ragged array (`%s`) should use the same dimensions.',...
            colname);
        coldim = i;
        col_lengths = valsz;
        invalidateDims = true;  %invalidate future dims with dimensions > 1
    end
end

%combine vector across correct dimensions
combined_sz = ones(1, colndims);
combined_sz(coldim) = sum(col_lengths);
combined_vals = zeros(combined_sz, valtype);
combined_ind = cumsum(col_lengths);

combined_vals(1:combined_ind(1)) = vals{1};
for i=2:length(vals)
    s_ind = combined_ind(i-1)+1;
    combined_vals(s_ind:combined_ind(i)) = vals{i};
end

vind = combined_ind;
vdat = combined_vals;
end