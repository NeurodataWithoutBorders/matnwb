classdef NodeInfoTest < matlab.unittest.TestCase
% NodeInfoTest - Unit tests for the node description classes in io.backend.model.

    methods (Test)
        function testGroupNameIsLastPathElement(testCase)
            nestedInfo = io.backend.model.GroupInfo('/a/b');
            topInfo = io.backend.model.GroupInfo('/a');

            testCase.verifyEqual(nestedInfo.Name, 'b');
            testCase.verifyEqual(topInfo.Name, 'a');
        end

        function testRootGroupHasEmptyName(testCase)
            rootInfo = io.backend.model.GroupInfo();

            testCase.verifyEqual(rootInfo.Path, '/');
            testCase.verifyEmpty(rootInfo.Name);
        end

        function testOmittedChildrenAreEmptyColumns(testCase)
            groupInfo = io.backend.model.GroupInfo('/a');

            testCase.verifyClass(groupInfo.Groups, 'io.backend.model.GroupInfo');
            testCase.verifySize(groupInfo.Groups, [0 1]);
            testCase.verifyClass(groupInfo.Datasets, 'io.backend.model.DatasetInfo');
            testCase.verifySize(groupInfo.Datasets, [0 1]);
            testCase.verifyClass(groupInfo.Links, 'io.backend.model.LinkInfo');
            testCase.verifySize(groupInfo.Links, [0 1]);
            testCase.verifyClass(groupInfo.Attributes, 'io.backend.model.AttributeInfo');
            testCase.verifySize(groupInfo.Attributes, [0 1]);
        end

        function testChildrenAreStoredAsColumns(testCase)
            attributes = [io.backend.model.AttributeInfo('a', 1), ...
                io.backend.model.AttributeInfo('b', 2)];
            datasetInfo = io.backend.model.DatasetInfo('d', attributes);
            groupInfo = io.backend.model.GroupInfo('/g', Attributes=attributes);

            testCase.verifySize(datasetInfo.Attributes, [2 1]);
            testCase.verifySize(groupInfo.Attributes, [2 1]);
            testCase.verifyEqual({groupInfo.Attributes.Name}, {'a', 'b'});
        end

        function testFromListsCreatesOneAttributePerName(testCase)
            attributes = io.backend.model.AttributeInfo.fromLists( ...
                {'a', "b"}, {1, 'two'}, {[], struct('Kind', 'text')});

            testCase.verifySize(attributes, [2 1]);
            testCase.verifyEqual({attributes.Name}, {'a', 'b'});
            testCase.verifyEqual({attributes.Value}, {1, 'two'});
            testCase.verifyEqual(attributes(2).BackendInfo, struct('Kind', 'text'));
        end

        function testFromListsWithoutNamesIsEmptyColumn(testCase)
            attributes = io.backend.model.AttributeInfo.fromLists({}, {}, {});

            testCase.verifyClass(attributes, 'io.backend.model.AttributeInfo');
            testCase.verifySize(attributes, [0 1]);
        end

        function testTextPropertiesAreChar(testCase)
            linkInfo = io.backend.model.LinkInfo("l", "external link", "/x", "other.nwb");
            groupInfo = io.backend.model.GroupInfo("/g");

            testCase.verifyEqual(linkInfo.Name, 'l');
            testCase.verifyEqual(linkInfo.Type, 'external link');
            testCase.verifyEqual(linkInfo.TargetPath, '/x');
            testCase.verifyEqual(linkInfo.TargetFile, 'other.nwb');
            testCase.verifyEqual(groupInfo.Path, '/g');
        end
    end
end
