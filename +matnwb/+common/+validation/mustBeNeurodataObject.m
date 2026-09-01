function mustBeNeurodataObject(value)
% mustBeNeurodataObject - Validate that value is a single neurodata object
%
% A neurodata object is an instance of a type of the NWB format, for example
% a types.core.Subject, a column of a table (types.hdmf_common.VectorData), or 
% an NwbFile.
%
% This is used instead of declaring types.untyped.MetaClass as the argument
% type. That class is the root every neurodata type inherits from, so it
% validates the right values, but it names an implementation detail in the
% error a user sees, and its constructor accepts any input, so a value of the
% wrong type is silently converted into an empty object rather than rejected.

    if ~isa(value, 'types.untyped.MetaClass')
        if isempty(value)
            % An empty value is reported as empty rather than by its class,
            % because the class of the usual empty value, [], is double.
            error('NWB:validators:mustBeNeurodataObject', ...
                ['Value must be a neurodata object, for example a ', ...
                'types.core.Subject or a column of a table, but it is empty.'])
        end
        error('NWB:validators:mustBeNeurodataObject', ...
            ['Value must be a neurodata object, for example a ', ...
            'types.core.Subject or a column of a table, but it is a %s.'], ...
            class(value))
    end

    if ~isscalar(value)
        error('NWB:validators:mustBeNeurodataObject', ...
            ['Value must be a single neurodata object, but it is a %s array ', ...
            'of size %s.'], class(value), mat2str(size(value)))
    end
end
