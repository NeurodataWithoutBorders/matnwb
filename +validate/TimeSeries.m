% Validate TimeSeries object
function TimeSeries(ts)
  scl = validate.util.genSuperClassList(metaclass(ts));
  if ~contains(scl, 'types.TimeSeries')
    error('validate.TimeSeries: input is not a TimeSeries object');
  end
  
  if ~isempty(ts.control)
    if length(ts.control) ~= length(ts.data)
      error('validate.TimeSeries: length of ''control'' field should match length of ''data'' field.');
    end
    
    if max(ts.control) - 1 ~= length(ts.control_description)
      error('validate.TimeSeries: length of ''control_description'' field should be 1 less than the maximum value in ''control''');
    end
  end
end