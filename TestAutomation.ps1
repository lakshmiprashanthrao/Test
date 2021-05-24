$resourceGroupName = "TestResourceGroup"
$apimServiceName = "TestApi5555"
$openapiSpecs ="https://testwebapp5555.azurewebsites.net/swagger/v1/swagger.json"
$apiGlobalPolicy = "api-policy.xml" 
$apiPath = ""
$apiId = "simpleapi"
$apiVersion = ""
$apiName = "SimpleAPI"
$apiProtocols = @('https')
$apiServiceUrl = "https://testwebapp5555.azurewebsites.net"
$subscription = "Free Trial"
$productId = "testproduct"

#Connect to Azure using Az Module
Connect-AzAccount
 
#Return all subscription
Get-AzSubscription
Set-AzContext -Subscription "$subscription"

# Create the API Management context
$context = New-AzApiManagementContext -ResourceGroupName $resourceGroupName -ServiceName $apimServiceName

# Version Set - Check if already exists, or create new
Write-Host "Performing versionset lookup. "
$versionSetLookup = Get-AzApiManagementApiVersionSet -Context $context | Where-Object { $_.DisplayName -eq "$apiName" }  | Sort-Object -Property ApiVersionSetId -Descending | Select-Object -first 1
if($versionSetLookup -eq $null)
{
	Write-Host "Version set NOT FOUND,creating a new one."
	$versionSet = New-AzApiManagementApiVersionSet -Context $context -Name "$apiName" -Scheme Segment -Description "$apiName"
	$versionSetId = $versionSet.Id
	Write-Host "Versionset id: $versionSetId"
}
else
{
	Write-Host "Version set FOUND, using existing one."
	$versionSetId = $versionSetLookup.ApiVersionSetId
	Write-Host "Versionset id: $versionSetId"
}
 
# import api from OpenAPI Specs
Write-Host  "Importing OpenAPI"
$api = Import-AzApiManagementApi -Context $context -SpecificationUrl $openapiSpecs -SpecificationFormat OpenApi -Path $apiPath -ApiId "$apiId$apiVersion" -ApiVersion $apiVersion -ApiVersionSetId $versionSetId -ServiceUrl $apiServiceUrl -Protocol $apiProtocols
Write-Host  "Imported API: $api.ApiId " 

# Apply Global Policy if existing
if (Test-Path $apiGlobalPolicy)
{
    Write-Host "applying Global Policy $apiGlobalPolicy "
    Set-AzApiManagementPolicy -Context $context -PolicyFilePath $apiGlobalPolicy -ApiId $api.ApiId
    Write-Host "Global Policy applied. "
}
else
{
    Write-Host "Global Policy NOT FOUND. skipping : $apiGlobalPolicy "
}

# Add Existing Product to API
Write-Host "Added Product to API"
Add-AzApiManagementApiToProduct -Context $context -ProductId "$productId" -ApiId "$apiId$apiVersion"
