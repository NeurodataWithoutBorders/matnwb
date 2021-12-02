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
name = '/test_data';

Pipe = types.untyped.DataPipe(...
    'maxSize', [10 13 15],...
    'axis', 3,...
    'chunkSize', [10 13 1],...
    'dataType', 'uint8',...
    'compressionLevel', 5);

%% create test file
fid = H5F.create(filename);

initialData = createData(Pipe.dataType, [10 13 10]);
Pipe.internal.data = initialData;
Pipe.export(fid, name, {}); % bind

H5F.close(fid);

%% append data
totalLength = 3;
appendData = zeros([10 13 totalLength], Pipe.dataType);
for i = 1:totalLength
    appendData(:,:,i) = createData(Pipe.dataType, Pipe.chunkSize);
    Pipe.append(appendData(:,:,i));
end

%% verify data
readData = Pipe.load();
testCase.verifyEqual(readData(:,:,1:10), initialData);
testCase.verifyEqual(readData(:,:,11:end), appendData);
end

function data = createData(dataType, size)
data = randi(intmax(dataType), size, dataType);
end
