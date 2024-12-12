classdef IntracellularRecordingsTable < types.hdmf_common.AlignedDynamicTable & types.untyped.GroupClass
% INTRACELLULARRECORDINGSTABLE - A table to group together a stimulus and response from a single electrode and a single simultaneous recording. Each row in the table represents a single recording consisting typically of a stimulus and a corresponding response. In some cases, however, only a stimulus or a response is recorded as part of an experiment. In this case, both the stimulus and response will point to the same TimeSeries while the idx_start and count of the invalid column will be set to -1, thus, indicating that no values have been recorded for the stimulus or response, respectively. Note, a recording MUST contain at least a stimulus or a response. Typically the stimulus and response are PatchClampSeries. However, the use of AD/DA channels that are not associated to an electrode is also common in intracellular electrophysiology, in which case other TimeSeries may be used.
%
% Required Properties:
%  electrodes, id, responses, stimuli


% REQUIRED PROPERTIES
properties
    electrodes; % REQUIRED (IntracellularElectrodesTable) Table for storing intracellular electrode related metadata.
    responses; % REQUIRED (IntracellularResponsesTable) Table for storing intracellular response related metadata.
    stimuli; % REQUIRED (IntracellularStimuliTable) Table for storing intracellular stimulus related metadata.
end

methods
    function obj = IntracellularRecordingsTable(varargin)
        % INTRACELLULARRECORDINGSTABLE - Constructor for IntracellularRecordingsTable
        %
        % Syntax:
        %  intracellularRecordingsTable = types.core.INTRACELLULARRECORDINGSTABLE() creates a IntracellularRecordingsTable object with unset property values.
        %
        %  intracellularRecordingsTable = types.core.INTRACELLULARRECORDINGSTABLE(Name, Value) creates a IntracellularRecordingsTable object where one or more property values are specified using name-value pairs.
        %
        % Input Arguments (Name-Value Arguments):
        %  - categories (char) - The names of the categories in this AlignedDynamicTable. Each category is represented by one DynamicTable stored in the parent group. This attribute should be used to specify an order of categories and the category names must match the names of the corresponding DynamicTable in the group.
        %
        %  - colnames (char) - The names of the columns in this table. This should be used to specify an order to the columns.
        %
        %  - dynamictable (DynamicTable) - A DynamicTable representing a particular category for columns in the AlignedDynamicTable parent container. The table MUST be aligned with (i.e., have the same number of rows) as all other DynamicTables stored in the AlignedDynamicTable parent container. The name of the category is given by the name of the DynamicTable and its description by the description attribute of the DynamicTable.
        %
        %  - electrodes (IntracellularElectrodesTable) - Table for storing intracellular electrode related metadata.
        %
        %  - id (ElementIdentifiers) - Array of unique identifiers for the rows of this dynamic table.
        %
        %  - responses (IntracellularResponsesTable) - Table for storing intracellular response related metadata.
        %
        %  - stimuli (IntracellularStimuliTable) - Table for storing intracellular stimulus related metadata.
        %
        %  - vectordata (VectorData) - Vector columns, including index columns, of this dynamic table.
        %
        % Output Arguments:
        %  - intracellularRecordingsTable (types.core.IntracellularRecordingsTable) - A IntracellularRecordingsTable object
        
        varargin = [{'description' 'A table to group together a stimulus and response from a single electrode and a single simultaneous recording and for storing metadata about the intracellular recording.'} varargin];
        obj = obj@types.hdmf_common.AlignedDynamicTable(varargin{:});
        
        
        p = inputParser;
        p.KeepUnmatched = true;
        p.PartialMatching = false;
        p.StructExpand = false;
        addParameter(p, 'description',[]);
        addParameter(p, 'electrodes',[]);
        addParameter(p, 'responses',[]);
        addParameter(p, 'stimuli',[]);
        misc.parseSkipInvalidName(p, varargin);
        obj.description = p.Results.description;
        obj.electrodes = p.Results.electrodes;
        obj.responses = p.Results.responses;
        obj.stimuli = p.Results.stimuli;
        if strcmp(class(obj), 'types.core.IntracellularRecordingsTable')
            cellStringArguments = convertContainedStringsToChars(varargin(1:2:end));
            types.util.checkUnset(obj, unique(cellStringArguments));
        end
        if strcmp(class(obj), 'types.core.IntracellularRecordingsTable')
            types.util.dynamictable.checkConfig(obj);
        end
    end
    %% SETTERS
    function set.electrodes(obj, val)
        obj.electrodes = obj.validate_electrodes(val);
    end
    function set.responses(obj, val)
        obj.responses = obj.validate_responses(val);
    end
    function set.stimuli(obj, val)
        obj.stimuli = obj.validate_stimuli(val);
    end
    %% VALIDATORS
    
    function val = validate_description(obj, val)
        if isequal(val, 'A table to group together a stimulus and response from a single electrode and a single simultaneous recording and for storing metadata about the intracellular recording.')
            val = 'A table to group together a stimulus and response from a single electrode and a single simultaneous recording and for storing metadata about the intracellular recording.';
        else
            error('NWB:Type:ReadOnlyProperty', 'Unable to set the ''description'' property of class ''<a href="matlab:doc types.core.IntracellularRecordingsTable">IntracellularRecordingsTable</a>'' because it is read-only.')
        end
    end
    function val = validate_electrodes(obj, val)
        val = types.util.checkDtype('electrodes', 'types.core.IntracellularElectrodesTable', val);
    end
    function val = validate_responses(obj, val)
        val = types.util.checkDtype('responses', 'types.core.IntracellularResponsesTable', val);
    end
    function val = validate_stimuli(obj, val)
        val = types.util.checkDtype('stimuli', 'types.core.IntracellularStimuliTable', val);
    end
    %% EXPORT
    function refs = export(obj, fid, fullpath, refs)
        refs = export@types.hdmf_common.AlignedDynamicTable(obj, fid, fullpath, refs);
        if any(strcmp(refs, fullpath))
            return;
        end
        refs = obj.electrodes.export(fid, [fullpath '/electrodes'], refs);
        refs = obj.responses.export(fid, [fullpath '/responses'], refs);
        refs = obj.stimuli.export(fid, [fullpath '/stimuli'], refs);
    end
end

end