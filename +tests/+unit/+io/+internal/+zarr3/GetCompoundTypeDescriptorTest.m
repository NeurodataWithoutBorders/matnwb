classdef GetCompoundTypeDescriptorTest < matlab.unittest.TestCase
% GetCompoundTypeDescriptorTest - Unit tests for getCompoundTypeDescriptor.
%
% Like GetObjectReferenceFieldsTest, these run without zarr-matlab: the
% function under test consumes a plain struct.
%
% The dtype fixtures mirror the shape zarr.internal.dtype_info returns for a
% Zarr v3 "structured" data type -- a 1xN struct array of fields, each with a
% string Name and an Info struct carrying matlabClass.

    methods (Static, Access = private)
        function info = buildDtypeInfo(names, matlabClasses)
        % buildDtypeInfo - Minimal dtype_info struct for a compound dtype.
        %
        % Only the members getCompoundTypeDescriptor reads are populated.
            fields = struct(...
                'Name', num2cell(string(names)), ...
                'Info', cellfun(@(c) struct('matlabClass', string(c)), ...
                    cellstr(matlabClasses), 'UniformOutput', false));
            info = struct('zarrType', "structured", 'fields', reshape(fields, 1, []));
        end
    end

    methods (Test)
        function mapsReferenceFieldToObjectView(testCase)
            info = tests.unit.io.internal.zarr3.GetCompoundTypeDescriptorTest.buildDtypeInfo(...
                ["idx_start", "count", "timeseries"], ["int32", "int32", "string"]);

            typeDescriptor = io.internal.zarr3.getCompoundTypeDescriptor(info, "timeseries");

            testCase.verifyEqual(typeDescriptor.timeseries, 'types.untyped.ObjectView');
        end

        function mapsRemainingFieldsToMatlabClass(testCase)
            info = tests.unit.io.internal.zarr3.GetCompoundTypeDescriptorTest.buildDtypeInfo(...
                ["idx_start", "count", "timeseries"], ["int32", "int32", "string"]);

            typeDescriptor = io.internal.zarr3.getCompoundTypeDescriptor(info, "timeseries");

            testCase.verifyEqual(typeDescriptor.idx_start, 'int32');
            testCase.verifyEqual(typeDescriptor.count, 'int32');
        end

        function preservesFieldOrder(testCase)
        % types.util.checkDtype>validateCompoundTypeDescriptor requires the
        % descriptor's fields to match the dataset's field order exactly.
            info = tests.unit.io.internal.zarr3.GetCompoundTypeDescriptorTest.buildDtypeInfo(...
                ["idx_start", "count", "timeseries"], ["int32", "int32", "string"]);

            typeDescriptor = io.internal.zarr3.getCompoundTypeDescriptor(info, "timeseries");

            testCase.verifyEqual(fieldnames(typeDescriptor), ...
                {'idx_start'; 'count'; 'timeseries'});
        end

        function treatsEveryFieldAsLiteralWhenNoReferencesDeclared(testCase)
        % A reference-free compound dataset keeps its underlying classes --
        % notably a text field stays literal text rather than becoming an
        % ObjectView.
            info = tests.unit.io.internal.zarr3.GetCompoundTypeDescriptorTest.buildDtypeInfo(...
                ["label", "weight"], ["string", "double"]);

            typeDescriptor = io.internal.zarr3.getCompoundTypeDescriptor(info, string.empty(1, 0));

            testCase.verifyEqual(typeDescriptor.label, 'char');
            testCase.verifyEqual(typeDescriptor.weight, 'double');
        end

        function reportsTextFieldsAsCharToMatchHdf5Backend(testCase)
        % zarr-matlab represents both Zarr text types as a MATLAB string, but
        % the HDF5 backend reports H5T_STRING as char and the generated type
        % classes declare text compound fields as 'char' (for instance
        % types.hdmf_common.HERD's entity_id). Since
        % types.util.checkDtype>validateCompoundTypeDescriptor compares
        % descriptor entries by name, a descriptor saying 'string' makes an
        % otherwise valid file unreadable.
            info = tests.unit.io.internal.zarr3.GetCompoundTypeDescriptorTest.buildDtypeInfo(...
                ["entity_id", "entity_uri"], ["string", "string"]);

            typeDescriptor = io.internal.zarr3.getCompoundTypeDescriptor(...
                info, string.empty(1, 0));

            testCase.verifyEqual(typeDescriptor.entity_id, 'char');
            testCase.verifyEqual(typeDescriptor.entity_uri, 'char');
        end

        function leavesNonTextClassesUnchanged(testCase)
        % The text mapping must not disturb any other class name.
            info = tests.unit.io.internal.zarr3.GetCompoundTypeDescriptorTest.buildDtypeInfo(...
                ["a", "b", "c", "d"], ["int32", "double", "logical", "uint64"]);

            typeDescriptor = io.internal.zarr3.getCompoundTypeDescriptor(...
                info, string.empty(1, 0));

            testCase.verifyEqual(struct2cell(typeDescriptor), ...
                {'int32'; 'double'; 'logical'; 'uint64'});
        end

        function mapsMultipleReferenceFields(testCase)
            info = tests.unit.io.internal.zarr3.GetCompoundTypeDescriptorTest.buildDtypeInfo(...
                ["x", "first_ref", "second_ref"], ["double", "string", "string"]);

            typeDescriptor = io.internal.zarr3.getCompoundTypeDescriptor(...
                info, ["first_ref", "second_ref"]);

            testCase.verifyEqual(typeDescriptor.x, 'double');
            testCase.verifyEqual(typeDescriptor.first_ref, 'types.untyped.ObjectView');
            testCase.verifyEqual(typeDescriptor.second_ref, 'types.untyped.ObjectView');
        end

        function ignoresDeclaredFieldThatIsNotInTheDtype(testCase)
        % The reference list and the dtype are read from two independent
        % sources (the "zarr_dtype" attribute and the array metadata), so a
        % name present in one but not the other must not error.
            info = tests.unit.io.internal.zarr3.GetCompoundTypeDescriptorTest.buildDtypeInfo(...
                ["idx_start", "count"], ["int32", "int32"]);

            typeDescriptor = io.internal.zarr3.getCompoundTypeDescriptor(info, "timeseries");

            testCase.verifyEqual(fieldnames(typeDescriptor), {'idx_start'; 'count'});
        end
    end
end
