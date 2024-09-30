function validateCodecovSettings()
    sysCommand = sprintf("curl -X POST --data-binary @%s https://codecov.io/validate", ...
        fullfile(misc.getMatnwbDir, '.github', '.codecov.yaml'));
    
    [status, message] = system(sysCommand);

    assert(status == 0, 'Curl command failed')

    assert(contains(message, 'Valid!'), ...
        'Codecov settings file is invalid')
end
