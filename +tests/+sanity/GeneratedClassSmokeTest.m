classdef (SharedTestFixtures = {tests.fixtures.GenerateCoreFixture}) ...
        GeneratedClassSmokeTest < matlab.unittest.TestCase

    methods (Test)
        function testGeneratedClassDefinitionsHaveMetaClasses(testCase)
            typeClassNames = schemes.utility.listGeneratedTypes();
            typesRoot = string(schemes.utility.findRootDirectoryForGeneratedTypes());
            isClassDefinition = arrayfun( ...
                @(className) startsWithGeneratedClassdef(typesRoot, className), ...
                typeClassNames);
            typeClassNames = typeClassNames(isClassDefinition);

            testCase.verifyNotEmpty(typeClassNames, ...
                'Expected generated neurodata type classes to be available.')

            for i = 1:numel(typeClassNames)
                typeClassName = typeClassNames(i);
                typeClassNameAsChar = char(typeClassName);

                try
                    metaClass = meta.class.fromName(typeClassNameAsChar);
                catch ME
                    testCase.verifyFail(sprintf( ...
                        'Could not get metaclass for generated class "%s": %s', ...
                        typeClassNameAsChar, ME.message))
                    continue
                end

                testCase.verifyNotEmpty(metaClass, sprintf( ...
                    'Expected generated class "%s" to resolve to a metaclass.', ...
                    typeClassNameAsChar))

                if ~isempty(metaClass)
                    testCase.verifyEqual(string(metaClass.Name), typeClassName)
                end
            end
        end
    end
end

function tf = startsWithGeneratedClassdef(typesRoot, typeClassName)
    arguments
        typesRoot (1,1) string
        typeClassName (1,1) string
    end

    relativeFilePath = matnwb.common.internal.classname2path(typeClassName);
    fileText = fileread(fullfile(typesRoot, relativeFilePath));
    tf = startsWith(strtrim(fileText), "classdef");
end
