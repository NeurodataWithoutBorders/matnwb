classdef (Sealed) AttributeInfo
% AttributeInfo - Description of an attribute, as reported by a backend reader.
%
% Value holds the attribute value as the reader lists it with its node.
% Text and numeric values are final there, which is what the parse
% functions rely on when they read the neurodata_type and namespace
% attributes. Values that need decoding, such as object references, are
% turned into MATLAB values by io.backend.base.Reader.readAttributeValue,
% which may use BackendInfo to do so.
%
% See also io.backend.base.Reader, io.backend.model.GroupInfo,
%   io.backend.model.DatasetInfo

    % SetAccess is private, not immutable, so that fromLists can fill an
    % array of attributes without a constructor call per attribute.
    properties (SetAccess = private)
        % Name - Name of the attribute.
        Name char = ''

        % Value - Attribute value as listed with its node.
        Value = []

        % BackendInfo - Backend-specific description of the stored value.
        % Only the reader that created the object reads it.
        BackendInfo = []
    end

    methods
        function obj = AttributeInfo(name, value, backendInfo)
        % AttributeInfo - Create an attribute description.
        %
        % Syntax:
        %  obj = io.backend.model.AttributeInfo(name, value, backendInfo)
        %
        % Input Arguments:
        %  - name - Name of the attribute.
        %  - value - Attribute value as listed with its node.
        %  - backendInfo - Backend-specific description of the stored value.
        %
        % All inputs are optional; omitted ones are empty.
            arguments
                name = ''
                value = []
                backendInfo = []
            end
            obj.Name = name;
            obj.Value = value;
            obj.BackendInfo = backendInfo;
        end
    end

    methods (Static)
        function attributes = fromLists(names, values, backendInfos)
        % fromLists - Create a column of attribute descriptions.
        %
        % Syntax:
        %  attributes = io.backend.model.AttributeInfo.fromLists(names, values, backendInfos)
        %
        % Input Arguments:
        %  - names - Cell array of attribute names.
        %  - values - Cell array of attribute values, one per name.
        %  - backendInfos - Cell array of backend-specific descriptions, one
        %    per name.
        %
        % Output Arguments:
        %  - attributes - AttributeInfo column with one element per name.
            numAttributes = numel(names);
            attributes = io.backend.model.AttributeInfo.empty(0, 1);
            for iAttribute = numAttributes:-1:1
                attributes(iAttribute, 1).Name = names{iAttribute};
                attributes(iAttribute, 1).Value = values{iAttribute};
                attributes(iAttribute, 1).BackendInfo = backendInfos{iAttribute};
            end
        end
    end
end
