import unittest2 as unittest
from datetime import datetime
import os.path
import numpy as np

from pynwb import NWBContainer, get_manager, NWBFile, NWBData, TimeSeries
from pynwb.ecephys import Device, ElectricalSeries, ElectrodeGroup, ElectrodeTable, ElectrodeTableRegion, Clustering
from pynwb.ophys import ImagingPlane, OpticalChannel, TwoPhotonSeries
from pynwb.form.backends.hdf5 import HDF5IO

class PyNWBIOTest(unittest.TestCase):
  def setUp(self):
    start_time = datetime(1970, 1, 1, 12, 0, 0)
    create_date = datetime(2017, 4, 15, 12, 0, 0)
    self.__file = NWBFile('a test source', 'a test NWB File', 'TEST123', start_time, file_create_date=create_date)
    self.__container = self.addContainer(self.file)

  @property
  def file(self):
    return self.__file

  @property
  def container(self):
    return self.__container

  def testInFromMatNWB(self):
    filename = 'MatNWB.' + self.__class__.__name__ + '.testOutToPyNWB.nwb'
    io = HDF5IO(filename, manager=get_manager())
    matfile = io.read()
    io.close()
    matcontainer = self.getContainer(matfile)
    pycontainer = self.getContainer(self.file)
    self.assertContainerEqual(matcontainer, pycontainer)

  def testOutToMatNWB(self):
    filename = 'PyNWB.' + self.__class__.__name__ + '.testOutToMatNWB.nwb'
    io = HDF5IO(filename, manager=get_manager())
    io.write(self.file)
    io.close()
    self.assertTrue(os.path.isfile(filename))

  def addContainer(self, file):
    raise unittest.SkipTest('Cannot run test unless addContainer is implemented')

  def getContainer(self, file):
    raise unittest.SkipTest('Cannot run test unless getContainer is implemented')

  def assertContainerEqual(self, container1, container2):
    type1 = type(container1)
    type2 = type(container2)
    self.assertEqual(type1, type2)
    for nwbfield in container1.__nwbfields__:
      with self.subTest(nwbfield=nwbfield, container_type=type1.__name__):
        f1 = getattr(container1, nwbfield)
        f2 = getattr(container2, nwbfield)
        if isinstance(f1, (tuple, list, np.ndarray)):
          if len(f1) > 0 and isinstance(f1[0], NWBContainer):
            for sub1, sub2 in zip(f1, f2):
              self.assertContainerEqual(sub1, sub2)
            continue
          else:
            self.assertTrue(np.array_equal(f1, f2))
        elif isinstance(f1, dict) and len(f1) and isinstance(next(iter(f1.values())), NWBContainer):
          f1_keys = set(f1.keys())
          f2_keys = set(f2.keys())
          self.assertSetEqual(f1_keys, f2_keys)
          for k in f1_keys:
            with self.subTest(module_name=k):
              self.assertContainerEqual(f1[k], f2[k])
        elif isinstance(f1, NWBContainer):
          self.assertContainerEqual(f1, f2)
        elif isinstance(f1, NWBData):
          self.assertDataEqual(f1, f2)
        else:
          self.assertEqual(f1, f2)

  def assertDataEqual(self, data1, data2):
    self.assertEqual(type(data1), type(data2))
    self.assertEqual(len(data1), len(data2))

class TimeSeriesIOTest(PyNWBIOTest):
  def addContainer(self, file):
    ts = TimeSeries('test_timeseries', 'example_source', list(range(100, 200, 10)), 'SIunit', timestamps=list(range(10)), resolution=0.1)
    file.add_acquisition(ts)
    return ts

  def getContainer(self, file):
    return file.get_acquisition(self.container.name)

class ElectrodeGroupIOTest(PyNWBIOTest):
  def addContainer(self, file):
    dev1 = Device('dev1', 'a test source')
    file.set_device(dev1)
    eg = ElectrodeGroup('elec1', 'a test source', 'a test ElectrodeGroup', 'a nonexistent place', dev1)
    file.set_electrode_group(eg)
    return eg

  def getContainer(self, file):
    return file.get_electrode_group(self.container.name)

class ElectricalSeriesIOTest(PyNWBIOTest):
  def addContainer(self, file):
    table = ElectrodeTable('electrodes')
    dev1 = Device('dev1', 'a test source')
    group = ElectrodeGroup('tetrode1', 'a test source', 'tetrode description', 'tetrode location', dev1)
    table.add_row(1, 1.0, 2.0, 3.0, -1.0, 'CA1', 'none', 'first channel of tetrode', group)
    table.add_row(2, 1.0, 2.0, 3.0, -2.0, 'CA1', 'none', 'second channel of tetrode', group)
    table.add_row(3, 1.0, 2.0, 3.0, -3.0, 'CA1', 'none', 'third channel of tetrode', group)
    table.add_row(4, 1.0, 2.0, 3.0, -4.0, 'CA1', 'none', 'fourth channel of tetrode', group)
    file.set_device(dev1)
    file.set_electrode_group(group)
    file.set_electrode_table(table)
    region = ElectrodeTableRegion(table, [0, 2], 'the first and third electrodes')  # noqa: F405
    data = list(zip(range(10), range(10, 20)))
    timestamps = list(range(10))
    es = ElectricalSeries('test_eS', 'a hypothetical source', data, region, timestamps=timestamps)
    file.add_acquisition(es)
    return es

  def getContainer(self, file):
    return file.get_acquisition(self.container.name)

class ImagingPlaneIOTest(PyNWBIOTest):
  def addContainer(self, file):
    oc = OpticalChannel('optchan1', 'unit test TestImagingPlaneIO', 'a fake OpticalChannel', '3.14')
    ip = ImagingPlane('imgpln1', 'unit test TestImagingPlaneIO', oc, 'a fake ImagingPlane', 'imaging_device_1', '6.28', '2.718', 'GFP', 'somewhere in the brain')
    file.set_imaging_plane(ip)
    return ip

  def getContainer(self, file):
    return file.get_imaging_plane(self.container.name)

class PhotonSeriesIOTest(PyNWBIOTest):
  def addContainer(self, file):
    oc = OpticalChannel('optchan1', 'unit test TestImagingPlaneIO', 'a fake OpticalChannel', '3.14')
    ip = ImagingPlane('imgpln1', 'unit test TestImagingPlaneIO', oc, 'a fake ImagingPlane', 'imaging_device_1', '6.28', '2.718', 'GFP', 'somewhere in the brain')
    file.set_imaging_plane(ip)
    data = list(zip(range(10), range(10, 20)))
    timestamps = list(range(10))
    fov = [2.0, 2.0, 5.0]
    tps = TwoPhotonSeries('test_2ps', 'unit test TestTwoPhotonSeries', data, ip, 'image_unit', 'raw', fov, 1.7, 3.4, timestamps=timestamps, dimension=[2])
    file.add_acquisition(tps)

  def getContainer(self, file):
    return file.get_acquisition(self.container.name)

class NWBFileIOTest(PyNWBIOTest):
  def addContainer(self, file):
    ts = TimeSeries('test_timeseries', 'example_source', list(range(100, 200, 10)), 'SIunit', timestamps=list(range(10)), resolution=0.1)
    self.file.add_acquisition(ts)
    mod = file.create_processing_module('test_module', 'a test source for a ProcessingModule', 'a test module')
    mod.add_container(Clustering("an example source for Clustering", "A fake Clustering interface", [0, 1, 2, 0, 1, 2], [100, 101, 102], list(range(10, 61, 10))))

  def getContainer(self, file):
    return file
