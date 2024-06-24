classdef IntracellularElectrodesTable < types.hdmf_common.DynamicTable & types.untyped.GroupClass
% INTRACELLULARELECTRODESTABLE Table for storing intracellular electrode related metadata.


% REQUIRED PROPERTIES
properties
    electrode; % REQUIRED (VectorData) Column for storing the reference to the intracellular electrode.
end

methods
    function obj = IntracellularElectrodesTable(varargin)
        % INTRACELLULARELECTRODESTABLE Constructor for IntracellularElectrodesTable
        varargin = [{'description' 'Table for storing intracellular electrode related metadata.'} varargin];
        obj = obj@types.hdmf_common.DynamicTable(varargin{:});
        
        
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        addParameter(p, 'description',[]);
        addParameter(p, 'electrode',[]);
        misc.parseSkipInvalidName(p, varargin);
        obj.description = p.Results.description;
        obj.electrode = p.Results.electrode;
        if strcmp(class(obj), 'types.core.IntracellularElectrodesTable')
            cellStringArguments = convertContainedStringsToChars(varargin(1:2:end));
            types.util.checkUnset(obj, unique(cellStringArguments));
        end
        if strcmp(class(obj), 'types.core.IntracellularElectrodesTable')
            types.util.dynamictable.checkConfig(obj);
        end
    end
    %% SETTERS
    function set.electrode(obj, val)
        obj.electrode = obj.validate_electrode(val);
    end
    %% VALIDATORS
    
    function val = validate_description(obj, val)
        if isequal(val, 'Table for storing intracellular electrode related metadata.')
            val = 'Table for storing intracellular electrode related metadata.';
        else
            error('Unable to set the ''description'' property of class ''<a href="matlab:doc types.core.IntracellularElectrodesTable">IntracellularElectrodesTable</a>'' because it is read-only.')
        end
    end
    function val = validate_electrode(obj, val)
        val = types.util.checkDtype('electrode', 'types.hdmf_common.VectorData', val);
    end
    %% EXPORT
    function refs = export(obj, fid, fullpath, refs)
        refs = export@types.hdmf_common.DynamicTable(obj, fid, fullpath, refs);
        if any(strcmp(refs, fullpath))
            return;
        end
        refs = obj.electrode.export(fid, [fullpath '/electrode'], refs);
    end
end

end