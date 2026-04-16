classdef DimensionOrder
%DIMENSIONORDER Global preference manager for NWB data dimension ordering.
%
%   Controls whether matnwb flips dimensions at the HDF5 boundary (legacy
%   behavior) or passes them through in schema/HDF5 order (schema-consistent
%   mode).
%
%   Modes:
%     matlab_style  - (default) Dimensions are reversed at read/write so
%                     MATLAB users work with column-major (F-order) indexing.
%                     The fastest-changing dimension is first in MATLAB.
%
%     schema_style  - Dimensions are NOT reversed. Arrays have the same
%                     dimension order as the NWB schema and the HDF5 file
%                     (C-order, slowest-changing dimension first).
%
%   Note on mixed-mode files:
%     The HDF5 file is always stored in C order regardless of mode. Switching
%     the preference does not change what is on disk — only how MATLAB indexes
%     into the data. A file written in one mode can be read in the other; the
%     data values are intact but the dimension indices will be reversed.
%
%   Usage:
%     % Check the active mode
%     mode = matnwb.preference.DimensionOrder.getMode();
%
%     % Switch to schema-consistent mode
%     matnwb.preference.DimensionOrder.setMode('schema_style');
%
%     % Switch back to legacy mode
%     matnwb.preference.DimensionOrder.setMode('matlab_style');
%
%     % Query whether flipping should occur (used internally by matnwb)
%     shouldFlip = matnwb.preference.DimensionOrder.shouldFlipDimensions();
%
%   See also:
%     matnwb.preference.DimensionOrderMode

    properties (Constant, Access = private)
        PreferenceGroup = 'matnwb'
        PreferenceName  = 'DimensionOrderMode'
    end

    methods (Static)
        function mode = getMode()
        %GETMODE Return the currently active DimensionOrderMode.
        %
        %   mode = matnwb.preference.DimensionOrder.getMode() returns a
        %   matnwb.preference.DimensionOrderMode enum value reflecting the
        %   active dimension ordering preference. Defaults to matlab_style if
        %   no preference has been set.
            cachedMode = matnwb.preference.DimensionOrder.accessCache('get');
            if isempty(cachedMode)
                preferenceDefault = char(matnwb.preference.DimensionOrderMode.matlab_style);
                storedValue = getpref( ...
                    matnwb.preference.DimensionOrder.PreferenceGroup, ...
                    matnwb.preference.DimensionOrder.PreferenceName, ...
                    preferenceDefault);
                mode = matnwb.preference.DimensionOrderMode.(storedValue);
                matnwb.preference.DimensionOrder.accessCache('set', mode);
            else
                mode = cachedMode;
            end
        end

        function setMode(mode)
        %SETMODE Set the active dimension ordering mode.
        %
        %   matnwb.preference.DimensionOrder.setMode(mode) sets the active
        %   dimension ordering preference. The setting persists across MATLAB
        %   sessions via MATLAB preferences.
        %
        %   Input Arguments:
        %     mode - Dimension ordering mode, specified as a
        %            matnwb.preference.DimensionOrderMode enum value or as a
        %            character vector / string: 'matlab_style' or 'schema_style'.
            arguments
                mode {matnwb.preference.DimensionOrder.mustBeDimensionOrderMode}
            end
            if ~isa(mode, 'matnwb.preference.DimensionOrderMode')
                mode = matnwb.preference.DimensionOrderMode.(char(mode));
            end
            setpref( ...
                matnwb.preference.DimensionOrder.PreferenceGroup, ...
                matnwb.preference.DimensionOrder.PreferenceName, ...
                char(mode));
            matnwb.preference.DimensionOrder.accessCache('set', mode);
        end

        function shouldFlip = shouldFlipDimensions()
        %SHOULDFLIPDIMENSIONS Return true if dimensions should be flipped.
        %
        %   shouldFlip = matnwb.preference.DimensionOrder.shouldFlipDimensions()
        %   returns true when the active mode is matlab_style (legacy flipping
        %   behavior) and false when the mode is schema_style. This is called
        %   internally at every HDF5 read/write boundary.
        %
        %   Uses a persistent cache so repeated calls on the hot path are free.
            activeMode = matnwb.preference.DimensionOrder.getMode();
            shouldFlip = activeMode == matnwb.preference.DimensionOrderMode.matlab_style;
        end

        function resetCache()
        %RESETCACHE Clear the in-memory preference cache.
        %
        %   matnwb.preference.DimensionOrder.resetCache() clears the persistent
        %   variable used to cache the active mode. The next call to getMode()
        %   will re-read from MATLAB preferences. Use this in tests to ensure a
        %   clean state after changing preferences.
            matnwb.preference.DimensionOrder.accessCache('reset');
        end
    end

    methods (Static, Access = private)
        function result = accessCache(action, value)
        %ACCESSCACHE Manage the persistent preference cache.
        %
        %   Centralises all access to the persistent variable so that it is
        %   only declared in one place.
            persistent cachedMode
            switch action
                case 'get'
                    result = cachedMode;
                case 'set'
                    cachedMode = value;
                    result = cachedMode;
                case 'reset'
                    cachedMode = [];
                    result = [];
            end
        end

        function mustBeDimensionOrderMode(value)
        %MUSTBEDIMENSIONORDERMODE Validate that value is a valid mode.
            isEnumValue = isa(value, 'matnwb.preference.DimensionOrderMode');
            isTextValue = (ischar(value) || isstring(value)) && ...
                ismember(char(value), {'matlab_style', 'schema_style'});
            assert(isEnumValue || isTextValue, ...
                'NWB:Preference:DimensionOrder:InvalidMode', ...
                ['Mode must be a matnwb.preference.DimensionOrderMode value ' ...
                'or one of: ''matlab_style'', ''schema_style''.']);
        end
    end
end
