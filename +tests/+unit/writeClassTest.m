function tests = writeClassTest()
tests = functiontests(localfunctions);
end

function setupOnce(testCase)
rootPath = fullfile(fileparts(mfilename('fullpath')), '..', '..');
testCase.applyFixture(matlab.unittest.fixtures.PathFixture(rootPath));
end

function setup(testCase)
testCase.applyFixture(matlab.unittest.fixtures.WorkingFolderFixture);
end

%% Write class (i.e. top-level group) tests

function testWriteClassToPackage(testCase)
file.writeClass('MyClass', classStruct(), 'mypack.mysubpack'); rehash;
testCase.fatalAssertEqual(exist('mypack.mysubpack.MyClass', 'class'), 8, ...
  'Class file was not written');
try
  mypack.mysubpack.MyClass();
catch e
  testCase.fatalAssertFail(['Class cannot be instantiated: ' e.message]);
end
end

function testWriteClassWithDefaultName(testCase)
testCase.assumeFail('writeClass does not yet use classStruct.default_name');
cs = classStruct('default_name', 'MyName');
file.writeClass('MyClass', cs, 'testpack'); rehash;
mc = testpack.MyClass();
testCase.verifyEqual(mc.name, cs.default_name, ...
  'The value of default_name was not assigned to the name property');
end

function testWriteClassWithDoc(testCase)
cs = classStruct('doc', 'A string describing the group');
file.writeClass('TestClass', cs, 'testpack'); rehash;
text = help('testpack.TestClass');
testCase.verifyTrue(contains(text, cs.doc), ...
  'Class does not contain doc as class help text');
end

function testWriteClassWithNeurodataTypeInc(testCase)
file.writeClass('TestSuperClass', classStruct(), 'testpack');
cs = classStruct('neurodata_type_inc', 'TestSuperClass', 'namespace', 'testpack');
file.writeClass('TestClass', cs, 'testpack'); rehash;
s = superclasses('testpack.TestClass');
testCase.verifyTrue(any(strcmp(s, 'testpack.TestSuperClass')), ...
  'The class defined by neurodata_type_inc is not a superclass');
end

function testWriteClassWithQuantity(testCase)
testCase.assumeFail('writeClass does not yet use classStruct.quantity');
cs = classStruct('quantity', '+');
testCase.verifyFail('Not yet implemented');
end

function testWriteClassWithLinkable(testCase)
testCase.assumeFail('writeClass does not yet use classStruct.linkable');
cs = classStruct('linkable', 'true');
testCase.verifyFail('Not yet implemented');
end

function testWriteClassWithAttributes(testCase)
cs = classStruct('attributes', struct( ...
  'a1', attrStruct(), ...
  'a2', attrStruct()));
file.writeClass('TestClass', cs, 'testpack'); rehash;
mc = testpack.TestClass();
testCase.verifyTrue(all(ismember({'a1', 'a2'}, properties(mc))), ...
  'An attribute was not added as a property to the class');
end

function testWriteClassWithLinks(testCase)
cs = classStruct('links', struct( ...
  'l1', linkStruct(), ...
  'l2', linkStruct()));
file.writeClass('TestClass', cs, 'testpack'); rehash;
mc = testpack.TestClass();
testCase.verifyTrue(all(ismember({'l1', 'l2'}, properties(mc))), ...
  'A link was not added as a property to the class');
end

function testWriteClassWithDatasets(testCase)
cs = classStruct('datasets', struct( ...
  'd1', datasetStruct(), ...
  'd2', datasetStruct()));
file.writeClass('TestClass', cs, 'testpack'); rehash;
mc = testpack.TestClass();
testCase.verifyTrue(all(ismember({'d1', 'd2'}, properties(mc))), ...
  'A dataset was not added as a property to the class');
end

function testWriteClassWithGroups(testCase)
cs = classStruct('groups', struct( ...
  'g1', groupStruct(), ...
  'g2', groupStruct()));
