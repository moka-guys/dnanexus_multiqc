# Release checklist
This checklist is for my own reference, as I forget the steps every time.

1. Check that everything is up to date and ready to go
2. Figure out what this release should be called
3. Update version numbers in code: `setup.py`, `CHANGELOG.md`, `docs/README.md`
4. Link the changelog subheading to the as yet non-existant release URL. Add date.
5. Install the package again for local development, but with the new version number:
```bash
python setup.py develop
```
6. Run using test data
  * Check for any command line or javascript errors
  * Check version numbers are printed correctly
7. Release on PyPI:
```bash
python setup.py sdist upload
```
8. Test that it pip installs:
```bash
conda create --name testing python pip
source activate testing
pip install multiqc
multiqc .
source deactivate
conda remove --name testing --all
```
9. Commit and push version updates
10. Make a [release](https://github.com/ewels/MultiQC/releases) on GitHub - paste changelog section.
11. Check that [PyPI listing page](https://pypi.python.org/pypi/multiqc/) looks sane
12. Make a new release on `bioconda`:
```bash
cd bioconda-recipes/recipes
rm -r multiqc
conda skeleton pypi multiqc
# Check that only the new things have changed
git commit
git push
# Submit a Pull Request and merge
```
13. Tell UPPMAX about the new version and ask for the module system to be updated.
14. Create new demo reports for the website and upload.
15. Describe new release on [SeqAnswers thread](http://seqanswers.com/forums/showthread.php?p=195831#post195831)
16. Tweet that new version is released
17. Update version numbers to new dev version in `setup.py` and `docs/README.md`
18. Add a new section in the changelog for the development version
19. Commit and push. Continue making more awesome :metal:
