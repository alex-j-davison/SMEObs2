# SME Obs 2

## Summary 

Script does the following:-

* Script: Script to build a new microk8s environment
* Description:Script to build a new microk8s environment
* Created by: Alex J Davison (alexdav@cisco.com)
* Created date: 09/09/26
* Version: 2.0.0

## Scope of script

* Update OS
* Get DNS values
* Install microk8s with add-ons
* Create  microk8s alias
* Download helm repos:-
    - splunk-otel-collector-chart
* Setup Splunk Otel 

## Files

* .gitattributes - (https://git-scm.com/docs/gitattributes)
* .gitignore - (https://git-scm.com/docs/gitignore)
* LICENSE - 
* README.md - This file (https://www.markdownguide.org/basic-syntax/)
* setup.sh - Setup script to create a new microk8s environment

## Arguments

* None

## Installation steps

Steps:-

1. Clone repo

<code> git clone https://github.com/alex-j-davison/obs-sme2.git </code>

2. Change permissions on shell scripts to execution

<code> chmod +x ./obs-sme2/setup.sh </code>

4. Run setup

<code> ./obs-sme2/setup.sh | tee setupLog.log</code>


## User guide

### Forward port to enable webpage

<code>sudo microk8s kubectl port-forward svc/kubeinvaders -n kubeinvaders 8080:80 --address='0.0.0.0'</code>

### View metrics

<code>curl $VM_IP$:8080/metrics</code>

**_Note:_** Forward port to enable webpage **MUST** be completed first.

## Change log

### Version 1.0.0
- Initial creation.