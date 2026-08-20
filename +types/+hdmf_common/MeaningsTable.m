classdef MeaningsTable < types.hdmf_common.DynamicTable & types.untyped.GroupClass
% MEANINGSTABLE - A table to store information about the meanings of values in a referenced VectorData object. All possible values of the referenced VectorData object should be present in the 'value' column of this table, even if the value is not observed in the data. Additional columns may be added to store additional metadata about each value. The name of the MeaningsTable should correspond to the name of the referenced VectorData object with a "_meanings" suffix. e.g., if the referenced VectorData object is named "stimulus_type", the corresponding MeaningsTable should be named "stimulus_type_meanings".
%
% Required Properties:
%  colnames, description, id, meaning, target, value


% REQUIRED PROPERTIES
properties
    meaning; % REQUIRED (VectorData) The meaning of the value in the referenced VectorData object.
    target; % REQUIRED (Object reference to VectorData) Reference to the VectorData object for which this table provides meanings.
    value; % REQUIRED (VectorData) The value of a row in the referenced VectorData object.
end
properties (Constant, Access = private)
    DeclaredSchemaColumns = ["meaning", "value"];
end

methods
    function obj = MeaningsTable(varargin)
        % MEANINGSTABLE - Constructor for MeaningsTable
        %
        % Syntax:
        %  meaningsTable = types.hdmf_common.MEANINGSTABLE() creates a MeaningsTable object with unset property values.
        %
        %  meaningsTable = types.hdmf_common.MEANINGSTABLE(Name, Value) creates a MeaningsTable object where one or more property values are specified using name-value pairs.
        %
        % Input Arguments (Name-Value Arguments):
        %  - colnames (char) - The names of the columns in this table. This should be used to specify an order to the columns.
        %
        %  - description (char) - Description of what is in this dynamic table.
        %
        %  - id (ElementIdentifiers) - Array of unique identifiers for the rows of this dynamic table.
        %
        %  - meaning (VectorData) - The meaning of the value in the referenced VectorData object.
        %
        %  - meanings_tables (MeaningsTable) - MeaningsTable objects that provide meanings for values in VectorData columns within this DynamicTable. Tables should be named according to the column they provide meanings for with a "_meanings" suffix. e.g., if a VectorData column is named "stimulus_type", the corresponding MeaningsTable should be named "stimulus_type_meanings".
        %
        %  - target (Object reference to VectorData) - Reference to the VectorData object for which this table provides meanings.
        %
        %  - value (VectorData) - The value of a row in the referenced VectorData object.
        %
        %  - vectordata (VectorData) - Vector columns, including index columns, of this dynamic table.
        %
        % Output Arguments:
        %  - meaningsTable (types.hdmf_common.MeaningsTable) - A MeaningsTable object
        
        obj = obj@types.hdmf_common.DynamicTable(varargin{:});
        
        
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        addParameter(p, 'meaning',[]);
        addParameter(p, 'target',[]);
        addParameter(p, 'value',[]);
        misc.parseSkipInvalidName(p, varargin);
        obj.meaning = p.Results.meaning;
        obj.target = p.Results.target;
        obj.value = p.Results.value;
        
        % Only execute validation/setup code when called directly in this class's
        % constructor, not when invoked through superclass constructor chain
        if strcmp(class(obj), 'types.hdmf_common.MeaningsTable') %#ok<STISA>
            cellStringArguments = convertContainedStringsToChars(varargin(1:2:end));
            types.util.checkUnset(obj, unique(cellStringArguments));
            obj.setupHasUnnamedGroupsMixin();
            obj.ensureDynamicTableConsistency();
        end
    end
    %% SETTERS
    function set.meaning(obj, val)
        obj.meaning = obj.validate_meaning(val);
        obj.postset_meaning()
    end
    function postset_meaning(obj)
        types.util.dynamictable.syncNamedColumn(obj, 'meaning');
    end
    function set.target(obj, val)
        obj.target = obj.validate_target(val);
    end
    function set.value(obj, val)
        obj.value = obj.validate_value(val);
        obj.postset_value()
    end
    function postset_value(obj)
        types.util.dynamictable.syncNamedColumn(obj, 'value');
    end
    %% VALIDATORS
    
    function val = validate_meaning(obj, val)
        types.util.checkType('meaning', 'types.hdmf_common.VectorData', val);
        if ~isempty(val)
            [val, originalVal] = types.util.unwrapValue(val);
            val = types.util.checkDtype('meaning', 'char', val);
            val = types.util.rewrapValue(val, originalVal);
        end
    end
    function val = validate_target(obj, val)
        % Reference to type `VectorData`
        val = types.util.validateReferenceType('target', val, 'types.hdmf_common.VectorData', 'types.untyped.ObjectView');
        types.util.validateShape('target', {[1]}, val)
    end
    function val = validate_value(obj, val)
        types.util.checkType('value', 'types.hdmf_common.VectorData', val);
    end
    %% EXPORT
    function refs = export(obj, writer, fullpath, refs)
        refs = export@types.hdmf_common.DynamicTable(obj, writer, fullpath, refs);
        if any(strcmp(refs, fullpath))
            return;
        end
        refs = obj.meaning.export(writer, [fullpath '/meaning'], refs);
        writer.writeAttribute([fullpath '/target'], obj.target);
        refs = obj.value.export(writer, [fullpath '/value'], refs);
    end
end

end