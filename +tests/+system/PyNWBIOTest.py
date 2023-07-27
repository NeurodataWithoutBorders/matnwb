import unittest
from datetime import datetime, timedelta
import os.path
import numpy as np
from dateutil.tz import tzlocal, tzoffset
import numpy.testing as npt
import h5py

from pynwb import get_manager, NWBFile, TimeSeries
from pynwb.ecephys import ElectricalSeries, Clustering
from pynwb.ophys import OpticalChannel, TwoPhotonSeries
from pynwb.misc import Units
from hdmf.backends.hdf5 import HDF5IO
from hdmf.container import Container, Data

class PyNWBIOTest(unittest.TestCase):
    def setUp(self):
        #tzoffset requires offset in seconds
        tz = tzoffset(None, -8 * 60 * 60)
        start_time = datetime(2018, 12, 2, 12, 57, 27, 371444, tzinfo=tz)
        create_date = datetime(2017, 4, 15, 12, 0, 0, tzinfo=tz)
        self.__file = NWBFile('a test NWB File', 'TEST123', start_time, file_create_date=create_date)
        self.__container = self.addContainer(self.file)

    @property
    def file(self):
        return self.__file

    @property
    def container(self):
        return self.__container

    def testInFromMatNWB(self):
        filename = 'MatNWB.' + self.__class__.__name__ + '.testOutToPyNWB.nwb'
        with HDF5IO(filename, manager=get_manager(), mode='r') as io:
            matfile = io.read()
            matcontainer = self.getContainer(matfile)
            pycontainer = self.getContainer(self.file)
            self.assertContainerEqual(matcontainer, pycontainer)

    def testOutToMatNWB(self):
        filename = 'PyNWB.' + self.__class__.__name__ + '.testOutToMatNWB.nwb'
        with HDF5IO(filename, manager=get_manager(), mode='w') as io:
            io.write(self.file)
        self.assertTrue(os.path.isfile(filename))

    def addContainer(self, file):
        raise unittest.SkipTest('Cannot run test unless addContainer is implemented')

    def getContainer(self, file):
        raise unittest.SkipTest('Cannot run test unless getContainer is implemented')

    def assertContainerEqual(self, container1, container2):           # noqa: C901
        '''
        container1 is what was read or generated
        container2 is what is hardcoded in the TestCase
        '''
        type1 = type(container1)
        type2 = type(container2)
        self.assertEqual(type1, type2)
        try:
            container_fields = container1.__nwbfields__
        except AttributeError:
            container_fields = container1.__fields__
        for nwbfield in container_fields:
            with self.subTest(nwbfield=nwbfield, container_type=type1.__name__):
                field1 = getattr(container1, nwbfield)
                field2 = getattr(container2, nwbfield)
                if isinstance(field1, (tuple, list, np.ndarray)):
                    if len(field1) > 0:
                        if isinstance(field1[0], Container):
                            for sub1, sub2 in zip(field1, field2):
                                self.assertContainerEqual(sub1, sub2)
                        elif isinstance(field1[0], Data):
                            for sub1, sub2 in zip(field1, field2):
                                self.assertDataEqual(sub1, sub2)
                        continue
                    else:
                        self.assertEqual(len(field1), len(field2))
                        if len(field1) == 0:
                            continue
                        if isinstance(field1[0], float):
                                for v1, v2 in zip(field1, field2):
                                    self.assertAlmostEqual(v1, v2, places=6)
                        else:
                            self.assertTrue(np.array_equal(field1, field2))
                elif isinstance(field1, dict) and len(field1) and isinstance(next(iter(field1.values())), Container):
                    field1_keys = set(field1.keys())
                    field2_keys = set(field2.keys())
                    self.assertSetEqual(field1_keys, field2_keys)
                    for k in field1_keys:
                        with self.subTest(module_name=k):
                            self.assertContainerEqual(field1[k], field2[k])
                elif isinstance(field1, Container) or isinstance(field1, Container):
                    self.assertContainerEqual(field1, field2)
                elif isinstance(field1, Data) and isinstance(field2, Data):
                    self.assertDataEqual(field1, field2)
                elif isinstance(field1, Data) or isinstance(field2, Data):
                    self.assertTrue(np.array_equal(field1.data, field2))
                elif isinstance(field1, (float, np.float32, np.float16, h5py.Dataset)):
                    npt.assert_almost_equal(field1, field2)
                elif isinstance(field1, datetime):
                    self.assertTrue(isinstance(field2, datetime))
                    field1_upper = field1 + timedelta(milliseconds = 1)
                    field1_lower = field1 - timedelta(milliseconds = 1)
                    self.assertTrue(field2 >= field1_lower and field2 <= field1_upper)
                else:
                    self.assertEqual(field1, field2)

    def assertDataEqual(self, data1, data2):
        self.assertEqual(type(data1), type(data2))
        self.assertEqual(len(data1), len(data2))


