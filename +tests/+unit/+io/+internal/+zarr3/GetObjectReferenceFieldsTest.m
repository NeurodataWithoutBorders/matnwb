classdef GetObjectReferenceFieldsTest < matlab.unittest.TestCase
% GetObjectReferenceFieldsTest - Unit tests for getObjectReferenceFields.
%
% These tests are deliberately free of any zarr-matlab dependency: the
% function under test takes an attributes dictionary and returns field
% names, so it can be exercised without a Zarr store on disk.
%
% The fixtures mirror what zarr-matlab decodes from the attributes hdmf-zarr
% writes for a compound dataset: a string -> cell dictionary, in which a JSON
% list is an Nx1 cell, a JSON string a string scalar, and a JSON object
% another dictionary. hdmf-zarr 0.14 writes "_REFERENCE_FIELDS", a list of
% field names; earlier versions wrote "zarr_dtype", a list of
% {"name", "dtype"} objects.

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

        function attrs = buildLegacyAttributes(names, dtypes)
        % buildLegacyAttributes - Attributes carrying a zarr_dtype list.
            names = string(names);
            dtypes = string(dtypes);
            descriptors = cell(numel(names), 1);
            for iField = 1:numel(names)
                descriptors{iField} = dictionary(["name", "dtype"], {names(iField), dtypes(iField)});
            end
            attrs = dictionary("zarr_dtype", {descriptors});
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

        function referenceFieldsTakePrecedenceOverLegacyDtype(testCase)
        % hdmf-zarr reads _REFERENCE_FIELDS in preference to zarr_dtype.
            attrs = tests.unit.io.internal.zarr3.GetObjectReferenceFieldsTest.buildLegacyAttributes(...
                ["idx_start", "timeseries"], ["int32", "object"]);
            attrs("_REFERENCE_FIELDS") = {{"idx_start"}};

            referenceFields = io.internal.zarr3.getObjectReferenceFields(attrs);

            testCase.verifyEqual(referenceFields, "idx_start");
        end

        function returnsLegacyFieldTaggedAsObject(testCase)
            attrs = tests.unit.io.internal.zarr3.GetObjectReferenceFieldsTest.buildLegacyAttributes(...
                ["idx_start", "count", "timeseries"], ["int32", "int32", "object"]);

            referenceFields = io.internal.zarr3.getObjectReferenceFields(attrs);

            testCase.verifyEqual(referenceFields, "timeseries");
        end

        function returnsEveryLegacyObjectFieldInDeclarationOrder(testCase)
            attrs = tests.unit.io.internal.zarr3.GetObjectReferenceFieldsTest.buildLegacyAttributes(...
                ["first_ref", "count", "second_ref"], ["object", "int32", "object"]);

            referenceFields = io.internal.zarr3.getObjectReferenceFields(attrs);

            testCase.verifyEqual(referenceFields, ["first_ref", "second_ref"]);
        end

        function returnsEmptyWhenNoLegacyFieldIsAReference(testCase)
        % A plain compound column, e.g. a TimeIntervals start/stop pair.
            attrs = tests.unit.io.internal.zarr3.GetObjectReferenceFieldsTest.buildLegacyAttributes(...
                ["start_time", "stop_time"], ["float64", "float64"]);

            referenceFields = io.internal.zarr3.getObjectReferenceFields(attrs);

            testCase.verifyEmpty(referenceFields);
        end

        function returnsEmptyWhenAttributeIsAbsent(testCase)
        % hdmf-zarr writes neither attribute for a compound dataset without
        % reference fields.
            referenceFields = io.internal.zarr3.getObjectReferenceFields(...
                dictionary(string.empty, {}));

            testCase.verifyEmpty(referenceFields);
        end

        function returnsEmptyForNonCompoundLegacyAttribute(testCase)
        % For a non-compound reference dataset hdmf-zarr before 0.14 wrote
        % "zarr_dtype" as the scalar string "object" rather than a per-field
        % list. Such a dataset has no fields, so nothing is reported.
            referenceFields = io.internal.zarr3.getObjectReferenceFields(...
                dictionary("zarr_dtype", {"object"}));

            testCase.verifyEmpty(referenceFields);
        end

        function emptyResultIsRowShapedString(testCase)
        % The result feeds arguments blocks validated as (1,:) string -- in
        % io.backend.zarr3.Zarr3LazyArray and
        % io.internal.zarr3.getCompoundTypeDescriptor. MATLAB accepts a 0x0
        % empty for that validation, so this pins the shape as a contract of
        % this function rather than as a guard against a downstream error.
            attrs = tests.unit.io.internal.zarr3.GetObjectReferenceFieldsTest.buildLegacyAttributes(...
                ["start_time", "stop_time"], ["float64", "float64"]);

            referenceFields = io.internal.zarr3.getObjectReferenceFields(attrs);

            testCase.verifyClass(referenceFields, "string");
            testCase.verifySize(referenceFields, [1 0]);
        end

        function emptyListsStillYieldRowShapedString(testCase)
        % An empty _REFERENCE_FIELDS or zarr_dtype list is the input for
        % which the row shape is not implicit. Exercised to keep the shape
        % contract above true for every code path, not just the common one.
            emptyLists = { ...
                dictionary("_REFERENCE_FIELDS", {cell(0, 1)}), ...
                dictionary("zarr_dtype", {cell(0, 1)})};

            for iCase = 1:numel(emptyLists)
                referenceFields = io.internal.zarr3.getObjectReferenceFields(emptyLists{iCase});

                testCase.verifyClass(referenceFields, "string");
                testCase.verifySize(referenceFields, [1 0]);
            end
        end

        function resultIsAcceptedByCompoundArgumentValidation(testCase)
        % Guards the contract the previous tests describe, by exercising the
        % consumer that declares it.
            attrs = tests.unit.io.internal.zarr3.GetObjectReferenceFieldsTest.buildLegacyAttributes(...
                "start_time", "float64");
            referenceFields = io.internal.zarr3.getObjectReferenceFields(attrs);

            testCase.verifyWarningFree(@() io.backend.zarr3.Zarr3LazyArray(...
                "unused.zarr", "/unused", [], [], referenceFields));
        end
    end
end
