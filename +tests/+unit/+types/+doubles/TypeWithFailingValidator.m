classdef TypeWithFailingValidator < types.untyped.MetaClass
% TypeWithFailingValidator - Test double for exercising MetaClass.validateProperties.
%   Provides a property whose validator always fails and one whose validator
%   always passes, plus a thin wrapper that invokes the protected
%   validateProperties method from outside the class hierarchy.

    properties
        validProperty
        invalidProperty
        coercingProperty
        datetimeProperty
    end

    methods
        function value = validate_validProperty(~, value)
            % Always valid; returns the value unchanged.
        end

        function validate_invalidProperty(~, ~)
            error('NWB:Test:InvalidPropertyValue', ...
                'This property value is never valid.')
        end

        function value = validate_coercingProperty(~, value)
            % Simulates a validator that coerces the input (e.g., dtype
            % conversion). Returns the value as double regardless of input type.
            value = double(value);
        end

        function value = validate_datetimeProperty(~, value)
            value = types.util.checkDtype('datetimeProperty', 'datetime', value);
        end

        function runValidateProperties(obj, fullpath)
            obj.validateProperties(fullpath)
        end
    end

    methods (Access = protected)
        function str = getFooter(~)
            % Override the inherited footer, which inspects required
            % properties assuming a `types.` namespace this test double does
            % not have.
            str = '';
        end
    end
end