class TimeSeriesIOTest(PyNWBIOTest):
    def addContainer(self, file):
        ts = TimeSeries('test_timeseries', np.arange(100, 200, 10).astype(np.double),
                        'SIunit', timestamps=np.arange(10, dtype=float), resolution=0.1)
        file.add_acquisition(ts)
        return ts

    def getContainer(self, file):
        return file.get_acquisition(self.container.name)


class ElectrodeGroupIOTest(PyNWBIOTest):
    def addContainer(self, file):
        dev1 = file.create_device('dev1', 'dev1 description')
        eg = file.create_electrode_group('elec1', 'a test ElectrodeGroup', 'a nonexistent place', dev1)
        return eg

    def getContainer(self, file):
        return file.get_electrode_group(self.container.name)


class ElectricalSeriesIOTest(PyNWBIOTest):
    def addContainer(self, file):
        dev1 = file.create_device('dev1', 'dev1 description')
        group = file.create_electrode_group('tetrode1', 'tetrode description', 'tetrode location', dev1)
        for i in range(4):
            file.add_electrode(1.0, 2.0, 3.0, 1.0, 'CA1', 'none', group)
        region = file.create_electrode_table_region([0, 2], 'the first and third electrodes')
        data = list(zip(np.arange(10).astype(np.double), np.arange(10, 20).astype(np.double)))
        timestamps = list(range(10))
        es = ElectricalSeries('test_eS', data, region, timestamps=timestamps)
        file.add_acquisition(es)
        return es

    def getContainer(self, file):
        return file.get_acquisition(self.container.name)


class ImagingPlaneIOTest(PyNWBIOTest):
    def addContainer(self, file):
        dev1 = file.create_device('imaging_device_1', 'dev1 description')
        oc = OpticalChannel('optchan1', 'a fake OpticalChannel', 3.14)
        ip = file.create_imaging_plane(
            'imgpln1',
            oc,
            description = 'a fake ImagingPlane',
            device = dev1,
            excitation_lambda = 6.28,
            indicator = 'GFP',
            location = 'somewhere in the brain',
            imaging_rate = 2.718)
            
        return ip

    def getContainer(self, file):
        return file.get_imaging_plane(self.container.name)


class PhotonSeriesIOTest(PyNWBIOTest):
    def addContainer(self, file):
        dev1 = file.create_device('dev1', 'dev1 description')
        oc = OpticalChannel('optchan1', 'a fake OpticalChannel', 3.14)
        ip = file.create_imaging_plane(
            'imgpln1',
            oc,
            description = 'a fake ImagingPlane',
            device = dev1,
            excitation_lambda = 6.28,
            indicator = 'GFP',
            location = 'somewhere in the brain',
            imaging_rate = 2.718)
        data = np.ones((3, 3, 3))
        timestamps = list(range(10))
        fov = [2.0, 2.0, 5.0]
        tps = TwoPhotonSeries('test_2ps', ip, data, 'image_unit', 'raw',
                              fov, 1.7, 3.4, timestamps=timestamps, dimension=[200, 200])
        file.add_acquisition(tps)
        return tps

    def getContainer(self, file):
        return file.get_acquisition(self.container.name)


class NWBFileIOTest(PyNWBIOTest):
    def addContainer(self, file):
        ts = TimeSeries('test_timeseries', list(range(100, 200, 10)),
                        'SIunit', timestamps=list(range(10)), resolution=0.1)
        self.file.add_acquisition(ts)
        mod = file.create_processing_module('test_module', 'a test module')
        mod.add_container(Clustering("A fake Clustering interface", [0, 1, 2, 0, 1, 2],
                                     [100., 101., 102.], list(range(10, 61, 10))))

    def getContainer(self, file):
        return file


class UnitTimesIOTest(PyNWBIOTest):
    def addContainer(self, file):
        self.file.units = Units('units', waveform_rate=1., resolution=3.)
        self.file.units.add_unit(waveform_mean=[5], waveform_sd=[7], waveforms=np.full((1, 1), 9),
                                 spike_times=[11])
    def getContainer(self, file):
        return file.units