file.writeClass('TestClass', cs, 'testpack'); rehash;
mc = testpack.TestClass();
testCase.verifyTrue(all(ismember({'g1', 'g2'}, properties(mc))), ...
  'A group was not added as a property to the class');
end

function testWriteClassWithDuplicatePropertyNamesThrows(testCase)
cs = classStruct( ...
  'groups', struct('dup', groupStruct()), ...
  'datasets', struct('dup', datasetStruct()));
testCase.verifyError(@()file.writeClass('TestClass', cs, 'testpack'), ?MException, ...
  'A group and dataset with the same name were written without error');
end

function testWriteClassConstructorThrowsOnUnknownArgument(testCase)
testCase.assumeFail('Class constructor does not currently throw with unknown argument');
file.writeClass('MyClass', classStruct(), 'testpack'); rehash;
testCase.verifyError(@()testpack.MyClass('unknown_key', 5), ?MException);
end

%% Write attribute tests

function testWriteAttributeWithDoc(testCase)
as = attrStruct('doc', 'A string describing the attribute');
cs = classStruct('attributes', struct('testAttr', as));
file.writeClass('TestClass', cs, 'testpack'); rehash;
text = help('testpack.TestClass.testAttr');
testCase.verifyTrue(contains(text, as.doc), ...
  'Attribute property does not contain doc as property help text');
end

function testWriteAttributeWithStringDtype(testCase)
as = attrStruct('dtype', 'string');
cs = classStruct('attributes', struct('testAttr', as));
file.writeClass('TestClass', cs, 'testpack'); rehash;
mc = testpack.TestClass();
mc.testAttr = {''};
testCase.verifyEqual(mc.testAttr, {''}, ...
  'Attribute was not assigned an empty string');
mc.testAttr = {'test string'};
testCase.verifyEqual(mc.testAttr, {'test string'}, ...
  'Attribute was not assigned a string');
testCase.verifyError(@()set(mc, 'testAttr', 123), ?MException, ...
  'Attribute with dtype string did not throw and error when passed type double');
end

function testWriteAttributeWithIntegerDtype(testCase)
dtype2mtype = struct( ...
  'int8', 'int8', ...
  'uint8', 'uint8', ...
  'int16', 'int16', ...
  'uint16', 'uint16', ...
  'int32', 'int32', ...
  'uint32', 'uint32', ...
  'int64', 'int64', ...
  'uint64', 'uint64');
dtypes = fieldnames(dtype2mtype);
for i = 1:numel(dtypes)
  dtype = dtypes{i};
  mtype = dtype2mtype.(dtype);
  as = attrStruct('dtype', dtype);
  cs = classStruct('attributes', struct('testAttr', as));
  file.writeClass('TestClass', cs, 'testpack'); rehash;
  mc = testpack.TestClass();
  mc.testAttr = intmin(mtype);
  testCase.verifyEqual(mc.testAttr, intmin(mtype), ...
    ['Attribute was not assigned min value of type ' mtype]);
  mc.testAttr = intmax(mtype);
  testCase.verifyEqual(mc.testAttr, intmax(mtype), ...
    ['Attribute was not assigned max value of type ' mtype]);
  w = warning('off');
  mc.testAttr = double(intmax(mtype))+1;
  warning(w);
  testCase.verifyTrue(isa(mc.testAttr, mtype), ...
    ['Attribute with dtype ' dtype ' was set to type other than ' mtype]);
end
end

function testWriteAttributeWithRealDtype(testCase)
dtype2mtype = struct( ...
  'single', 'single', ...
  'double', 'double');
