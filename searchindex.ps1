<#	
	Copyright  Microsoft Corporation ("Microsoft").
	
	Microsoft grants you the right to use this software in accordance with your subscription agreement, if any, to use software 
	provided for use with Microsoft Azure ("Subscription Agreement").  All software is licensed, not sold.  
	
	If you do not have a Subscription Agreement, or at your option if you so choose, Microsoft grants you a nonexclusive, perpetual, 
	royalty-free right to use and modify this software solely for your internal business purposes in connection with Microsoft Azure 
	and other Microsoft products, including but not limited to, Microsoft R Open, Microsoft R Server, and Microsoft SQL Server.  
	
	Unless otherwise stated in your Subscription Agreement, the following applies.  THIS SOFTWARE IS PROVIDED "AS IS" WITHOUT 
	WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, 
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL MICROSOFT OR ITS LICENSORS BE LIABLE 
	FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED 
	TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) 
	HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
	NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THE SAMPLE CODE, EVEN IF ADVISED OF THE
	POSSIBILITY OF SUCH DAMAGE.
#>

<#
    Issues:
        - Creating a datasource where it already exists returns a 400 not a 409 


    Code Execution Locations
        - Program Parameters :              Line 42
        - Load Settings from Deployment :   Line 561
        - Main program execution :          Line 669
#>

<# ----------------------------------------------------------------------
    

    Program parameters, it's expecte you have a logged on Azure user 
    with access to the subscription that holds the resource group that
    will either be identified with the -resource_group parameter or 
    hard coded here. 


---------------------------------------------------------------------- #>
param(
    [string]$resource_group = 'rijai-armtest',
    [string]$deployment_name = 'kmjulydeployment'
)


<# ----------------------------------------------------------------------


    Get Azure Resource Group Deployment outputs


---------------------------------------------------------------------- #>

class DeploymentOutputs {
    <#
        Static class holding the names of all the deployment outputs we'll need to proceed
    #>
    static $searchApiKey = 'searchApiKey'
    static $cognitiveServicesKey = "cognitiveServicesKey"
    static $storageAccountName = "storageAccountName"
    static $storageAccountKey = "storageAccountKey"
    static $storageContainerName = "storageContainerName"
    static $prefixName = "prefixName"
    static $searchServiceName = "searchServiceName"
    static $searchIndexName = "searchIndexName"   

    static $allOutputs = [DeploymentOutputs]::searchApiKey, [DeploymentOutputs]::cognitiveServicesKey, [DeploymentOutputs]::storageAccountKey, [DeploymentOutputs]::storageAccountName, [DeploymentOutputs]::storageContainerName, [DeploymentOutputs]::prefixName, [DeploymentOutputs]::searchServiceName, [DeploymentOutputs]::searchIndexName
}

<#
    Function : Get-Deployment

    Purpose: 
        Given an Azure Resource Group and Resource Group Deployment name, this function will 
        retrieve all of the deployment outputs as a dictionary.

        All values from DeploymentOutputs.allOutputs must be present. If collecting the deployment
        OR one of the values is missing, $null is returned for caller to terminate. 

    Parameters:
        resourceGroup - Resource Group name in which to get the deployment outputs
        deployment - Deployment name in the resource group

    Returns:
        Returns a dictionary of all of the values. 
#>
Function Get-Deployment {
    param( 
        [System.String] $resourceGroup,
        [System.String] $deployment
    )

    $deploy_data = $null
    try{
        $deploy_data = Get-AzResourceGroupDeployment -ResourceGroupName $resourceGroup -Name $deployment
    }
    catch{
        Write-Host("Resource Group Deployment Exception Caught-----")
        Write-Host($_.Message)
    }

    if($deploy_data -eq $null){
        Write-Host("Deployment not found on Resource Group")
        return $deploy_data
    }

    $return_data = @{}
    if($deploy_data -ne $null ){
        foreach ($key in $deploy_data.Outputs.Keys) { 
            $variable = $deploy_data.Outputs[$key]
            $var = $variable.Value.ToString()
            $return_data.Add($key, $var)
        } 
    }

    # Now validate that they are all there. 
    $deployment_keys = $return_data.Keys.ForEach('ToString')

    foreach($required_key in [DeploymentOutputs]::allOutputs){
        if( $deployment_keys.Contains($required_key) -eq $false){
            Write-Host("Missing required key in data " + $required_key)
            $return_data = $null
            break
        }
    }
    $return_data
}


