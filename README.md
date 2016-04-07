# marathon-artifactory-project

- First run marathon-lb :

`dcos package install marathon-lb`

- DCOS doesn't support yet service dependencies, so you'll have to run a mysql first :

`dcos marathon app add mysql.json`

- Run Artifactory and provide the parameters in the json files :
`dcos package install artifactory --options=haexample.json`

If you don't specify options, by default it will run one artifactory-pro instance and you'll have to past the license key in the UI.

