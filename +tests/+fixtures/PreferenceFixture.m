classdef PreferenceFixture < matlab.unittest.fixtures.Fixture
% PreferenceFixture Fixture that sets a MATLAB preference for the duration of a test.
%
%   On setup, the fixture records the current state of the preference and sets
%   it to the requested value. On teardown, the original value is restored. If
%   the preference did not exist before setup, it is removed again on teardown
%   so that running the tests never leaves a new preference behind on the
%   user's machine.
%
%   Example:
%       testCase.applyFixture( ...
%           tests.fixtures.PreferenceFixture('matnwb', 'ContainerDisplayMode', 'groups'))

    properties (SetAccess = immutable)
        Group (1,1) string
        Name (1,1) string
        Value
    end

    methods
        function fixture = PreferenceFixture(group, name, value)
            fixture.Group = group;
            fixture.Name = name;
            fixture.Value = value;
        end

        function setup(fixture)
            if ispref(fixture.Group, fixture.Name)
                originalValue = getpref(fixture.Group, fixture.Name);
                fixture.addTeardown(@() setpref(fixture.Group, fixture.Name, originalValue))
            else
                fixture.addTeardown(@() rmpref(fixture.Group, fixture.Name))
            end
            setpref(fixture.Group, fixture.Name, fixture.Value)
        end
    end

    methods (Access = protected)
        function tf = isCompatible(fixtureA, fixtureB)
            tf = strcmp(fixtureA.Group, fixtureB.Group) ...
                && strcmp(fixtureA.Name, fixtureB.Name) ...
                && isequal(fixtureA.Value, fixtureB.Value);
        end
    end
end
