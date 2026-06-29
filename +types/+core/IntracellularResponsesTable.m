classdef IntracellularResponsesTable < types.hdmf_common.DynamicTable & types.untyped.GroupClass
% INTRACELLULARRESPONSESTABLE - Table for storing intracellular response related metadata.
%
% Required Properties:
%  colnames, id, response


% REQUIRED PROPERTIES
properties
    response; % REQUIRED (TimeSeriesReferenceVectorData) Column storing the reference to the recorded response for the recording (rows)
end

methods
    function obj = IntracellularResponsesTable(varargin)
        % INTRACELLULARRESPONSESTABLE - Constructor for IntracellularResponsesTable
        %
        % Syntax:
        %  intracellularResponsesTable = types.core.INTRACELLULARRESPONSESTABLE() creates an IntracellularResponsesTable object with unset property values.
        %
        %  intracellularResponsesTable = types.core.INTRACELLULARRESPONSESTABLE(Name, Value) creates an IntracellularResponsesTable object where one or more property values are specified using name-value pairs.
        %
        % Input Arguments (Name-Value Arguments):
        %  - colnames (char) - The names of the columns in this table. This should be used to specify an order to the columns.
        %
        %  - id (ElementIdentifiers) - Array of unique identifiers for the rows of this dynamic table.
        %
        %  - response (TimeSeriesReferenceVectorData) - Column storing the reference to the recorded response for the recording (rows)
        %
        %  - vectordata (VectorData) - Vector columns, including index columns, of this dynamic table.
        %
        % Output Arguments:
        %  - intracellularResponsesTable (types.core.IntracellularResponsesTable) - An IntracellularResponsesTable object
        
        varargin = [{'description' 'Table for storing intracellular response related metadata.'} varargin];
        obj = obj@types.hdmf_common.DynamicTable(varargin{:});
        
        
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        addParameter(p, 'response',[]);
        misc.parseSkipInvalidName(p, varargin);
        obj.response = p.Results.response;
        
        % Only execute validation/setup code when called directly in this class's
        % constructor, not when invoked through superclass constructor chain
        if strcmp(class(obj), 'types.core.IntracellularResponsesTable') %#ok<STISA>
            cellStringArguments = convertContainedStringsToChars(varargin(1:2:end));
            types.util.checkUnset(obj, unique(cellStringArguments));
            types.util.dynamictable.checkConfig(obj);
        end
    end
    %% SETTERS
    function set.response(obj, val)
        obj.response = obj.validate_response(val);
        obj.postset_response()
    end
    function postset_response(obj)
        types.util.dynamictable.syncNamedColumn(obj, 'response');
    end
    %% VALIDATORS
    
    function val = validate_description(obj, val)
        constantValue = 'Table for storing intracellular response related metadata.';
        val = types.util.checkConstant('description', constantValue, val, 'types.core.IntracellularResponsesTable');
    end
    function val = validate_response(obj, val)
        types.util.checkType('response', 'types.core.TimeSeriesReferenceVectorData', val);
    end
    %% EXPORT
    function refs = export(obj, writer, fullpath, refs)
        refs = export@types.hdmf_common.DynamicTable(obj, writer, fullpath, refs);
        if any(strcmp(refs, fullpath))
            return;
        end
        refs = obj.response.export(writer, [fullpath '/response'], refs);
    end
end

end