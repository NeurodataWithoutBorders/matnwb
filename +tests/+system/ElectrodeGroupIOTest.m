classdef ElectrodeGroupIOTest < tests.system.PyNWBIOTest
  methods    
    function addContainer(testCase, file) %#ok<INUSL>
      dev = types.Device( ...
        'source', {'a test source'});
      file.general.devices = types.untyped.Group();
      file.general.devices.dev1 = dev;
      eg = types.ElectrodeGroup( ...
        'source', {'a test source'}, ...
        'description', {'a test ElectrodeGroup'}, ...
        'location', {'a nonexistent place'}, ...
        'device', types.untyped.Link('/general/devices/dev1', '', dev));
      file.general.extracellular_ephys = types.untyped.Group();
      file.general.extracellular_ephys.elec1 = eg;
    end
    
    function c = getContainer(testCase, file) %#ok<INUSL>
      c = file.general.extracellular_ephys.elec1;
    end
  end
end

