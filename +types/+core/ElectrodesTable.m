classdef ElectrodesTable < types.hdmf_common.DynamicTable & types.untyped.GroupClass
% ELECTRODESTABLE - A table of all electrodes (i.e. channels) used for recording. Introduced in NWB 2.8.0. Replaces the "electrodes" table (neurodata_type_inc DynamicTable, no neurodata_type_def) that is part of NWBFile.
%
% Required Properties:
%  colnames, description, group, id, location


% REQUIRED PROPERTIES
properties
    group; % REQUIRED (VectorData) Reference to the ElectrodeGroup this electrode is a part of.
    location; % REQUIRED (VectorData) Location of the electrode (channel). Specify the area, layer, comments on estimation of area/layer, stereotaxic coordinates if in vivo, etc. Use standard atlas names for anatomical regions when possible.
end
% OPTIONAL PROPERTIES
properties
    filtering; %  (VectorData) Description of hardware filtering, including the filter name and frequency cutoffs.
    group_name; %  (VectorData) Name of the ElectrodeGroup this electrode is a part of.
    imp; %  (VectorData) Impedance of the channel, in ohms.
    reference; %  (VectorData) Description of the reference electrode and/or reference scheme used for this electrode, e.g., "stainless steel skull screw" or "online common average referencing".
    rel_x; %  (VectorData) x coordinate in electrode group
    rel_y; %  (VectorData) y coordinate in electrode group
    rel_z; %  (VectorData) z coordinate in electrode group
    x; %  (VectorData) x coordinate of the channel location in the brain (+x is posterior).
    y; %  (VectorData) y coordinate of the channel location in the brain (+y is inferior).
    z; %  (VectorData) z coordinate of the channel location in the brain (+z is right).
end

