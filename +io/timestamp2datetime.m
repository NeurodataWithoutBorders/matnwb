function Datetimes = timestamp2datetime(timestamps)
    %TIMESTAMP2DATETIME converts string timestamps to MATLAB datetime object
    
    timestamps = timestamp2cellstr(timestamps);
    for iTimestamp = 1:length(timestamps)
        timestampString = timestamps{iTimestamp};
        try
            Datetime = datetime(timestampString);
        catch ME
            unrecognizedStringId = { ...
                'MATLAB:datetime:UnrecognizedDateStringSuggestLocale' ...
                , 'MATLAB:datetime:UnrecognizedDateStringsSuggestLocale' ...
                }; % missing plural strings lmao
            if any(strcmp(ME.identifier, unrecognizedStringId))
                Datetime = detectDatetime(timestampString);
            else
                rethrow(ME);
            end
        end
        Datetimes(iTimestamp) = Datetime;
    end
end

function Datetime = detectDatetime(timestamp)
    errorId = 'NWB:InvalidTimestamp';
    errorTemplate = sprintf('Timestamp `%s` is not a valid ISO8601 subset for NWB:\n  %%s', timestamp);
    Datetime = datetime(0, 0, 0, 0, 0, 0, 0);
    %% YMoD
    hmsStart = find(timestamp == 'T', 1);
    if isempty(hmsStart)
        ymdStamp = timestamp;
    else
        ymdStamp = extractBefore(timestamp, hmsStart);
    end
    errorMessage = sprintf(errorTemplate, 'YMD should be in the form YYYY-mm-dd or YYYYmmdd');
    if contains(ymdStamp, '-')
        assert(length(ymdStamp) == 10, errorId, errorMessage);
        YmdToken = struct(...
            'Year', ymdStamp(1:4) ...
            , 'Month', ymdStamp(6:7) ...
            , 'Day', ymdStamp(9:10) ...
        );
    else
        assert(length(ymdStamp) == 8, errorId, errorMessage);
        YmdToken = struct(...
            'Year', ymdStamp(1:4) ...
            , 'Month', ymdStamp(5:6) ...
            , 'Day', ymdStamp(7:8) ...
        );
    end
    Datetime.Year = str2double(YmdToken.Year);
    Datetime.Month = str2double(YmdToken.Month);
    Datetime.Day = str2double(YmdToken.Day);
    assert(~isnat(Datetime), errorId, sprintf(errorTemplate, 'non-numeric YMD values detected'));
    
    %% HMiS TZ
    if isempty(hmsStart)
        return;
    end
    afterDateStamp = extractAfter(timestamp, 'T'); % needs to do this so we don't have wrong '-' checks.
    timeZoneStart = find(afterDateStamp == 'Z' | afterDateStamp == '+' | afterDateStamp == '-', 1);
    if isempty(timeZoneStart)
        hmsStamp = afterDateStamp;
    else
        hmsStamp = extractBefore(afterDateStamp, timeZoneStart);
    end
    errorMessage = sprintf(errorTemplate ...
        , 'H:m:s should be in the form HH:mm:ss.ssssss or HHmmss.ssssss');
    if contains(hmsStamp, ':')
        % note, seconds must be at least 2 digits
        assert(length(hmsStamp) >= 8, errorId, errorMessage);
        HmsToken = struct(...
            'Hour', hmsStamp(1:2) ...
            , 'Minute', hmsStamp(4:5) ...
            , 'Second', hmsStamp(7:end) ...
        );
    else
        assert(length(hmsStamp) >= 6, errorId, errorMessage);
        HmsToken = struct(...
            'Hour', hmsStamp(1:2) ...
            , 'Minute', hmsStamp(3:4) ...
            , 'Second', hmsStamp(5:end) ...
        );
    end
    Datetime.Hour = str2double(HmsToken.Hour);
    Datetime.Minute = str2double(HmsToken.Minute);
    Datetime.Second = str2double(HmsToken.Second);
    assert(~isnat(Datetime), errorId, sprintf(errorTemplate, 'non-numeric H:m:s values detected'));

    %% TimeZone
    if isempty(timeZoneStart)
        return;
    end
    timeZoneStamp = afterDateStamp(timeZoneStart:end);
    try
        Datetime.TimeZone = timeZoneStamp;
    catch ME
        Cause = MException(errorId ...
            , sprintf(errorTemplate, sprintf('invalid time zone `%s` provided', timeZoneStamp)));
        addCause(ME, Cause);
       	throwAsCaller(ME);
    end
end

function cells = timestamp2cellstr(timestamps)
    if isstring(timestamps)
        cells = num2cell(timestamps);
        for iString = 1:length(cells)
            cells{iString} = char(cells{iString});
        end
    elseif iscell(timestamps)
        cells = cell(size(timestamps));
        for iElement = 1:length(timestamps)
            cells(iElement) = timestamp2cellstr(timestamps{iElement});
        end
    elseif ischar(timestamps)
        cells = {timestamps};
    else
        error(['timestamps must be a ' ...
            , 'string, character array, or cell array of strings/character arrays.']);
    end
end

