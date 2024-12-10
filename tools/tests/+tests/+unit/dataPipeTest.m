function tests = dataPipeTest()
    tests = functiontests(localfunctions);
end

function setupOnce(testCase)
    rootPath = fullfile(fileparts(mfilename('fullpath')), '..', '..');
    testCase.applyFixture(matlab.unittest.fixtures.PathFixture(rootPath));
end

function setup(testCase)
    testCase.applyFixture(matlab.unittest.fixtures.WorkingFolderFixture);
    generateCore('savedir', '.');
    rehash();
end

function testInit(testCase)
    import types.untyped.datapipe.*;
    import matlab.unittest.fixtures.SuppressedWarningsFixture
    %testCase.applyFixture(SuppressedWarningsFixture('NWB:DataPipeTest:Debug'))

    warnDebugId = 'NWB:DataPipeTest:Debug';
    warning('off', warnDebugId);
    warning(warnDebugId, '');
    
    %% extra data type
    data = rand(100, 1);
    % types.untyped.DataPipe('data', data, 'dataType', 'double');
    % [~,lastId] = lastwarn();
    % testCase.verifyEqual(lastId, 'NWB:DataPipe:RedundantDataType');

    testCase.verifyWarning(...
        @(varargin) types.untyped.DataPipe('data', data, 'dataType', 'double'), ...
        'NWB:DataPipe:RedundantDataType')
    
    warning(warnDebugId, '');
    
    %% compressionLevel and hasShuffle ignored if filters is provided
    pipe = types.untyped.DataPipe('data', data ...
        , 'compressionLevel', 3 ...
        , 'hasShuffle', true ...
        , 'filters', [properties.Compression(4)]);
    [~,lastId] = lastwarn();
    testCase.verifyEqual(lastId, 'NWB:DataPipe:FilterOverride');
    testCase.verifyEqual(pipe.compressionLevel, 4);
    testCase.verifyTrue(~pipe.hasShuffle);
    pipe.compressionLevel = 2;
    testCase.verifyEqual(pipe.compressionLevel, 2);
    pipe.hasShuffle = true;
    testCase.verifyTrue(pipe.hasShuffle);
    
    warning(warnDebugId, '');
    
    %% extraneous properties from file
    filename = 'testInit.h5';
    datasetName = '/test_data';
    fid = H5F.create(filename);
    pipe.export(fid, datasetName, {});
    H5F.close(fid);
    
    testCase.verifyWarning(...
        @(varargin) types.untyped.DataPipe('filename', filename, 'path', datasetName, 'dataType', 'double'), ...
        'NWB:DataPipe:UnusedArguments')

    testCase.applyFixture(SuppressedWarningsFixture('NWB:DataPipe:UnusedArguments'))
    pipe = types.untyped.DataPipe('filename', filename, 'path', datasetName, 'dataType', 'double');
    % [~,lastId] = lastwarn();
    % testCase.verifyEqual(lastId, 'NWB:DataPipe:UnusedArguments');
    testCase.verifyEqual(pipe.compressionLevel, 2);
    testCase.verifyTrue(pipe.hasShuffle);
    
    % cleanup
    warning('on', warnDebugId);
end

function testIndex(testCase)
    filename = 'testIndexing.h5';
    name = '/test_data';
    
    data = rand(100, 100, 100);
    Pipe = types.untyped.DataPipe('data', data);
    
    testCase.verifyEqual(Pipe(:), data(:));
    testCase.verifyEqual(Pipe(:,:,1), data(:,:,1));
    
    fid = H5F.create(filename);
    Pipe.export(fid, name, {}); % bind the pipe.
    H5F.close(fid);
    
    testCase.verifyEqual(Pipe(:), data(:));
    testCase.verifyEqual(Pipe(:,:,1), data(:,:,1));
end