methods
    function obj = ElectrodesTable(varargin)
        % ELECTRODESTABLE - Constructor for ElectrodesTable
        %
        % Syntax:
        %  electrodesTable = types.core.ELECTRODESTABLE() creates a ElectrodesTable object with unset property values.
        %
        %  electrodesTable = types.core.ELECTRODESTABLE(Name, Value) creates a ElectrodesTable object where one or more property values are specified using name-value pairs.
        %
        % Input Arguments (Name-Value Arguments):
        %  - colnames (char) - The names of the columns in this table. This should be used to specify an order to the columns.
        %
        %  - description (char) - Description of what is in this dynamic table.
        %
        %  - filtering (VectorData) - Description of hardware filtering, including the filter name and frequency cutoffs.
        %
        %  - group (VectorData) - Reference to the ElectrodeGroup this electrode is a part of.
        %
        %  - group_name (VectorData) - Name of the ElectrodeGroup this electrode is a part of.
        %
        %  - id (ElementIdentifiers) - Array of unique identifiers for the rows of this dynamic table.
        %
        %  - imp (VectorData) - Impedance of the channel, in ohms.
        %
        %  - location (VectorData) - Location of the electrode (channel). Specify the area, layer, comments on estimation of area/layer, stereotaxic coordinates if in vivo, etc. Use standard atlas names for anatomical regions when possible.
        %
        %  - reference (VectorData) - Description of the reference electrode and/or reference scheme used for this electrode, e.g., "stainless steel skull screw" or "online common average referencing".
        %
        %  - rel_x (VectorData) - x coordinate in electrode group
        %
        %  - rel_y (VectorData) - y coordinate in electrode group
        %
        %  - rel_z (VectorData) - z coordinate in electrode group
        %
        %  - vectordata (VectorData) - Vector columns, including index columns, of this dynamic table.
        %
        %  - x (VectorData) - x coordinate of the channel location in the brain (+x is posterior).
        %
        %  - y (VectorData) - y coordinate of the channel location in the brain (+y is inferior).
        %
        %  - z (VectorData) - z coordinate of the channel location in the brain (+z is right).
        %
        % Output Arguments:
        %  - electrodesTable (types.core.ElectrodesTable) - A ElectrodesTable object
        
        obj = obj@types.hdmf_common.DynamicTable(varargin{:});
        
        
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        addParameter(p, 'filtering',[]);
        addParameter(p, 'group',[]);
        addParameter(p, 'group_name',[]);
        addParameter(p, 'imp',[]);
        addParameter(p, 'location',[]);
        addParameter(p, 'reference',[]);
        addParameter(p, 'rel_x',[]);
        addParameter(p, 'rel_y',[]);
        addParameter(p, 'rel_z',[]);
        addParameter(p, 'x',[]);
        addParameter(p, 'y',[]);
        addParameter(p, 'z',[]);
        misc.parseSkipInvalidName(p, varargin);
        obj.filtering = p.Results.filtering;
        obj.group = p.Results.group;
        obj.group_name = p.Results.group_name;
        obj.imp = p.Results.imp;
        obj.location = p.Results.location;
        obj.reference = p.Results.reference;
        obj.rel_x = p.Results.rel_x;
        obj.rel_y = p.Results.rel_y;
        obj.rel_z = p.Results.rel_z;
        obj.x = p.Results.x;
        obj.y = p.Results.y;
        obj.z = p.Results.z;
        if strcmp(class(obj), 'types.core.ElectrodesTable')
            cellStringArguments = convertContainedStringsToChars(varargin(1:2:end));
            types.util.checkUnset(obj, unique(cellStringArguments));
        end
        if strcmp(class(obj), 'types.core.ElectrodesTable')
            types.util.dynamictable.checkConfig(obj);
        end
    end
    %% SETTERS
    function set.filtering(obj, val)
        obj.filtering = obj.validate_filtering(val);
    end
    function set.group(obj, val)
        obj.group = obj.validate_group(val);
    end
    function set.group_name(obj, val)
        obj.group_name = obj.validate_group_name(val);
    end
    function set.imp(obj, val)
        obj.imp = obj.validate_imp(val);
    end
    function set.location(obj, val)
        obj.location = obj.validate_location(val);
    end
    function set.reference(obj, val)
        obj.reference = obj.validate_reference(val);
    end
    function set.rel_x(obj, val)
        obj.rel_x = obj.validate_rel_x(val);
    end
    function set.rel_y(obj, val)
        obj.rel_y = obj.validate_rel_y(val);
    end
    function set.rel_z(obj, val)
        obj.rel_z = obj.validate_rel_z(val);
    end
    function set.x(obj, val)
        obj.x = obj.validate_x(val);
    end
    function set.y(obj, val)
        obj.y = obj.validate_y(val);
    end
    function set.z(obj, val)
        obj.z = obj.validate_z(val);
    end
    %% VALIDATORS
    
    function val = validate_filtering(obj, val)
        val = types.util.checkDtype('filtering', 'types.hdmf_common.VectorData', val);
    end
    function val = validate_group(obj, val)
        val = types.util.checkDtype('group', 'types.hdmf_common.VectorData', val);
    end
    function val = validate_group_name(obj, val)
        val = types.util.checkDtype('group_name', 'types.hdmf_common.VectorData', val);
    end
    function val = validate_imp(obj, val)
        val = types.util.checkDtype('imp', 'types.hdmf_common.VectorData', val);
    end
    function val = validate_location(obj, val)
        val = types.util.checkDtype('location', 'types.hdmf_common.VectorData', val);
    end
    function val = validate_reference(obj, val)
        val = types.util.checkDtype('reference', 'types.hdmf_common.VectorData', val);
    end
    function val = validate_rel_x(obj, val)
        val = types.util.checkDtype('rel_x', 'types.hdmf_common.VectorData', val);
    end
    function val = validate_rel_y(obj, val)
        val = types.util.checkDtype('rel_y', 'types.hdmf_common.VectorData', val);
    end
    function val = validate_rel_z(obj, val)
        val = types.util.checkDtype('rel_z', 'types.hdmf_common.VectorData', val);
    end
    function val = validate_x(obj, val)
        val = types.util.checkDtype('x', 'types.hdmf_common.VectorData', val);
    end
    function val = validate_y(obj, val)
        val = types.util.checkDtype('y', 'types.hdmf_common.VectorData', val);
    end
    function val = validate_z(obj, val)
        val = types.util.checkDtype('z', 'types.hdmf_common.VectorData', val);
    end
    %% EXPORT
    function refs = export(obj, fid, fullpath, refs)
        refs = export@types.hdmf_common.DynamicTable(obj, fid, fullpath, refs);
        if any(strcmp(refs, fullpath))
            return;
        end
        if ~isempty(obj.filtering)
            refs = obj.filtering.export(fid, [fullpath '/filtering'], refs);
        end
        refs = obj.group.export(fid, [fullpath '/group'], refs);
        if ~isempty(obj.group_name)
            refs = obj.group_name.export(fid, [fullpath '/group_name'], refs);
        end
        if ~isempty(obj.imp)
            refs = obj.imp.export(fid, [fullpath '/imp'], refs);
        end
        refs = obj.location.export(fid, [fullpath '/location'], refs);
        if ~isempty(obj.reference)
            refs = obj.reference.export(fid, [fullpath '/reference'], refs);
        end
        if ~isempty(obj.rel_x)
            refs = obj.rel_x.export(fid, [fullpath '/rel_x'], refs);
        end
        if ~isempty(obj.rel_y)
            refs = obj.rel_y.export(fid, [fullpath '/rel_y'], refs);
        end
        if ~isempty(obj.rel_z)
            refs = obj.rel_z.export(fid, [fullpath '/rel_z'], refs);
        end
        if ~isempty(obj.x)
            refs = obj.x.export(fid, [fullpath '/x'], refs);
        end
        if ~isempty(obj.y)
            refs = obj.y.export(fid, [fullpath '/y'], refs);
        end
        if ~isempty(obj.z)
            refs = obj.z.export(fid, [fullpath '/z'], refs);
        end
    end
end

end