classdef IZeroClampSeries < types.core.CurrentClampSeries & types.untyped.GroupClass
% IZEROCLAMPSERIES Voltage data from an intracellular recording when all current and amplifier settings are off (i.e., CurrentClampSeries fields will be zero). There is no CurrentClampStimulusSeries associated with an IZero series because the amplifier is disconnected and no stimulus can reach the cell.



methods
    function obj = IZeroClampSeries(varargin)
        % IZEROCLAMPSERIES Constructor for IZeroClampSeries
        varargin = [{'bias_current' types.util.correctType(0, 'single') 'bridge_balance' types.util.correctType(0, 'single') 'capacitance_compensation' types.util.correctType(0, 'single') 'stimulus_description' 'N/A'} varargin];
        obj = obj@types.core.CurrentClampSeries(varargin{:});
        
        
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        addParameter(p, 'bias_current',[]);
        addParameter(p, 'bridge_balance',[]);
        addParameter(p, 'capacitance_compensation',[]);
        addParameter(p, 'stimulus_description',[]);
        misc.parseSkipInvalidName(p, varargin);
        obj.bias_current = p.Results.bias_current;
        obj.bridge_balance = p.Results.bridge_balance;
        obj.capacitance_compensation = p.Results.capacitance_compensation;
        obj.stimulus_description = p.Results.stimulus_description;
        if strcmp(class(obj), 'types.core.IZeroClampSeries')
            cellStringArguments = convertContainedStringsToChars(varargin(1:2:end));
            types.util.checkUnset(obj, unique(cellStringArguments));
        end
    end
    %% SETTERS
    
    %% VALIDATORS
    
    function val = validate_bias_current(obj, val)
        if isequal(val, 0)
            val = 0;
        else
            error('NWB:Type:ReadOnlyProperty', 'Unable to set the ''bias_current'' property of class ''<a href="matlab:doc types.core.IZeroClampSeries">IZeroClampSeries</a>'' because it is read-only.')
        end
    end
    function val = validate_bridge_balance(obj, val)
        if isequal(val, 0)
            val = 0;
        else
            error('NWB:Type:ReadOnlyProperty', 'Unable to set the ''bridge_balance'' property of class ''<a href="matlab:doc types.core.IZeroClampSeries">IZeroClampSeries</a>'' because it is read-only.')
        end
    end
    function val = validate_capacitance_compensation(obj, val)
        if isequal(val, 0)
            val = 0;
        else
            error('NWB:Type:ReadOnlyProperty', 'Unable to set the ''capacitance_compensation'' property of class ''<a href="matlab:doc types.core.IZeroClampSeries">IZeroClampSeries</a>'' because it is read-only.')
        end
    end
    function val = validate_stimulus_description(obj, val)
        if isequal(val, 'N/A')
            val = 'N/A';
        else
            error('NWB:Type:ReadOnlyProperty', 'Unable to set the ''stimulus_description'' property of class ''<a href="matlab:doc types.core.IZeroClampSeries">IZeroClampSeries</a>'' because it is read-only.')
        end
    end
    %% EXPORT
    function refs = export(obj, fid, fullpath, refs)
        refs = export@types.core.CurrentClampSeries(obj, fid, fullpath, refs);
        if any(strcmp(refs, fullpath))
            return;
        end
    end
end

end