dtypes = fieldnames(dtype2mtype);
for i = 1:numel(dtypes)
  dtype = dtypes{i};
  mtype = dtype2mtype.(dtype);
  as = attrStruct('dtype', dtype);
  cs = classStruct('attributes', struct('testAttr', as));
  file.writeClass('TestClass', cs, 'testpack'); rehash;
  mc = testpack.TestClass();
  mc.testAttr = realmin(mtype);
  testCase.verifyEqual(mc.testAttr, realmin(mtype), ...
    ['Attribute was not assigned min value of type ' mtype]);
  mc.testAttr = realmax(mtype);
  testCase.verifyEqual(mc.testAttr, realmax(mtype), ...
    ['Attribute was not assigned max value of type ' mtype]);
  w = warning('off');
  mc.testAttr = double(realmax(mtype))+1;
  warning(w);
  testCase.verifyTrue(isa(mc.testAttr, mtype), ...
    ['Attribute with dtype ' dtype ' was set to type other than ' mtype]);
end
end

function testWriteAttributeWithDims(testCase)
testCase.assumeFail('writeClass does not yet use attrStruct.dims');
as = attrStruct('dims', {{'dim1', 'dim2'}}, 'dtype', 'int32');
testCase.verifyFail('Not yet implemented');
end

function testWriteAttributeWithShape(testCase)
testCase.assumeFail('writeClass does not yet use attrStruct.shape');
as = attrStruct('shape', {{'2', '3'}}, 'dtype', 'int32');
testCase.verifyFail('Not yet implemented');
end

function testWriteAttributeWithRequired(testCase)
testCase.assumeFail('writeClass does not yet use attrStruct.required');
as = attrStruct('required', 'true');
testCase.verifyFail('Not yet implemented');
end

function testWriteAttributeWithValue(testCase)
as = attrStruct('value', '52', 'dtype', 'int32');
cs = classStruct('attributes', struct('testAttr', as));
file.writeClass('TestClass', cs, 'testpack'); rehash;
mc = testpack.TestClass();
testCase.verifyEqual(mc.testAttr, int32(52), ...
  'The value was not assigned to the attribute property');
testCase.verifyError(@()set(mc, 'testAttr', int32(12)), ?MException, ...
  'The value was expected to be a constant but it allowed assigning a new value');
end

function testWriteAttributeWithDefaultValue(testCase)
as = attrStruct('default_value', '52', 'dtype', 'int32');
cs = classStruct('attributes', struct('testAttr', as));
file.writeClass('TestClass', cs, 'testpack'); rehash;
mc = testpack.TestClass();
testCase.verifyEqual(mc.testAttr, int32(52), ...
  'The default_value was not assigned to the attribute property');
end

%% Write link tests

function testWriteLinkWithTargetType(testCase)
testCase.assumeFail('writeClass does not yet use linkStruct.target_type');
ls = linkStruct('target_type', 'TestTargetType');
testCase.verifyFail('Not yet implemented');
end

function testWriteLinkWithDoc(testCase)
ls = linkStruct('doc', 'A string describing the link');
cs = classStruct('links', struct('testLink', ls));
file.writeClass('TestClass', cs, 'testpack'); rehash;
text = help('testpack.TestClass.testLink');
testCase.verifyTrue(contains(text, ls.doc), ...
  'Link property does not contain doc as property help text');
end

%% Write dataset tests

function testWriteDatasetWithDefaultName(testCase)
testCase.assumeFail('writeClass does not yet use datasetStruct.default_name');
ds = datasetStruct('default_name', 'MyName');
testCase.verifyFail('Not yet implemented');
end

function testWriteDatasetWithDoc(testCase)
ds = datasetStruct('doc', 'A string describing the dataset');
cs = classStruct('datasets', struct('testDataset', ds));
file.writeClass('TestClass', cs, 'testpack'); rehash;
text = help('testpack.TestClass.testDataset');
testCase.verifyTrue(contains(text, ds.doc), ...
  'Dataset property does not contain doc as property help text');
end

function testWriteDatasetWithNeurodataTypeInc(testCase)
testCase.assumeFail('writeClass does not yet use datasetStruct.neurodata_type_inc');
ds = datasetStruct('neurodata_type_inc', 'TestSuperClass');
testCase.verifyFail('Not yet implemented');
end

