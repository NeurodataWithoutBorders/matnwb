function [previousSource, cleanup] = reportingSource(newSource, options)
% reportingSource - Get or set the current read-validation reporting source.
%
%   The new source can be provided either as a scalar struct with TypeName
%   and Path fields, or as name-value pairs (TypeName=..., Path=...).
%   The two forms cannot be combined.
%
%   [~, cleanup] = reportingSource(newSource) additionally returns an onCleanup
%   handle that restores the prior source when it goes out of scope.
%   cleanup must be assigned to a named variable — if ignored, it fires
%   immediately and the state change is immediately undone.

    arguments
        newSource struct = struct.empty % Struct with fields TypeName and Path
        options.TypeName (1,1) string
        options.Path (1,1) string
    end

    persistent activeSource

    if isempty(activeSource)
        activeSource = [];
    end

    previousSource = activeSource;

    if ~isempty(newSource) || ~isempty(fieldnames(options))
        assert(isempty(newSource) || isempty(fieldnames(options)), ...
            'NWB:Validation:InvalidReportingSource', ...
            'Specify source as a struct or as name-value pairs, not both.')
        if isempty(newSource)
            newSource = options;
        end
        validateSource(newSource)
        activeSource = newSource;
    end

    if nargout > 1
        cleanup = onCleanup(@() ...
            matnwb.common.validation.internal.reportingSource(previousSource));
    end
end

function validateSource(source)
    if isempty(source); return; end

    assert(isstruct(source) && isscalar(source), ...
        'NWB:Validation:InvalidReportingSource', ...
        'Reporting source must be a scalar struct.')
    assert(isfield(source, 'TypeName') && isfield(source, 'Path'), ...
        'NWB:Validation:InvalidReportingSource', ...
        'Reporting source must have TypeName and Path fields.')
    assert(isTextScalar(source.TypeName) && isTextScalar(source.Path), ...
        'NWB:Validation:InvalidReportingSource', ...
        'Reporting source TypeName and Path fields must be text scalars.')
end

function tf = isTextScalar(value)
    tf = ischar(value) || (isstring(value) && isscalar(value));
end