<# ----------------------------------------------------------------------


    Azure Storage Routines


---------------------------------------------------------------------- #>

<#
    Function : getStorageContext

    Purpose: 
        Retrieve an IStorageContext object to be used in other storage
        calls.

    Parameters:
        storage_account - Azure Storage Account Name
        storage_key - Associated key to Azure Storage Account Name

    Returns:
        IStorageContext for use in other *-Az storage calls.. 
#>
Function getStorageContext{
    param( 
        [System.String] $storage_account,
        [System.String] $storage_key
    )

    Write-Host("Getting storage account " + $storage_account)
    $res = New-AzStorageContext -StorageAccountName $storage_account -StorageAccountKey $storage_key

    return $res.Context
}

<#
    Function : createStorageContainer

    Purpose: 
        Create a private storage container in a given storage account identified
        by the context object. 

    Parameters:
        storage_context - IStorageContext
        container_name - Name of container to create

    Returns:
        Storage container if succesful, $null otherwise.  
#>
Function createStorageContainer{
    param( 
        $storage_context,
        [System.String] $container_name
    )

    $container = $null
    try {
        $container = Get-AzStorageContainer -Name $container_name -Context $storage_context

        if($container){
            Write-Host("Storage container exists....")
        }
        else{
            Write-Host("Creating storage container " + $container_name)
            $container = New-AzStorageContainer -Name $container_name -Context $storage_context
        }
    }
    catch{
        Write-Host("Container Exception Caught-----")
        Write-Host($_.ToString())
        $container = $null
    }
    return $container
}


<# ----------------------------------------------------------------------
    Generic URI builder
---------------------------------------------------------------------- #>

<#
    Function : constructUrl

    Purpose: 
        Generic URL builder for creating many of the services in the search 
        service that requires different inputs. 

        Read the code as I took this directly from the Python implementation.

    Parameters:

    Returns:
        String URL to use for request
#>
Function constructUrl {
    param( 
        [System.String] $service,
        [System.String] $resource,
        [System.String] $resource_name,
        [System.String] $action,
        [System.String] $api_version
    )

    if( [String]::IsNullOrEmpty($resource_name) -eq $false){
        if( [String]::IsNullOrEmpty($action) -eq $false){
            return $service + "/" + $resource + "/" + $resource_name + "/" + $action + "?api-version=" + $api_version
        }
        else{
            return $service + "/" + $resource + "/" + $resource_name + "?api-version=" + $api_version
        }
    }
    else{
        return $service + "/" + $resource + "?api-version=" + $api_version
    }
}

<# ----------------------------------------------------------------------


    File utilities


---------------------------------------------------------------------- #>

<#
    Function : loadFile

    Purpose: 
        Load a JSON file and return a PSCustomObject with the content.

    Parameters:
        filePath - File to load

    Returns:
        Returns a PSCustomObject if file exists and was parsed, $null
        otherwise.
#>

Function loadFile {
    param( 
        [System.String] $filePath
    ) 

    $return_object = $null
    if( [IO.File]::Exists($filePath) -eq $true)
    {
        try {
            $content = [IO.File]::ReadAllText($filePath)
            $return_object = ConvertFrom-Json -InputObject $content
        }
        catch {
            Write-Host("Failed to parse file " + $filePath)
            $return_object = $null
        }
    }
    else {
        Write-Host("Request file does not exist  " + $filePath)
    }

    return $return_object
}

<#
    Function : uploadSampleDataToBlob

    Purpose: 
        Uploads all files in a specified directory to a specified storage account
        and storage container. 

    Parameters:
        filePath - local path to files to upload
        storageContext - IStorageContext item to desired account
        storageContainer - Name of an existing storage container

    Returns:
        None
