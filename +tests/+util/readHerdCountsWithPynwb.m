function counts = readHerdCountsWithPynwb(nwbFilename)
% readHerdCountsWithPynwb - Read a file with pynwb and count what its HERD holds.
%
% counts is a struct with the number of keys, entities and objects the
% file's HERD holds, and the number of entities pynwb resolves for the
% file's subject.
%
% The direct py.* calls live in this function rather than in a test method
% so that a MATLAB release whose Python is unsupported can still construct
% the test suite: the unittest framework fails a whole test file whose
% py.* references cannot be resolved, dropping every test in it.
    [pyNwbFile, pyNwbFileCleanup] = tests.util.readWithPynwb(nwbFilename); %#ok<ASGLU>
    pyHerd = pyNwbFile.get_external_resources();
    counts = struct( ...
        'numKeys', double(py.len(pyHerd.keys)), ...
        'numEntities', double(py.len(pyHerd.entities)), ...
        'numObjects', double(py.len(pyHerd.objects)), ...
        'numSubjectEntities', double(py.len( ...
            pyHerd.get_object_entities(pyargs('container', pyNwbFile.subject)))));
end
