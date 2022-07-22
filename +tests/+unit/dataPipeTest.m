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

function data = createData(dataType, size)
data = randi(intmax(dataType), size, dataType);
end
