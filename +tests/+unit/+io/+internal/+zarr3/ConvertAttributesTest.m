classdef ConvertAttributesTest < matlab.unittest.TestCase
% ConvertAttributesTest - Unit tests for io.internal.zarr3.convertAttributes.
%
% Only the inputs the fixture-driven reader tests do not produce are
% covered here: value conversion, and the attribute forms written before
% hdmf-zarr 0.14. The 0.14 forms (links, object references, reserved
% attributes) are exercised through Zarr3ReaderTest.
%
% Inputs mirror what zarr-matlab decodes from a node's attributes: a string
% -> cell dictionary, in which a JSON list is an Nx1 cell, a JSON string a
% string scalar, and a JSON object another dictionary.

    methods (TestClassSetup)
        function setupDependencyPaths(testCase)
        % convertAttributes calls hdmf.zarr.Link.fromAttributes for any
        % non-empty input, so the hdmf-zarr-matlab package must be
        % resolvable.
            tests.util.assumeZarr3Support(testCase)
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(...
                tests.util.getZarr3DependencyPaths()));
        end
    end

    methods (Test)
        function nonDictionaryInputYieldsEmptyOutputs(testCase)
            [attributes, links] = io.internal.zarr3.convertAttributes([]);

            testCase.verifyEmpty(attributes);
            testCase.verifyEmpty(links);
            testCase.verifyEqual(fieldnames(attributes), ...
                {'Name'; 'Datatype'; 'Dataspace'; 'Value'});
            testCase.verifyEqual(fieldnames(links), {'Name'; 'Type'; 'Value'});
        end

        function textListBecomesOneCellstrAttribute(testCase)
        % struct(..., 'Value', value) expands a cell into a struct array;
        % the conversion must keep it as one attribute whose Value is the
        % whole list, as a cellstr like h5info gives.
            rawAttributes = dictionary("keywords", {{"first"; "second"}});

            attributes = io.internal.zarr3.convertAttributes(rawAttributes);

            testCase.verifyEqual(numel(attributes), 1);
            testCase.verifyEqual(attributes(1).Name, 'keywords');
            testCase.verifyEqual(attributes(1).Value, {'first'; 'second'});
        end

        function singleElementTextListStaysAList(testCase)
        % A DynamicTable with one column still has a list of colnames.
            rawAttributes = dictionary("colnames", {{"x"}});

            attributes = io.internal.zarr3.convertAttributes(rawAttributes);

            testCase.verifyEqual(attributes(1).Value, {'x'});
        end

        function textBecomesChar(testCase)
            rawAttributes = dictionary("description", {"a description"});

            attributes = io.internal.zarr3.convertAttributes(rawAttributes);

            testCase.verifyEqual(attributes(1).Value, 'a description');
        end

        function numericListBecomesColumnVector(testCase)
            rawAttributes = dictionary("resolution", {{1; 2; 3}});

            attributes = io.internal.zarr3.convertAttributes(rawAttributes);

            testCase.verifyEqual(attributes(1).Value, [1; 2; 3]);
        end

        function nestedNumericListBecomesMatrix(testCase)
        % One row per inner list, as jsondecode reads [[1, 2], [3, 4]].
            rawAttributes = dictionary("matrix", {{{1; 2}; {3; 4}}});

            attributes = io.internal.zarr3.convertAttributes(rawAttributes);

            testCase.verifyEqual(attributes(1).Value, [1 2; 3 4]);
        end

        function emptyListBecomesEmpty(testCase)
            rawAttributes = dictionary("colnames", {cell(0, 1)});

            attributes = io.internal.zarr3.convertAttributes(rawAttributes);

            testCase.verifyEmpty(attributes(1).Value);
        end

        function reservedAttributesAreDropped(testCase)
            reservedNames = ["_LINKS", "_DTYPE", "_REFERENCE_FIELDS", ...
                "zarr_link", "zarr_dtype", ".specloc", "_ARRAY_DIMENSIONS"];
            rawAttributes = dictionary([reservedNames, "description"], ...
                [{cell(0, 1), "str", cell(0, 1), cell(0, 1), "str", "specifications", cell(0, 1)}, ...
                {"kept"}]);

            attributes = io.internal.zarr3.convertAttributes(rawAttributes);

            testCase.verifyEqual({attributes.Name}, {'description'});
        end

        function legacyReferenceAttributeIsTagged(testCase)
        % hdmf-zarr before 0.14 wrapped an attribute reference as
        % {"zarr_dtype": "object", "value": <record>}.
            record = dictionary(["source", "path"], {".", "/units/spike_times"});
            rawAttributes = dictionary("target", ...
                {dictionary(["zarr_dtype", "value"], {"object", record})});

            attributes = io.internal.zarr3.convertAttributes(rawAttributes);

            testCase.verifyEqual(attributes(1).Datatype, 'object reference');
            objectView = io.internal.zarr3.decodeObjectReferences(attributes(1).Value);
            testCase.verifyEqual(string(objectView.path), "/units/spike_times");
        end

        function legacyLinksAreRead(testCase)
        % hdmf-zarr before 0.14 listed a group's links under "zarr_link".
            linkRecord = dictionary(["name", "source", "path"], ...
                {"device", ".", "/general/devices/array"});
            rawAttributes = dictionary("zarr_link", {{linkRecord}});

            [attributes, links] = io.internal.zarr3.convertAttributes(rawAttributes);

            testCase.verifyEmpty(attributes);
            testCase.verifyEqual(numel(links), 1);
            testCase.verifyEqual(links(1).Name, 'device');
            testCase.verifyEqual(links(1).Type, 'soft link');
            testCase.verifyEqual(links(1).Value, {'/general/devices/array'});
        end
    end
end
