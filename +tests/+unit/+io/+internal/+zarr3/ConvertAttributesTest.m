classdef ConvertAttributesTest < matlab.unittest.TestCase
% ConvertAttributesTest - Unit tests for io.internal.zarr3.convertAttributes.
%
% Only the inputs the fixture-driven reader tests do not produce are
% covered here; the common shapes (links, object references, reserved
% attributes) are exercised through Zarr3ReaderTest.

    methods (TestClassSetup)
        function setupDependencyPaths(testCase)
        % convertAttributes calls hdmf.zarr.Link.fromAttributes for any
        % struct input, so the hdmf-zarr-matlab package must be resolvable.
            tests.util.assumeZarr3Support(testCase)
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(...
                tests.util.getZarr3DependencyPaths()));
        end
    end

    methods (Test)
        function nonStructInputYieldsEmptyOutputs(testCase)
        % zarr-matlab reports "no attributes" as [], not as an empty struct.
            [attributes, links] = io.internal.zarr3.convertAttributes([]);

            testCase.verifyEmpty(attributes);
            testCase.verifyEmpty(links);
            testCase.verifyEqual(fieldnames(attributes), ...
                {'Name'; 'Datatype'; 'Dataspace'; 'Value'});
            testCase.verifyEqual(fieldnames(links), {'Name'; 'Type'; 'Value'});
        end

        function nonScalarCellValueStaysOneAttribute(testCase)
        % struct(..., 'Value', value) expands a non-scalar cell into a
        % struct array; the conversion must keep it as one attribute whose
        % Value is the whole cell.
            rawAttributes = struct('keywords', {{'first', 'second'}});

            attributes = io.internal.zarr3.convertAttributes(rawAttributes);

            testCase.verifyEqual(numel(attributes), 1);
            testCase.verifyEqual(attributes(1).Name, 'keywords');
            testCase.verifyEqual(attributes(1).Value, {'first', 'second'});
        end
    end
end
