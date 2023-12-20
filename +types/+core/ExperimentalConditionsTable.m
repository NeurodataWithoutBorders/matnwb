classdef ExperimentalConditionsTable < types.hdmf_common.DynamicTable & types.untyped.GroupClass
% EXPERIMENTALCONDITIONSTABLE A table for grouping different intracellular recording repetitions together that belong to the same experimental condition.


% REQUIRED PROPERTIES
properties
    repetitions; % REQUIRED (DynamicTableRegion) A reference to one or more rows in the RepetitionsTable table.
    repetitions_index; % REQUIRED (VectorIndex) Index dataset for the repetitions column.
end

methods
    function obj = ExperimentalConditionsTable(varargin)
        % EXPERIMENTALCONDITIONSTABLE Constructor for ExperimentalConditionsTable
        obj = obj@types.hdmf_common.DynamicTable(varargin{:});
        
        
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        addParameter(p, 'repetitions',[]);
        addParameter(p, 'repetitions_index',[]);
        misc.parseSkipInvalidName(p, varargin);
        obj.repetitions = p.Results.repetitions;
        obj.repetitions_index = p.Results.repetitions_index;
        if strcmp(class(obj), 'types.core.ExperimentalConditionsTable')
            cellStringArguments = convertContainedStringsToChars(varargin(1:2:end));
            types.util.checkUnset(obj, unique(cellStringArguments));
        end
        if strcmp(class(obj), 'types.core.ExperimentalConditionsTable')
            types.util.dynamictable.checkConfig(obj);
        end
    end
    %% SETTERS
    function set.repetitions(obj, val)
        obj.repetitions = obj.validate_repetitions(val);
    end
    function set.repetitions_index(obj, val)
        obj.repetitions_index = obj.validate_repetitions_index(val);
    end
    %% VALIDATORS
    
    function val = validate_repetitions(obj, val)
        val = types.util.checkDtype('repetitions', 'types.hdmf_common.DynamicTableRegion', val);
    end
    function val = validate_repetitions_index(obj, val)
        val = types.util.checkDtype('repetitions_index', 'types.hdmf_common.VectorIndex', val);
    end
    %% EXPORT
    function refs = export(obj, fid, fullpath, refs)
        refs = export@types.hdmf_common.DynamicTable(obj, fid, fullpath, refs);
        if any(strcmp(refs, fullpath))
            return;
        end
        refs = obj.repetitions.export(fid, [fullpath '/repetitions'], refs);
        refs = obj.repetitions_index.export(fid, [fullpath '/repetitions_index'], refs);
    end
end

end