#>
Function uploadSampleDataToBlob{
    param( 
        [System.String] $filePath,
        $storageContext,
        [System.String] $storageContainer
    ) 
    
    $response = Get-ChildItem -Path $filePath -File
    foreach($itm in $response){
        Write-Host("Moving file " + $itm.Name + " to storage container " + $storageContainer)
        Set-AzStorageBlobContent -File $itm.FullName -Container $storageContainer -Blob $itm.Name -Context $storageContext 
    }
}

<# ----------------------------------------------------------------------


    Generic request methods


---------------------------------------------------------------------- #>

<#
    Function: makeRequest

    Purpose: 
        Makes an HTTP request with either POST or GET

        POST requires all parameters
        GET requires all but body

    Parameters:
        url = URL to call
        headers = Request headers
        body = Request body
        method = POST or GET

    Returns:
        HTTP response or $null if there was a problem
#>
Function makeRequest{
    param( 
        [System.String] $url,
        [System.Collections.Hashtable]  $headers,
        $body,
        $method
    ) 

    Write-Host("----REQUEST----")
    $request_response = $null

    if( [String]::IsNullOrEmpty($url) -eq $false){
        Write-Host("Request on " + $url)

        if( ($method -eq "POST") -or  ($method -eq "PUT")) {
            $request_body = $body | ConvertTo-Json -Depth 100

            Write-Host($url)
            foreach($hdr in $headers.Keys)
            {
                Write-Host(" " + $hdr + ' = ' + $headers[$hdr])
            }
            Write-Host($request_body)
    
            #try { 
                $request_response = Invoke-WebRequest $url -Headers $headers -Body $request_body -Method $method 
            #} catch {
            #    Write-Host($_.Exception.Message)
            #    $request_response = $_.Exception.Response
            #    Write-Host($_.Exception)
            #}
        }
        elseif ($method -eq "GET"){
            try { 
                $request_response = Invoke-WebRequest $url -Headers $headers -Method 'GET'
            } catch {
                Write-Host($_.Exception.Message)
                $request_response = $_.Exception.Response
            }
        }

    }
    else {
        Write-Host("URL is missing")
    }

    $request_response
}

<#
    Function : validateResponse

    Purpose: 
        Validate the sresponse from an HTTP request. If the request is null, status
        code is higher than the max expected (typically 204 Created) then exit
        is called internally.

        Caller does not check return values, if execution continues after calling this
        method, the response was acceptable. 

    Parameters:
        request_response - HTTP Response Object
        subject - Name to be used in logging
        max_accepted_code - Maximum status code value accepted

    Returns:
        None
#>

Function validateResponse{
    param( 
        $request_response,
        [System.String]  $subject,
        [System.Int32]  $max_accepted_code
    ) 

    if($request_response -ne $null){
        $code = $resp.StatusCode.Value__
        if($code -gt $max_accepted_code){
            Write-Host("Request Failed with " + $code)
            exit
        }
    }
    elseif($request_response -eq $null){
        Write-Host($subject + " Failed")
        exit
    }    
}

<#
    Function : getIndexerStatus

    Purpose: 
        Wait up to 10 minutes for the indexer to report anything other than unknown or 
        inProgress. 

        Output to see content. 

    Parameters:
        url - URL to indexer status
        headers - Required HTTP headers

    Returns:
        None
