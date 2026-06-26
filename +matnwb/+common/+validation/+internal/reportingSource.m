function previousSource = reportingSource(newSource)
% reportingSource - Get or set the current read-validation reporting source.

    arguments
        newSource = []
    end

    persistent activeSource

    if isempty(activeSource)
        activeSource = [];
    end

    previousSource = activeSource;

    if nargin > 0
        validateSource(newSource)
        activeSource = newSource;
    end
end

function validateSource(source)
    if isempty(source)
        return
    end

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