function testWriteDatasetWithQuantity(testCase)
testCase.assumeFail('writeClass does not yet use datasetStruct.quantity');
ds = datasetStruct('quantity', '+');
testCase.verifyFail('Not yet implemented');
end

function testWriteDatasetWithLinkable(testCase)
testCase.assumeFail('writeClass does not yet use datasetStruct.linkable');
ds = datasetStruct('linkable', 'true');
testCase.verifyFail('Not yet implemented');
end

function testWriteDatasetWithStringDtype(testCase)
ds = datasetStruct('dtype', 'string');
cs = classStruct('datasets', struct('testDataset', ds));
file.writeClass('TestClass', cs, 'testpack'); rehash;
mc = testpack.TestClass();
mc.testDataset = {''};
testCase.verifyEqual(mc.testDataset, {''}, ...
  'Dataset was not assigned an empty string');
mc.testDataset = {'test string'};
testCase.verifyEqual(mc.testDataset, {'test string'}, ...
  'Dataset was not assigned a string');
testCase.verifyError(@()set(mc, 'testDataset', 123), ?MException, ...
  'Dataset with dtype string did not throw and error when passed type double');
end

function testWriteDatasetWithIntegerDtype(testCase)
dtype2mtype = struct( ...
  'int8', 'int8', ...
  'uint8', 'uint8', ...
  'int16', 'int16', ...
  'uint16', 'uint16', ...
  'int32', 'int32', ...
  'uint32', 'uint32', ...
  'int64', 'int64', ...
  'uint64', 'uint64');
dtypes = fieldnames(dtype2mtype);
for i = 1:numel(dtypes)
  dtype = dtypes{i};
  mtype = dtype2mtype.(dtype);
  as = datasetStruct('dtype', dtype);
  cs = classStruct('datasets', struct('testDataset', as));
  file.writeClass('TestClass', cs, 'testpack'); rehash;
  mc = testpack.TestClass();
  mc.testDataset = intmin(mtype);
  testCase.verifyEqual(mc.testDataset, intmin(mtype), ...
    ['Dataset was not assigned min value of type ' mtype]);
  mc.testDataset = intmax(mtype);
  testCase.verifyEqual(mc.testDataset, intmax(mtype), ...
    ['Dataset was not assigned max value of type ' mtype]);
  w = warning('off');
  mc.testDataset = double(intmax(mtype))+1;
  warning(w);
  testCase.verifyTrue(isa(mc.testDataset, mtype), ...
    ['Dataset with dtype ' dtype ' was set to type other than ' mtype]);
end
end

function testWriteDatasetWithRealDtype(testCase)
dtype2mtype = struct( ...
  'single', 'single', ...
  'double', 'double');
dtypes = fieldnames(dtype2mtype);
for i = 1:numel(dtypes)
  dtype = dtypes{i};
  mtype = dtype2mtype.(dtype);
  as = datasetStruct('dtype', dtype);
  cs = classStruct('datasets', struct('testDataset', as));
  file.writeClass('TestClass', cs, 'testpack'); rehash;
  mc = testpack.TestClass();
  mc.testDataset = realmin(mtype);
  testCase.verifyEqual(mc.testDataset, realmin(mtype), ...
    ['Dataset was not assigned min value of type ' mtype]);
  mc.testDataset = realmax(mtype);
  testCase.verifyEqual(mc.testDataset, realmax(mtype), ...
    ['Dataset was not assigned max value of type ' mtype]);
  w = warning('off');
  mc.testDataset = double(realmax(mtype))+1;
  warning(w);
  testCase.verifyTrue(isa(mc.testDataset, mtype), ...
    ['Dataset with dtype ' dtype ' was set to type other than ' mtype]);
end
end

function testWriteDatasetWithDims(testCase)
testCase.assumeFail('writeClass does not yet use datasetStruct.dims');
ds = datasetStruct('dims', {{'dim1', 'dim2'}}, 'dtype', 'int32');
testCase.verifyFail('Not yet implemented');
end

