classdef (Sealed) DatasetInfo
% DatasetInfo - Description of a dataset, as reported by a backend reader.
%
% The parse functions need a dataset's name and attributes. How the data
% is stored (type, shape, encoding) matters only to the reader that reads
% it, so the reader keeps that in BackendInfo and interprets it in
% io.backend.base.Reader.readDatasetValue and isReferenceDataset.
%
% See also io.backend.base.Reader, io.backend.model.GroupInfo

    properties (SetAccess = immutable)
        % Name - Name of the dataset within its parent group.
        Name char = ''

        % Attributes - Attributes of the dataset.
        Attributes (:,1) io.backend.model.AttributeInfo

        % BackendInfo - Backend-specific description of the stored data.
        % Only the reader that created the object reads it.
        BackendInfo = []
    end

    methods
        function obj = DatasetInfo(name, attributes, backendInfo)
        % DatasetInfo - Create a dataset description.
        %
        % Syntax:
        %  obj = io.backend.model.DatasetInfo(name, attributes, backendInfo)
        %
        % Input Arguments:
        %  - name - Name of the dataset within its parent group.
        %  - attributes - AttributeInfo array describing the attributes.
        %  - backendInfo - Backend-specific description of the stored data.
        %
        % All inputs are optional; omitted ones are empty.
            arguments
                name = ''
                attributes = io.backend.model.AttributeInfo.empty(0, 1)
                backendInfo = []
            end
            obj.Name = name;
            obj.Attributes = attributes;
            obj.BackendInfo = backendInfo;
        end
    end
end