#>
Function getIndexerStatus{
    param( 
        [System.String] $url,
        [System.Collections.Hashtable]  $headers
    ) 

    $continue = $true
    $current_attempt = 0
    $max_retries = 30 # Wait a max of 10 minutes
    $continue_conditions =  "unknown", "inProgress"

    do {
        $response = makeRequest $url $headers $null "GET"

        if($response -eq $null){
            Write-Host("Failure to query indexer status")
            $continue = $false
        }
        elseif( $response.StatusCode -ne 200){
            Write-Host("Failure when querying indexer status - " + $response.StatusCode)
            $continue = $false
        }
        else{
            
            if ([String]::IsNullOrEmpty($response.Content) -eq $false) {
                $resp_content = ConvertFrom-Json $response.Content

                if($resp_content.lastResult -and $resp_content.lastResult.status)
                {
                    $status = $resp_content.lastResult.status.ToString()
                    if( $continue_conditions.Contains($status) -eq $false)
                    {
                        Write-Host("Completing look for indexer status with : " + $status)
                        $continue = $false
                    }
                }
            }

            # In case of no output or we aren't ready, sleep assuming we aren't already past the timeout
            if($continue -eq $true){
                Start-Sleep -s 20

                $current_attempt += 1
                if($current_attempt -gt $max_retries)
                {
                    Write-Host("Indexer hasn't come up in 10 minutes, leaving...")
                    $continue = $false
                }
            }
        }
    } while($continue)
}

<#
    Function : Get-Deployment

    Purpose: 
        Given an Azure Resource Group and Resource Group Deployment name, this function will 
        retrieve all of the deployment outputs as a dictionary.

        All values from DeploymentOutputs.allOutputs must be present. If collecting the deployment
        OR one of the values is missing, $null is returned for caller to terminate. 

    Parameters:
        resourceGroup - Resource Group name in which to get the deployment outputs
        deployment - Deployment name in the resource group

    Returns:
        Returns a dictionary of all of the values. 
#>
Function getSearchDocCounts{
    param( 
        [System.String] $url,
        [System.Collections.Hashtable]  $headers
    ) 

    $response = makeRequest $url $headers $null "GET"

    if($response -eq $null){
        Write-Host("Failure to query doc count")
    }
    elseif( $response.StatusCode -ne 200){
        Write-Host("Failure when querying doc count - " + $response.StatusCode)
    }
    elseif ([String]::IsNullOrEmpty($response.Content) -eq $false) {
        Write-Host("Scanning for document count ....")    
        $resp_content = ConvertFrom-Json $response.Content

        foreach($mbm in $resp_content.PSObject.Members) {
            if( $mbm.Name -eq "@odata.count"){
                Write-Host("Total Documents Found - " + $mbm.value)
            }
        }
    }
    else{
        Write-Host("Succesful return, but no content to parse.")
    }
}


<# ----------------------------------------------------------------------


    Prepare variables using the inputs from the Deployment Outputs


---------------------------------------------------------------------- #>
$deployment_output_table = Get-Deployment $resource_group $deployment_name

if( $deployment_output_table -eq $null){
    Write-Host("No deployment settings returned....exiting")
    exit
}
else{
    Write-Host("Deployment settings loaded...")
}


# Azure Search
$search_service = "https://" + $deployment_output_table[[DeploymentOutputs]::searchServiceName] + ".search.windows.net"
$api_version = "2019-05-06-Preview"

# Azure Storage
$storage_account_name = $deployment_output_table[[DeploymentOutputs]::storageAccountName]
$storage_account_key = $deployment_output_table[[DeploymentOutputs]::storageAccountKey]

$storage_connection = "DefaultEndpointsProtocol=https;AccountName=" + $deployment_output_table[[DeploymentOutputs]::storageAccountName] + ";AccountKey=" + $deployment_output_table[[DeploymentOutputs]::storageAccountKey] +";EndpointSuffix=core.windows.net"
$output_storagecontainer_ksfull = "crackedfull"
$storage_container_name = $deployment_output_table[[DeploymentOutputs]::storageContainerName]

# Knowledge Store
$content_type = "application/json"
$headers = @{"api-key" = $deployment_output_table[[DeploymentOutputs]::searchApiKey]; "Content-Type" = $content_type}

# Search resources
$datasource_name = $deployment_output_table[[DeploymentOutputs]::prefixName] + "datasource"
$skillset_name = $deployment_output_table[[DeploymentOutputs]::prefixName] + "skillset"
$indexer_name = $deployment_output_table[[DeploymentOutputs]::prefixName] + "indexer"

