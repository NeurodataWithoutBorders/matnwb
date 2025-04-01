.. _how-to-create-release:

How to Create a New Release
===========================

1. **Navigate to the** `"Actions" <https://github.com/NeurodataWithoutBorders/matnwb/actions/workflows/prepare_release.yml>`_ **tab** in the MatNwb repository on GitHub.

2. **Click "Run workflow"**, then:
   - Enter the desired version number in ``major.minor.patch`` format (e.g., ``2.8.0``).
   - Click the **Run workflow** button to start the process.

3. **Monitor the workflow** as it runs across multiple MATLAB and OS configurations. The workflow is successful if:
   - The version string is valid.
   - All tests pass successfully.

4. **Confirm the draft release** once the workflow completes:
   - A new tag (matching your version number) is pushed to the repository.
   - A draft release is automatically generated with updated badges and the revised ``Contents.m`` file.

5. **(Optional) Finalize the release** by editing the draft release in GitHub’s "Releases" section, adding any additional details, and clicking **"Publish release"**.
