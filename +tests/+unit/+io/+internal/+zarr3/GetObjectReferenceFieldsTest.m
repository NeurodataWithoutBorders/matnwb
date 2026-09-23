classdef GetObjectReferenceFieldsTest < matlab.unittest.TestCase
% GetObjectReferenceFieldsTest - Unit tests for getObjectReferenceFields.
%
% These tests are deliberately free of any zarr-matlab dependency: the
% function under test takes a decoded attribute struct and returns field
% names, so it can be exercised without a Zarr store on disk.
%
% The attribute fixtures mirror the "zarr_dtype" payload hdmf-zarr writes for
% a compound dataset -- a list of {"name", "dtype"} objects, decoded by
% matnwb into an Nx1 struct array with char fields. See the compound dtype
% section of hdmf-zarr's docs/source/storage.rst.

    methods (Static, Access = private)
        function attrs = buildAttributes(names, dtypes)
        % buildAttributes - Nx1 struct array, matching the decoded attribute.
            descriptors = struct('name', cellstr(names), 'dtype', cellstr(dtypes));
            attrs = struct('zarr_dtype', reshape(descriptors, [], 1));
        end
    end

    methods (Test)
        function returnsFieldTaggedAsObject(testCase)
        % A TimeSeriesReferenceVectorData column: only "timeseries" is a
        % reference; the two index fields are literal data.
            attrs = tests.unit.io.internal.zarr3.GetObjectReferenceFieldsTest.buildAttributes(...
                ["idx_start", "count", "timeseries"], ["int32", "int32", "object"]);

            referenceFields = io.internal.zarr3.getObjectReferenceFields(attrs);

            testCase.verifyEqual(referenceFields, "timeseries");
        end

        function returnsEveryObjectFieldInDeclarationOrder(testCase)
            attrs = tests.unit.io.internal.zarr3.GetObjectReferenceFieldsTest.buildAttributes(...
                ["first_ref", "count", "second_ref"], ["object", "int32", "object"]);

            referenceFields = io.internal.zarr3.getObjectReferenceFields(attrs);

            testCase.verifyEqual(referenceFields, ["first_ref", "second_ref"]);
        end

        function returnsEmptyWhenNoFieldIsAReference(testCase)
        % A plain compound column, e.g. a TimeIntervals start/stop pair.
            attrs = tests.unit.io.internal.zarr3.GetObjectReferenceFieldsTest.buildAttributes(...
                ["start_time", "stop_time"], ["float64", "float64"]);

            referenceFields = io.internal.zarr3.getObjectReferenceFields(attrs);

            testCase.verifyEmpty(referenceFields);
        end

        function returnsEmptyWhenAttributeIsAbsent(testCase)
        % A dataset written without the hdmf-zarr "zarr_dtype" attribute.
            referenceFields = io.internal.zarr3.getObjectReferenceFields(struct());

            testCase.verifyEmpty(referenceFields);
        end

        function returnsEmptyForNonCompoundAttribute(testCase)
        % For a non-compound reference dataset hdmf-zarr writes "zarr_dtype"
        % as the scalar string "object" rather than a per-field list. Such a
        % dataset has no fields, so nothing is reported.
            referenceFields = io.internal.zarr3.getObjectReferenceFields(...
                struct('zarr_dtype', "object"));

            testCase.verifyEmpty(referenceFields);
        end

        function emptyResultIsRowShapedString(testCase)
        % The result feeds arguments blocks validated as (1,:) string -- in
        % io.backend.zarr3.Zarr3LazyArray and
        % io.internal.zarr3.getCompoundTypeDescriptor. MATLAB accepts a 0x0
        % empty for that validation, so this pins the shape as a contract of
        % this function rather than as a guard against a downstream error.
            attrs = tests.unit.io.internal.zarr3.GetObjectReferenceFieldsTest.buildAttributes(...
                ["start_time", "stop_time"], ["float64", "float64"]);

            referenceFields = io.internal.zarr3.getObjectReferenceFields(attrs);

            testCase.verifyClass(referenceFields, "string");
            testCase.verifySize(referenceFields, [1 0]);
        end

        function emptyDescriptorListStillYieldsRowShapedString(testCase)
        % A "zarr_dtype" holding no descriptors at all is the only input for
        % which the row shape is not implicit: indexing the names of an empty
        % struct array gives a 0x0. Exercised to keep the shape contract
        % above true for every code path, not just the common one.
            attrs = struct('zarr_dtype', struct('name', {}, 'dtype', {}));

            referenceFields = io.internal.zarr3.getObjectReferenceFields(attrs);

            testCase.verifyClass(referenceFields, "string");
            testCase.verifySize(referenceFields, [1 0]);
        end

        function resultIsAcceptedByCompoundArgumentValidation(testCase)
        % Guards the contract the previous test describes, by exercising the
        % consumer that declares it.
            attrs = tests.unit.io.internal.zarr3.GetObjectReferenceFieldsTest.buildAttributes(...
                "start_time", "float64");
            referenceFields = io.internal.zarr3.getObjectReferenceFields(attrs);

            testCase.verifyWarningFree(@() io.backend.zarr3.Zarr3LazyArray(...
                "unused.zarr", "/unused", [], [], referenceFields));
        end
    end
end