function testAppend(testCase)
    filename = 'testIterativeWrite.h5';
    
    Pipe = types.untyped.DataPipe(...
        'maxSize', [10 13 15],...
        'axis', 3,...
        'chunkSize', [10 13 1],...
        'dataType', 'uint8',...
        'compressionLevel', 5);
    
    OneDimensionPipe = types.untyped.DataPipe('maxSize', Inf, 'data', [7, 8, 9]);
    
    %% create test file
    fid = H5F.create(filename);
    
    initialData = createData(Pipe.dataType, [10 13 10]);
    Pipe.internal.data = initialData;
    Pipe.export(fid, '/test_data', {}); % bind
    OneDimensionPipe.export(fid, '/test_one_dim_data', {});
    
    H5F.close(fid);
    
    %% append data
    totalLength = 3;
    appendData = zeros([10 13 totalLength], Pipe.dataType);
    for i = 1:totalLength
        appendData(:,:,i) = createData(Pipe.dataType, Pipe.chunkSize);
        Pipe.append(appendData(:,:,i));
    end
    
    for i = 1:totalLength
        OneDimensionPipe.append(rand());
    end
    
    %% verify data
    Pipe = types.untyped.DataPipe('filename', filename, 'path', '/test_data');
    readData = Pipe.load();
    testCase.verifyEqual(readData(:,:,1:10), initialData);
    testCase.verifyEqual(readData(:,:,11:end), appendData);
    
    OneDimensionPipe = types.untyped.DataPipe('filename', filename, 'path', '/test_one_dim_data');
    readData = OneDimensionPipe.load();
    testCase.verifyTrue(isvector(readData));
    testCase.verifyEqual(length(readData), 6);
    testCase.verifyEqual(readData(1:3), [7, 8, 9] .');
end

function testExternalFilters(testCase)
    import types.untyped.datapipe.dynamic.Filter;
    import types.untyped.datapipe.properties.DynamicFilter;
    import types.untyped.datapipe.properties.Shuffle;
    
    % TODO: Why is Filter.LZ4 not part of the exported Pipe, i.e when the
    % Pipe.internal goes from Blueprint to Bound

    testCase.assumeTrue(logical(H5Z.filter_avail(uint32(Filter.LZ4))));
    
    filename = 'testExternalWrite.h5';
    
    Pipe = types.untyped.DataPipe(...
        'maxSize', [10 13 15],...
        'axis', 3,...
        'chunkSize', [10 13 1],...
        'dataType', 'uint8',...
        'filters', [Shuffle() DynamicFilter(Filter.LZ4)]);
    
    OneDimensionPipe = types.untyped.DataPipe('maxSize', Inf, 'data', [7, 8, 9]);
    
    %% create test file
    fid = H5F.create(filename);
    
    initialData = createData(Pipe.dataType, [10 13 10]);
    Pipe.internal.data = initialData;
    Pipe.export(fid, '/test_data', {}); % bind
    OneDimensionPipe.export(fid, '/test_one_dim_data', {});
    
    H5F.close(fid);

    %% append data
    totalLength = 3;
    appendData = zeros([10 13 totalLength], Pipe.dataType);
    for i = 1:totalLength
        appendData(:,:,i) = createData(Pipe.dataType, Pipe.chunkSize);
        Pipe.append(appendData(:,:,i));
    end
    
    for i = 1:totalLength
        OneDimensionPipe.append(rand());
    end
    
    %% verify data
    Pipe = types.untyped.DataPipe('filename', filename, 'path', '/test_data');
    readData = Pipe.load();
    testCase.verifyEqual(readData(:,:,1:10), initialData);
    testCase.verifyEqual(readData(:,:,11:end), appendData);
    
    OneDimensionPipe = types.untyped.DataPipe('filename', filename, 'path', '/test_one_dim_data');
    readData = OneDimensionPipe.load();
    testCase.verifyTrue(isvector(readData));
    testCase.verifyEqual(length(readData), 6);
    testCase.verifyEqual(readData(1:3), [7, 8, 9] .');
end

function testBoundPipe(testCase)
    import types.untyped.*;
    filename = 'bound.h5';
    dsName = '/test_data';
    debugId = 'NWB:DataPipe:Debug';
    warning('off', debugId);
    
    %% full pipe case
    fullpipe = DataPipe('data', rand(100, 1));
    
    fid = H5F.create(filename);
    fullpipe.export(fid, dsName, {});
    H5F.close(fid);
    DataPipe('filename', filename, 'path', dsName);
    delete(filename);
    
    %% multi-axis case
    data = rand(100, 1);
    maxSize = [200, 2];
    multipipe = DataPipe('data', data, 'maxSize', maxSize);
    fid = H5F.create(filename);
    try
        % this should be impossible normally.
        multipipe.export(fid, dsName, {});
    catch ME
        testCase.verifyEqual(ME.identifier, 'NWB:BoundPipe:InvalidSize');
    end
    H5F.close(fid);
    delete(filename);
    
    fid = H5F.create(filename);
    rank = length(maxSize);
    dcpl = H5P.create('H5P_DATASET_CREATE');
    H5P.set_chunk(dcpl, datapipe.guessChunkSize(class(data), maxSize));
    did = H5D.create( ...
        fid, dsName ...
        , io.getBaseType(class(data)) ...
        , H5S.create_simple(rank, fliplr(size(data)), fliplr(maxSize)) ...
        , 'H5P_DEFAULT', dcpl, 'H5P_DEFAULT');
    H5D.write(did, 'H5ML_DEFAULT', 'H5S_ALL', 'H5S_ALL', 'H5P_DEFAULT', data);
    H5D.close(did);
    H5F.close(fid);
    
    warning(debugId, '');
    multipipe = DataPipe('filename', filename, 'path', dsName);
    [~,lastId] = lastwarn();
    testCase.verifyEqual(lastId, 'NWB:BoundPipe:InvalidPipeShape');
    
    try
        multipipe.append(rand(10, 2, 10));
    catch ME
        testCase.verifyEqual(ME.identifier, 'NWB:BoundPipe:InvalidDataShape');
    end
    
    delete(filename);
    
    %% not chunked behavior
    fid = H5F.create(filename);
    did = H5D.create( ...
        fid, dsName ...
        , io.getBaseType(class(data)) ...
        , H5S.create_simple(rank, fliplr(size(data)), fliplr(size(data))) ...
        , 'H5P_DEFAULT', 'H5P_DEFAULT', 'H5P_DEFAULT');
    H5D.write(did, 'H5ML_DEFAULT', 'H5S_ALL', 'H5S_ALL', 'H5P_DEFAULT', data);
    H5D.close(did);
    H5F.close(fid);
    warning(debugId, '');
    nochunk = DataPipe('filename', filename, 'path', dsName);
    [~,lastId] = lastwarn();
    testCase.verifyEqual(lastId, 'NWB:BoundPipe:NotChunked');
    nochunk.load(); % test still loadable.
    
    %% cleanup
    warning('on', debugId);
end

function testConfigurationFromData(testCase)
    conf = types.untyped.datapipe.Configuration.fromData(zeros(10,10), 1);
    testCase.verifyClass(conf, 'types.untyped.datapipe.Configuration')
end

function testPropertySetGet(testCase)
    data = rand(100, 1);
    pipe = types.untyped.DataPipe('data', data);
    
    pipe.axis = 1;
    testCase.verifyEqual(pipe.axis, 1)

    pipe.offset = 4;
    testCase.verifyEqual(pipe.offset, 4)

    pipe.dataType = 'double';
    testCase.verifyEqual(pipe.dataType, 'double')

    pipe.chunkSize = 10;
    testCase.verifyEqual(pipe.chunkSize, 10)

    pipe.compressionLevel = -1;
    % Todo: make verification

    pipe.hasShuffle = false;
    testCase.verifyFalse(pipe.hasShuffle)

    pipe.hasShuffle = true;
    testCase.verifyTrue(pipe.hasShuffle)
end

function testAppendVectorToBlueprintPipe(testCase)
    % Column vector:
    data = rand(10, 1);
    pipe = types.untyped.DataPipe('data', data);

    pipe.append([1;2]);
    newData = pipe.load();
    testCase.verifyEqual(newData, cat(1, data, [1;2]))

    testCase.verifyError(@(X) pipe.append([1,2]), 'MATLAB:catenate:dimensionMismatch')

    % Row vector:
    data = rand(1, 10);
    pipe = types.untyped.DataPipe('data', data);

    pipe.append([1,2]);
    newData = pipe.load();
    testCase.verifyEqual(newData, cat(2, data, [1,2]))

    testCase.verifyError(@(X) pipe.append([1;2]), 'MATLAB:catenate:dimensionMismatch')
end

function testSubsrefWithNonScalarSubs(testCase)
    data = rand(100, 1);
    pipe = types.untyped.DataPipe('data', data);
    
    % This syntax should not be supported. Not clear what a valid
    % non-scalar subsref would be...
    subData = pipe{1:10}(1:5); 
    testCase.verifyEqual(subData, data(1:5))
end

function testOverrideBoundPipeProperties(testCase)
    import matlab.unittest.fixtures.SuppressedWarningsFixture
    testCase.applyFixture(SuppressedWarningsFixture('NWB:DataPipe:UnusedArguments'))
    
    data = rand(10, 1);
    pipe = types.untyped.DataPipe('data', data);
    
    filename = 'testInit.h5';
    datasetName = '/test_data';
    fid = H5F.create(filename);
    pipe.export(fid, datasetName, {});
    H5F.close(fid);
        
    loadedPipe = types.untyped.DataPipe('filename', filename, 'path', datasetName, 'dataType', 'double');
    
    % Using verifyError did not work for the following statements, i.e this:
    % testCase.verifyError(@(x) eval('loadedPipe.chunkSize = 2'), 'NWB:BoundPipe:CannotSetPipeProperty') %#ok<EVLCS>
    % fails with the following error: Attempt to add "loadedPipe" to a static workspace.
    try
        loadedPipe.chunkSize = 2;
    catch ME
        testCase.verifyEqual(ME.identifier,  'NWB:BoundPipe:CannotSetPipeProperty')
    end
    
    try
        loadedPipe.hasShuffle = false;
    catch ME
        testCase.verifyEqual(ME.identifier,  'NWB:BoundPipe:CannotSetPipeProperty')
    end

end

function testDynamicFilterIsInDatasetCreationPropertyList(testCase)
    import types.untyped.datapipe.dynamic.Filter;
    import types.untyped.datapipe.properties.DynamicFilter;

    dcpl = H5P.create('H5P_DATASET_CREATE');
    dynamicFilter = DynamicFilter(Filter.LZ4);

    tf = dynamicFilter.isInDcpl(dcpl);
    testCase.verifyFalse(tf)

    % Add filter
    dynamicFilter.addTo(dcpl)
    tf = dynamicFilter.isInDcpl(dcpl);
    testCase.verifyTrue(tf)
end

function data = createData(dataType, size)
    data = randi(intmax(dataType), size, dataType);
end

