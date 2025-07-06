function nwbtable = table2nwb(T, description, dataType)
% TABLE2NWB - Converts from a MATLAB table to an NWB DynamicTable
%
% Syntax:
%  nwbtable = util.TABLE2NWB(T) converts table T into a types.core.DynamicTable.
%
%  nwbtable = util.TABLE2NWB(T, description) includes the description in the 
%  DynamicTable.
%
%  nwbtable = util.TABLE2NWB(T, description, dataType) specifies a dataType
%  to use for the resulting nwbtable. The dataType must be the name of a
%  neurodata type that extends DynamicTable
%
% Input Arguments:
%  - T (table) -
%    A MATLAB table to be converted.
%
%  - description (string)
%    A string providing a description for the DynamicTable (default is 
%    "no description").
%
%  - dataType - A string specifying the data type of the DynamicTable 
%              (default is "types.hdmf_common.DynamicTable").
%
% Output Arguments:
%  - nwbtable (types.hdmf_common.DynamicTable) - The resulting DynamicTable 
%    object. If dataType is specified, the nwbtable will be an object of that 
%    specific neurodata type.
%
% Usage:
%  Example 1 - Convert a MATLAB table::
%    
%    nwbFile = NwbFile()
%    T = table([.1, 1.5, 2.5]', [1., 2., 3.]', [0, 1, 0]', ...
%       'VariableNames', {'start', 'stop', 'condition'});
%    nwbFile.trials = table2nwb(T, 'my description')

arguments
    T table
    description (1,1) string = "no description"
    dataType (1,1) string {mustBeDynamicTableTypeName} = "types.hdmf_common.DynamicTable"
end

if ismember('id', T.Properties.VariableNames)
    id = T.id;
else
    id = transpose( 0:height(T)-1 ); % Must be column vector
end

dataTypeConstructor = str2func(dataType);

nwbtable = dataTypeConstructor( ...
    'colnames', T.Properties.VariableNames,...
    'description', description );

for col = T
    currentVariableName = col.Properties.VariableNames{1};
    if strcmp(currentVariableName, 'id')
        nwbtable.id = types.hdmf_common.ElementIdentifiers('data', id);
    else
        if ~isempty(col.Properties.VariableDescriptions) ...
                && ~isempty(col.Properties.VariableDescriptions{1})
            description = col.Properties.VariableDescriptions{1};
        else
            description = 'no description provided';
        end

        currentVectorData = types.hdmf_common.VectorData(...
            'data', col.Variables', ...
            'description', description);

        if isprop(nwbtable, currentVariableName)
            nwbtable.(currentVariableName) = currentVectorData;
        else
            nwbtable.vectordata.set(currentVariableName, currentVectorData);
        end
    end
end

% If `id` were not part of the input table, create a default element identifier
% vector and add it to the nwbtable
if ~any(strcmp(T.Properties.VariableNames, 'id'))
    nwbtable.id = types.hdmf_common.ElementIdentifiers('data', id);
end
end

function mustBeDynamicTableTypeName(typeName)
    % Validate datatype
    if ~strcmp(typeName, "types.hdmf_common.DynamicTable")

        if matnwb.utility.isNeurodataTypeClassName(typeName)

            dataTypeConstructor = str2func(typeName);        
            dummyObject = dataTypeConstructor();
            
            isValidTypeName = isa(dummyObject, 'types.hdmf_common.DynamicTable') ...
                || isa(dummyObject, 'types.core.DynamicTable'); % NWB <= v2.1.0
    
            assert(isValidTypeName, ...
                'NWB:validator:NotDynamicTableType', ...
                '`dataType` must be the name of a neurodata type that extends DynamicTable')
        else
            error('NWB:validator:NotNeurodataType', ...
                '`dataType` is not the name of an existing neurodata type.')
        end
    end
end
