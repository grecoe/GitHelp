# Post Deployment

This page describes how to utilize the Microsoft.Resources/deploymentScripts resource in an ARM template to deploy over a set of resources in an existing resource group. 

### Useful Links
https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/deployment-script-template?tabs=CLI
https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/deployment-script-template?tabs=CLI#run-script-more-than-once
https://docs.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/how-to-manage-ua-identity-cli


# Files

|File Name|Purpose|
|------|------|
|searchindex.ps1|Powershell script to run against a KM ARM deployment|
|psscript1.json|Post deployment ARM template to run against the initial deployment. Requires 2 parameters<br><br>1. deployment_name as the name of the initial ARM deployment.<br><br>2. Identity as the principal ID of a [user created identity](https://docs.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/how-to-manage-ua-identity-cli)|
|psscript2.json|Post deployment ARM template to run against the initial deployment. Requires 2 parameters<br><br>1. deployment_name as the name of the initial ARM deployment.<br><br>2. Name of an identity to create in the resoure group.|

### Files Notes
Along with the file searchindex.ps1 having to belong in a repo, the schema files <b>datasource.json, skillset.json, index.json and indexer.json must exist in a repo as well as they are required by searchindex.ps1</b>.

### File Deployments
```
az deployment group create -g [YOUR_RG_NAME] 
    --name [YOUR_DEPLOY_NAME] 
    --template-file ./psscript[1|2].json 
    -deployment_name [YOUR_KM_DEPLOY_NAME] 
    -identity [FULL ID (script1) | ID NAME TO CREATE (script2)] 
    --verbose 
    --debug
```

## UserIdentities

Create the [identity using CLI](https://docs.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/how-to-manage-ua-identity-cli). This is used in the psscript1.json approach. 

Create the [identity in ARM](https://dev.azure.com/AZGlobal/Azure%20Global%20CAT%20Engineering/_git/RetailRecommendation?version=GBmaster&path=%2Fsrc%2Ftemplate%2Ftemplate.json). This is the psscript2.json approach and was borrowed from the recomenders repo. 

Regardless of approach, running a powershell scrip in an ARM template requires a user managed identity to function. Contributor rights against the resource group is required. 

## Use External Scripts

Currently, this is tested against files in my own personal repo. However, it supposed to be able to use files in a private ADO, or at least that's what the team (Jonathan Gao) told me. 

https://docs.microsoft.com/en-us/azure/azure-resource-manager/templates/deployment-script-template?tabs=CLI#use-external-scripts. 

# TBD

There are a couple of things that need to be addressed still

1. If a script has already been run, it does NOT look for existing services and hence will/may cause the script to terminate with an error. (This is true currently, but an existing search service returns 400 causing an error). 
2. Moving the additional files to the ADO so that they are available to be pulled by either ARM teamplate identified at the top of this file. 