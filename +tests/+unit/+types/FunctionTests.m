classdef FunctionTests < matlab.unittest.TestCase
% FunctionTests - Unit test for functions in +types namespace.
    methods (TestClassSetup)
        function setupClass(testCase)
            % Get the root path of the matnwb repository
            rootPath = misc.getMatnwbDir();

            % Use a fixture to add the folder to the search path
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(rootPath));

            % Use a fixture to create a temporary working directory
            testCase.applyFixture(matlab.unittest.fixtures.WorkingFolderFixture);

            generateCore('savedir', '.')
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
    end 
end