function testWriteDatasetWithShape(testCase)
ds = datasetStruct('shape', {{'1','2','3'}}, 'dtype', 'double');
cs = classStruct('datasets', struct('testDataset', ds));
file.writeClass('TestClass', cs, 'testpack'); rehash;
mc = testpack.TestClass();
mc.testDataset = ones(1,2,3);
testCase.verifyEqual(mc.testDataset, ones(1,2,3), ...
  'Dataset with three dimensional shape could not be set to three dimensional matrix');
testCase.verifyError(@()set(mc, 'testDataset', 1), ?MException, ...
  'Dataset with three dimensional shape did not throw when set to scalar value');
testCase.verifyError(@()set(mc, 'testDataset', ones(1,2,3,4)), ?MException, ...
  'Dataset with three dimensional shape did not error when set to four dimensional matrix');
end

function testWriteDatasetWithNullShape(testCase)
ds = datasetStruct('shape', {{'null', '3'}}, 'dtype', 'string');
cs = classStruct('datasets', struct('testDataset', ds));
file.writeClass('TestClass', cs, 'testpack'); rehash;
mc = testpack.TestClass();
mc.testDataset = {{'a'},{'b'},{'c'}; {'d'},{'e'},{'f'}};
testCase.verifyEqual(mc.testDataset, [1 2 3], ...
  'Dataset with null shape could not be set to vector');
testCase.verifyError(@()set(mc, 'testDataset', ones(5)), ?MException, ...
  'Dataset with null shape did not error when set to two dimensional matrix');
end

function testWriteDatasetWithMultipleShapes(testCase)
ds = datasetStruct('shape', {{{'1'},{'2','3'}}}, 'dtype', 'double');
cs = classStruct('datasets', struct('testDataset', ds));
file.writeClass('TestClass', cs, 'testpack'); rehash;
mc = testpack.TestClass();
mc.testDataset = 1;
testCase.verifyEqual(mc.testDataset, 1, ...
  'Dataset with one or two dimensional shape could not be set to scalar value');
mc.testDataset = ones(2,3);
testCase.verifyEqual(mc.testDataset, ones(2,3), ...
  'Dataset with one or two dimensional shape could not be set to two dimensional matrix');
testCase.verifyError(@()set(mc, 'testDataset', ones(1,2,3)), ?MException, ...
  'Dataset with one or two dimensional shape did not error when set to three dimensional matrix');
end

function testWriteDatasetWithMultipleNullShapes(testCase)
ds = datasetStruct('shape', {{{'null'},{'null','null'}}}, 'dtype', 'double');
cs = classStruct('datasets', struct('testDataset', ds));
file.writeClass('TestClass', cs, 'testpack'); rehash;
mc = testpack.TestClass();
mc.testDataset = 1;
testCase.verifyEqual(mc.testDataset, 1, ...
  'Dataset with one or two null dimensional shape could not be set to scalar value');
mc.testDataset = ones(2,3);
testCase.verifyEqual(mc.testDataset, ones(2,3), ...
  'Dataset with one or two null dimensional shape could not be set to two dimensional matrix');
testCase.verifyError(@()set(mc, 'testDataset', ones(1,2,3)), ?MException, ...
  'Dataset with one or two null dimensional shape did not error when set to three dimensional matrix');
end

function testWriteDatasetWithAttributes(testCase)
ds = datasetStruct('attributes', struct( ...
  'a1', attrStruct(), ...
  'a2', attrStruct()));
cs = classStruct('datasets', struct('ds', ds));
file.writeClass('TestClass', cs, 'testpack'); rehash;
mc = testpack.TestClass();
testCase.verifyTrue(all(ismember({'ds_a1', 'ds_a2'}, properties(mc))), ...
  'A dataset attribute was not added as a property to the class');
end

%% Write group (sub-groups of top-level group) tests

