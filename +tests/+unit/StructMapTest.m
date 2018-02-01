function tests = StructMapTest()
tests = functiontests(localfunctions);
end

function setupOnce(testCase)
rootPath = fullfile(fileparts(mfilename('fullpath')), '..', '..');
testCase.applyFixture(matlab.unittest.fixtures.PathFixture(rootPath));
end

function testStructMapConstructor(testCase)
sm = util.StructMap();
testCase.verifyTrue(isempty(sm));
end

function testStructMapConstructorWithKVSet(testCase)
sm = util.StructMap({'a','b'}, {3,4});
testCase.verifyEqual(sm.a, 3);
testCase.verifyEqual(sm.b, 4);
end

function testStructMapConstructorWithStruct(testCase)
s.a = 3;
s.b = 4;
sm = util.StructMap(s);
testCase.verifyEqual(sm.a, 3);
testCase.verifyEqual(sm.b, 4);
end

function testStructMapDotSubref(testCase)
sm = util.StructMap('fld', 'val');
testCase.verifyEqual(sm.fld, 'val');
testCase.verifyEqual(sm.map('fld'), 'val');
end

function testStructMapNestedDotSubsref(testCase)
sm = util.StructMap('sm2', util.StructMap('a',3));
testCase.verifyEqual(sm.sm2.a, 3);
testCase.verifyEqual(sm.map('sm2').a, 3);
testCase.verifyEqual(sm.map('sm2').map('a'), 3);
testCase.verifyEqual(sm.sm2.map('a'), 3);
end

function testStructMapArrayDotSubsref(testCase)
sm1 = util.StructMap('a', 1);
sm2 = util.StructMap('a', 2);
arr = [sm1 sm2];
testCase.verifyEqual(arr(1).a, 1);
testCase.verifyEqual(arr(1).map('a'), 1);
testCase.verifyEqual(arr(2).a, 2);
testCase.verifyEqual(arr(2).map('a'), 2);
end

function testStructMapCellArrayDotSubsref(testCase)
sm1 = util.StructMap('a', 1);
sm2 = util.StructMap('a', 2);
arr = {sm1 sm2};
testCase.verifyEqual(arr{1}.a, 1);
testCase.verifyEqual(arr{1}.map('a'), 1);
testCase.verifyEqual(arr{2}.a, 2);
testCase.verifyEqual(arr{2}.map('a'), 2);
end

function testStructMapDotSubsasgn(testCase)
sm = util.StructMap();
sm.fld1 = 'val1';
testCase.verifyEqual(sm.fld1, 'val1');
sm.map('fld2') = 'val2';
testCase.verifyEqual(sm.fld2, 'val2');
end

function testStructMapFieldNames(testCase)
sm = util.StructMap({'a','b'}, {3,4});
testCase.verifyTrue(all(ismember({'a','b'}, fieldnames(sm))));
end

function testStructMapRemoveField(testCase)
sm = util.StructMap({'a','b'}, {3,4});
testCase.verifyTrue(isfield(sm, 'a'));
testCase.verifyTrue(isfield(sm, 'b'));
sm = rmfield(sm, 'a');
testCase.verifyFalse(isfield(sm, 'a'));
testCase.verifyTrue(isfield(sm, 'b'));
end