# Additionals and load from props to make code cleaner later
$cog_service_key = $deployment_output_table[[DeploymentOutputs]::cognitiveServicesKey]
$search_index_name = $deployment_output_table[[DeploymentOutputs]::searchIndexName]

<#
    Build all required URL's that will be needed in future calls
#>
Write-Host("----URLS----")
$data_source_url = constructUrl $search_service  "datasources" $null $null $api_version
Write-Host($data_source_url)
$skill_set_url = constructUrl $search_service  "skillsets" $skillset_name $null $api_version
Write-Host($skill_set_url)
$index_url = constructUrl $search_service  "indexes" $null $null $api_version
Write-Host($index_url)
$indexers_url = constructUrl $search_service  "indexers" $null $null $api_version
Write-Host($indexers_url)
$indexer_status_url = $search_service + "/indexers/" + $indexer_name + "/status?api-version=" + $api_version
Write-Host($indexer_status_url)
$query_parameters = "search=*&`$" + "count=true&`$" + "select=metadata_storage_name"
$search_doc_counts_url = $search_service + "/indexes/" + $search_index_name + "/docs?" + $query_parameters + "&api-version=" + $api_version
Write-Host($search_doc_counts_url)

<#
    Build all required payloads that will be needed in future calls
#>
Write-Host("----PAYLOADS----")

# Data Source
$data_source_json = loadFile "./schemafiles/datasource.json"
if($data_source_json -eq $null){
    exit
}
$data_source_json.name = $datasource_name
$data_source_json.credentials.connectionString = $storage_connection
$data_source_json.container.name = $storage_container_name

# Skillset
$skillset_source_json = loadFile "./schemafiles/skillset.json"
if($skillset_source_json -eq $null){
    exit
}
$skillset_source_json.name = $skillset_name
$skillset_source_json.cognitiveServices.key = $cog_service_key
$skillset_source_json.knowledgeStore.storageConnectionString = $storage_connection
$skillset_source_json.knowledgeStore.projections[1].objects[0].storageContainer = $output_storagecontainer_ksfull

#Index
$index_source_json = loadFile "./schemafiles/index.json"
if($index_source_json -eq $null){
    exit
}
$index_source_json.name = $search_index_name

# Indexer
$indexer_source_json = loadFile "./schemafiles/indexer.json"
if($indexer_source_json -eq $null){
    exit
}
$indexer_source_json.name = $indexer_name 
$indexer_source_json.dataSourceName = $datasource_name
$indexer_source_json.skillsetName = $skillset_name
$indexer_source_json.targetIndexName = $search_index_name


<# ----------------------------------------------------------------------
    

    PROGRAM EXECUTION - mimic Python main() routine

    With everything prepared, fire it off

    PROGRAM EXECUTION - mimic Python main() routine


---------------------------------------------------------------------- #>

$stg_context = getStorageContext $storage_account_name $storage_account_key
if( $stg_context -eq $null){
    Write-Host("Storage context could not be created")
    exit
}

#createContainer()
$stg_container = createStorageContainer $stg_context $storage_container_name
if( $stg_container -eq $null){
    Write-Host("Storage container was NOT created")
    exit
}

#createDataSource()
$resp = makeRequest $data_source_url $headers $data_source_json "POST"
Write-Host("RESPONSE: " + $resp)
validateResponse $resp "Data Source" 204

#createSkillSet()
Write-Host($skill_set_url)
$resp = makeRequest $skill_set_url $headers $skillset_source_json "PUT"
validateResponse $resp "Skill Set" 204

#createIndex()
$resp = makeRequest $index_url $headers $index_source_json  "POST"
validateResponse $resp "Index" 204

#createIndexer()
$resp = makeRequest $indexers_url $headers $indexer_source_json "POST"
validateResponse $resp "Indexer" 204

# Python while loop replaced with single call
getIndexerStatus $indexer_status_url $headers

# uploadSampleDataToBlob()
# uploadSampleDataToBlob './rawdata' $stg_context $storage_container_name

#getSearchDocsCount()
getSearchDocCounts $search_doc_counts_url $headers