function testWriteGroupWithDefaultName(testCase)
testCase.assumeFail('writeClass does not yet use groupStruct.default_name');
gs = groupStruct('default_name', 'MyName');
testCase.verifyFail('Not yet implemented');
end

function testWriteGroupWithDoc(testCase)
gs = groupStruct('doc', 'A string describing the group');
cs = classStruct('groups', struct('testGroup', gs));
file.writeClass('TestClass', cs, 'testpack'); rehash;
text = help('testpack.TestClass.testGroup');
testCase.verifyTrue(contains(text, gs.doc), ...
  'Group property does not contain doc as property help text');
end

function testWriteGroupWithNeurodataTypeInc(testCase)
testCase.assumeFail('writeClass does not yet use groupStruct.neurodata_type_inc');
gs = groupStruct('neurodata_type_inc', 'TestSuperClass');
testCase.verifyFail('Not yet implemented');
end

function testWriteGroupWithQuantity(testCase)
testCase.assumeFail('writeClass does not yet use groupStruct.quantity');
gs = groupStruct('quantity', '+');
testCase.verifyFail('Not yet implemented');
end

function testWriteGroupWithLinkable(testCase)
testCase.assumeFail('writeClass does not yet use groupStruct.linkable');
gs = groupStruct('linkable', 'true');
testCase.verifyFail('Not yet implemented');
end

function testWriteGroupWithAttributes(testCase)
testCase.assumeFail('writeClass does not yet use groupStruct.attributes');
gs = groupStruct('attributes', struct( ...
  'a1', attrStruct(), ...
  'a2', attrStruct()));
cs = classStruct('groups', struct('gp', gs));
file.writeClass('TestClass', cs, 'testpack'); rehash;
mc = testpack.TestClass();
testCase.verifyTrue(all(ismember({'gp_a1', 'gp_a2'}, properties(mc))), ...
  'A group attribute was not added as a property to the class');
end

function testWriteGroupWithLinks(testCase)
testCase.assumeFail('writeClass does not yet use groupStruct.links');
gs = groupStruct('links', struct( ...
  'l1', attrStruct(), ...
  'l2', attrStruct()));
testCase.verifyFail('Not yet implemented');
end

function testWriteGroupWithDatasets(testCase)
testCase.assumeFail('writeClass does not yet use groupStruct.datasets');
gs = groupStruct('datasets', struct( ...
  'd1', attrStruct(), ...
  'd2', attrStruct()));
testCase.verifyFail('Not yet implemented');
end

function testWriteGroupWithGroups(testCase)
testCase.assumeFail('writeClass does not yet use groupStruct.groups');
gs = groupStruct('groups', struct( ...
  'g1', attrStruct(), ...
  'g2', attrStruct()));
testCase.verifyFail('Not yet implemented');
end

%% Convenience functions

% Create structs with all necessary fields expected by writeClass
function cs = classStruct(varargin)
cs = baseStruct(varargin{:});
end

function as = attrStruct(varargin)
as = baseStruct(varargin{:});
if ~isfield(as, 'dtype')
  [as(:).dtype] = deal('string');
end
if ~isfield(as, 'inherited')
  [as(:).inherited] = deal(false);
end
end

function ls = linkStruct(varargin)
ls = baseStruct(varargin{:});
end

function ds = datasetStruct(varargin)
ds = baseStruct(varargin{:});
if ~isfield(ds, 'dtype')
  [ds(:).dtype] = deal('string');
end
if ~isfield(ds, 'inherited')
  [ds(:).inherited] = deal(false);
end
end

function gs = groupStruct(varargin)
gs = baseStruct(varargin{:});
if ~isfield(gs, 'inherited')
  [gs(:).inherited] = deal(false);
end
end

function bs = baseStruct(varargin)
bs = struct(varargin{:});
end

function set(obj, name, val)
% Allows setting a property value in an anonymous function for verifyError
obj.(name) = val;
end
