classdef GetObjectReferenceFieldsTest < matlab.unittest.TestCase
% GetObjectReferenceFieldsTest - Unit tests for getObjectReferenceFields.
%
% These tests are deliberately free of any zarr-matlab dependency: the
% function under test takes an attributes dictionary and returns field
% names, so it can be exercised without a Zarr store on disk.
%
% The fixtures mirror what zarr-matlab decodes from the attributes hdmf-zarr
% writes for a compound dataset: a string -> cell dictionary, in which a JSON
% list is an Nx1 cell and a JSON string a string scalar. hdmf-zarr lists the
% reference fields in "_REFERENCE_FIELDS", a list of field names.

    methods (TestClassSetup)
        function requireDictionaryBraceIndexing(testCase)
        % The function under test reads the attributes dictionary with brace
        % indexing, which MATLAB added in R2023a, the release zarr-matlab
        % requires as well (see tests.util.assumeZarr3Support).
            testCase.assumeFalse(isMATLABReleaseOlderThan("R2023a"), ...
                "dictionary brace indexing requires MATLAB R2023a or newer.")
        end
    end

    methods (Static, Access = private)
        function attrs = buildAttributes(referenceFields)
        % buildAttributes - Attributes carrying _REFERENCE_FIELDS.
            attrs = dictionary("_REFERENCE_FIELDS", {num2cell(reshape(string(referenceFields), [], 1))});
        end
    end

    methods (Test)
        function returnsListedReferenceField(testCase)
        % A TimeSeriesReferenceVectorData column: only "timeseries" is a
        % reference. A one-element list must still be read as a list.
            attrs = tests.unit.io.internal.zarr3.GetObjectReferenceFieldsTest.buildAttributes(...
                "timeseries");

            referenceFields = io.internal.zarr3.getObjectReferenceFields(attrs);

            testCase.verifyEqual(referenceFields, "timeseries");
        end

        function returnsEveryListedFieldInOrder(testCase)
            attrs = tests.unit.io.internal.zarr3.GetObjectReferenceFieldsTest.buildAttributes(...
                ["first_ref", "second_ref"]);

            referenceFields = io.internal.zarr3.getObjectReferenceFields(attrs);

            testCase.verifyEqual(referenceFields, ["first_ref", "second_ref"]);
        end

        function returnsEmptyWhenAttributeIsAbsent(testCase)
        % hdmf-zarr writes no _REFERENCE_FIELDS for a compound dataset
        % without reference fields, e.g. a TimeIntervals start/stop pair.
            referenceFields = io.internal.zarr3.getObjectReferenceFields(...
                dictionary(string.empty, {}));

            testCase.verifyEmpty(referenceFields);
        end

        function emptyResultIsRowShapedString(testCase)
        % The result feeds arguments blocks validated as (1,:) string -- in
        % io.backend.zarr3.Zarr3LazyArray and
        % io.internal.zarr3.getCompoundTypeDescriptor. MATLAB accepts a 0x0
        % empty for that validation, so this pins the shape as a contract of
        % this function rather than as a guard against a downstream error.
            referenceFields = io.internal.zarr3.getObjectReferenceFields(...
                dictionary(string.empty, {}));

            testCase.verifyClass(referenceFields, "string");
            testCase.verifySize(referenceFields, [1 0]);
        end

        function emptyListStillYieldsRowShapedString(testCase)
        % An empty _REFERENCE_FIELDS list is the input for which the row
        % shape is not implicit. Exercised to keep the shape contract above
        % true for every code path, not just the common one.
            attrs = dictionary("_REFERENCE_FIELDS", {cell(0, 1)});

            referenceFields = io.internal.zarr3.getObjectReferenceFields(attrs);

            testCase.verifyClass(referenceFields, "string");
            testCase.verifySize(referenceFields, [1 0]);
        end

        function resultIsAcceptedByCompoundArgumentValidation(testCase)
        % Guards the contract the previous tests describe, by exercising the
        % consumer that declares it.
            referenceFields = io.internal.zarr3.getObjectReferenceFields(...
                dictionary(string.empty, {}));

            testCase.verifyWarningFree(@() io.backend.zarr3.Zarr3LazyArray(...
                "unused.zarr", "/unused", [], [], referenceFields));
        end
    end
end
