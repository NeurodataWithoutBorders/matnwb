classdef IntracellularResponsesTable < types.hdmf_common.DynamicTable & types.untyped.GroupClass
% INTRACELLULARRESPONSESTABLE - Table for storing intracellular response related metadata.
%
% Required Properties:
%  id, response


% REQUIRED PROPERTIES
properties
    response; % REQUIRED (TimeSeriesReferenceVectorData) Column storing the reference to the recorded response for the recording (rows)
end

methods
    function obj = IntracellularResponsesTable(varargin)
        % INTRACELLULARRESPONSESTABLE - Constructor for IntracellularResponsesTable
        %
        % Syntax:
        %  intracellularResponsesTable = types.core.INTRACELLULARRESPONSESTABLE() creates a IntracellularResponsesTable object with unset property values.
        %
        %  intracellularResponsesTable = types.core.INTRACELLULARRESPONSESTABLE(Name, Value) creates a IntracellularResponsesTable object where one or more property values are specified using name-value pairs.
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
        %  - intracellularResponsesTable (types.core.IntracellularResponsesTable) - A IntracellularResponsesTable object
        
        varargin = [{'description' 'Table for storing intracellular response related metadata.'} varargin];
        obj = obj@types.hdmf_common.DynamicTable(varargin{:});
        
        
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        addParameter(p, 'description',[]);
        addParameter(p, 'response',[]);
        misc.parseSkipInvalidName(p, varargin);
        obj.description = p.Results.description;
        obj.response = p.Results.response;
        if strcmp(class(obj), 'types.core.IntracellularResponsesTable')
            cellStringArguments = convertContainedStringsToChars(varargin(1:2:end));
            types.util.checkUnset(obj, unique(cellStringArguments));
        end
        if strcmp(class(obj), 'types.core.IntracellularResponsesTable')
            types.util.dynamictable.checkConfig(obj);
        end
    end
    %% SETTERS
    function set.response(obj, val)
        obj.response = obj.validate_response(val);
    end
    %% VALIDATORS
    
    function val = validate_description(obj, val)
        if isequal(val, 'Table for storing intracellular response related metadata.')
            val = 'Table for storing intracellular response related metadata.';
        else
            error('NWB:Type:ReadOnlyProperty', 'Unable to set the ''description'' property of class ''<a href="matlab:doc types.core.IntracellularResponsesTable">IntracellularResponsesTable</a>'' because it is read-only.')
        end
    end
    function val = validate_response(obj, val)
        val = types.util.checkDtype('response', 'types.core.TimeSeriesReferenceVectorData', val);
    end
    %% EXPORT
    function refs = export(obj, fid, fullpath, refs)
        refs = export@types.hdmf_common.DynamicTable(obj, fid, fullpath, refs);
        if any(strcmp(refs, fullpath))
            return;
        end
        refs = obj.response.export(fid, [fullpath '/response'], refs);
    end
end

end