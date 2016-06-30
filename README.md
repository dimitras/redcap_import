## Script to automate the import of subjects in bulk from CollOS to Redcap, and the generation of the labels' file per phase per subject.

### Step 1: 
Split full samples list from collos to multiple files. In collos_exports directory it generates a directory for each subejct, named as the subject. In the subject's directory it generates all the per phase_day files.
```
ruby fulllist2timepoints.rb all_samples_of_study_from_collos.csv
```

In each subject dir, you can also see a manifest folder that has the label files for each phase. You can import these manifests to SPS to print the labels.

### Step 2: 
Generate all the files per subject you need to import to redcap. It uses the output of Step1, that is the collos_exports/{subject_name}/ directory. In to_import directory it generates a directory for each subejct, named as the subject. In the subject's directory it generates all the per phase_day files.
```
ruby to_redcap.rb "30"
```