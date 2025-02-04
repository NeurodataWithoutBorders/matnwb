function matnwb_validateCodecovSettings()
% matnwb_validateCodecovSettings Validate a codecov settings file.
%
%   Note: This is a utility function developer's can use to check the
%   codecov settings file in .github/.codecov.yaml

    sysCommand = sprintf("curl -X POST --data-binary @%s https://codecov.io/validate", ...
        fullfile(misc.getMatnwbDir, '.github', '.codecov.yaml'));
    
    [status, message] = system(sysCommand);

    assert(status == 0, 'Curl command failed')

    assert(contains(message, 'Valid!'), ...
        'Codecov settings file is invalid')
end
