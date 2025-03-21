classdef (SharedTestFixtures = {tests.fixtures.GenerateCoreFixture}) ...
        FunctionTests < matlab.unittest.TestCase
% FunctionTests - Unit test for functions in +types namespace.
    methods (TestClassSetup)
        function setupClass(testCase)

            % Use a fixture to create a temporary working directory
            testCase.applyFixture(matlab.unittest.fixtures.WorkingFolderFixture);
        end
    end
    methods (Test)
        function testcheckConstraint(testCase)
            pname = 'vectordata';
            name = 'col1';
            namedprops = struct('col1', 'double');
            constrained = {'types.hdmf_common.VectorData'};
            val = [];
            
            % Should pass with no error
            types.util.checkConstraint(pname, name, namedprops, constrained, val)
            
            val = 10;
            types.util.checkConstraint(pname, name, namedprops, constrained, val)

            val = {10};
            testCase.verifyError(...
                @(varargin) types.util.checkConstraint(pname, name, namedprops, constrained, val), ...
                'NWB:TypeCorrection:InvalidConversion')

            % Verify that checkConstraint fails if constrained is not a
            % char describing a type (test unexpected error)
            constrained = {false};
            namedprops = struct.empty;
            testCase.verifyError(...
                @(varargin) types.util.checkConstraint(pname, name, namedprops, constrained, val), ...
                'MATLAB:string:MustBeStringScalarOrCharacterVector')
        end

        function testCheckDimsWithValidSize(testCase)
            types.util.checkDims([3,5], {[3,5]})
            testCase.verifyTrue(true)
        end

        function testCheckDimsWithInvalidSize(testCase)
            testCase.verifyError(...
                @(varargin) types.util.checkDims([3,5], {[1,10,4]}), ...
                'NWB:CheckDims:InvalidDimensions' )
        end

        function testCheckDtype(testCase)
            % Example that triggers a block for non-scalar structs in
            % compound data processing case. %Todo: simplify
            ccss = types.core.VoltageClampStimulusSeries( ...
                'data', [1, 2, 3, 4, 5] );
            vcs = types.core.VoltageClampSeries( ...
                'data', [0.1, 0.2, 0.3, 0.4, 0.5] );

            stimuli = types.core.IntracellularStimuliTable( ...
                'colnames', {'stimulus'}, ...
                'id', types.hdmf_common.ElementIdentifiers( ...
                    'data', int64([0, 1, 2]) ...
                ), ...
                'stimulus', types.core.TimeSeriesReferenceVectorData( ...
                    'data', struct( ...
                        'idx_start', {0, 1, -1}, ...
                        'count', {5, 3, -1}, ...
                        'timeseries', { ...
                            types.untyped.ObjectView(ccss), ...
                            types.untyped.ObjectView(ccss), ...
                            types.untyped.ObjectView(vcs) ...
                        } ...
                    )...
                )...
            );
            testCase.verifyClass(stimuli, 'types.core.IntracellularStimuliTable')
        end

        function testParseConstrainedAppendMode(testCase)

            columnA = types.hdmf_common.VectorData( ...
                'description', 'first column', ...
                'data', rand(10,1) ...
            );
            
            % 1D column
            idCol = types.hdmf_common.ElementIdentifiers('data', int64(0:9)');
            
            % Create table
            dynamicTable = types.hdmf_common.DynamicTable(...
                            'description', 'test dynamic table column',...
                            'colnames', {'colA'}, ...
                            'colA', columnA, ...
                            'id', idCol ...     
            );
            
            columnB = types.hdmf_common.VectorData( ...
                            'description', 'second column', ...
                            'data', rand(10,1) ...
            );
            
                    
            [vectordata, ~] = types.util.parseConstrained(dynamicTable, ...
                'vectordata', 'types.hdmf_common.VectorData', ...
                'colB', columnB );

            testCase.verifyEqual(vectordata.keys, {'colA', 'colB'})
            testCase.verifyEqual(vectordata.get('colA').data, columnA.data)
            testCase.verifyEqual(vectordata.get('colB').data, columnB.data)
        end
    
        function testCorrectType(testCase)
            testCase.verifyEqual(types.util.correctType('5', 'double'), 5)
            testCase.verifyEqual(types.util.correctType(uint8(5), 'int32'), int32(5))
            testCase.verifyEqual(types.util.correctType(uint32(5), 'int32'), int64(5))

            testCase.verifyWarning(...
                @(varargin) types.util.correctType('5i', 'double'), ...
                'NWB:TypeCorrection:DataLoss')
        end
    end
end