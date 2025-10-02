.. _installation:

Installation
============

Quick install
-------------

If you want the quickest installation option, and you have ``git`` available, run the following snippet in MATLAB. This clones into your current working directory, adds MatNWB to the path, and optionally persists the change:

.. code-block:: matlab

   !git clone https://github.com/NeurodataWithoutBorders/matnwb.git
   addpath("matnwb")
   % Optional: persist for future MATLAB sessions
   savepath()

If you do not have git, prefer a stable release, or run into installation issues, please refer to the detailed guide below.

Prerequisites
-------------

- MATLAB R2019b or newer (we strive to support MATLAB releases from the past ~5 years).

.. note::
   Dynamically loaded filters for dataset compression are supported only in MATLAB R2022a or later.

Choose an installation method
-----------------------------

Pick the method that best fits your workflow:

- Method A: Clone from GitHub (development version) — Recommended
- Method B: MATLAB Add-On Manager
- Method C: Download a release ZIP (offline-friendly, stable)

.. _method-a:

Method A — Install the development version from GitHub (recommended)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. note::
   Requires `git <https://git-scm.com>`_.

Use this if you want the latest changes or plan to contribute. This clones MatNWB into your current working directory.

- From a shell/Terminal:

  .. code-block:: bash

     git clone https://github.com/NeurodataWithoutBorders/matnwb.git

- Or directly from within MATLAB:

  .. code-block:: matlab

     !git clone https://github.com/NeurodataWithoutBorders/matnwb.git
     addpath("matnwb")
     % Optional: persist for future MATLAB sessions
     savepath()

.. _method-b:

Method B — Install via MATLAB Add-On Manager
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

1. In MATLAB, go to: Home tab → Add-Ons → Get Add-Ons.
2. In Add-On Explorer, search for ``matnwb``.
3. Select “NeurodataWithoutBorders/matnwb”, then click “Add to MATLAB”.

.. tip::
   If your organization blocks Add-On Explorer, use Method A or C instead.

.. _method-c:

Method C — Install from a release ZIP (offline-friendly, stable)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

1. Download the latest release ZIP from the `GitHub Releases <https://github.com/NeurodataWithoutBorders/matnwb/releases>`_ page.
2. Unzip into a permanent folder (e.g., ``C:\tools\matnwb`` on Windows or ``~/tools/matnwb`` on macOS/Linux).
3. Add MatNWB to your MATLAB path:

   .. code-block:: matlab

      addpath("path/to/matnwb")

4. (Optional) Persist the change for future sessions:

   .. code-block:: matlab

      savepath() % May require write permissions to pathdef.m


Verify your installation
------------------------

Run this quick check in MATLAB to verify that MatNWB is installed:

.. code-block:: matlab

   versionInfo = ver("matnwb")
   
You should see a structure with MatNWB version information.


Update or uninstall
-------------------

- Update (Add-On Manager):

  - MATLAB R2025a and later:

    - Home → Add-Ons → Manage Add-Ons → Find “matnwb” → Update (if available).

  - Before MATLAB R2025a:

    - Uninstall your current version and reinstall a newer version.

- Update (Git):

  .. code-block:: matlab

     cd path/to/matnwb
     !git pull

- Uninstall (Remove the MatNWB folder from the MATLAB path and delete it):

  .. code-block:: matlab

     rmpath("path/to/matnwb")
     savepath()
     rmdir("path/to/matnwb", "s") % delete folder and contents


Troubleshooting
---------------

MATLAB cannot find MatNWB functions
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

- Ensure the MatNWB folder is on the path (see “Verify your installation”).
- If needed, restart MATLAB after calling ``savepath()``.
- Use ``which nwbRead -all`` to diagnose duplicate or shadowed installs.

Add-On Explorer blocked by network policy
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

- Use Method A (Git clone) or Method C (release ZIP).

Path persistence issues
~~~~~~~~~~~~~~~~~~~~~~~

- ``savepath`` may require write permissions to ``pathdef.m``.
- Run MATLAB as an administrator (Windows) or adjust permissions/create a user pathdef.

Next steps
----------

- Read data with :func:`nwbRead` (see :doc:`/pages/concepts/file_read`).
- Review important data dimension notes: :doc:`/pages/concepts/dimension_ordering`.
- Explore tutorials: :doc:`../tutorials/index`.