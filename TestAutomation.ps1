$resourceGroupName = "191-e188a1d7-deploy-a-web-application-with-terrafo"
$apimServiceName = "testresource55555"
$openapiSpecs ="https://testwebapp5555.azurewebsites.net/swagger/v1/swagger.json"
$apiGlobalPolicy = "$(System.ArtifactsDirectory)\$(Release.PrimaryArtifactSourceAlias)\drop\$(api-policy.xml)"
$apiPath = ""
$apiId = "simpleapi"
$apiVersion = ""
$apiName = "SimpleAPI"
$apiProtocols = @('https')
$apiServiceUrl = "https://testwebapp5555.azurewebsites.net"
$subscription = "P1-Real Hands-On Labs"
$productNames = @("Test Product1", "Test Product 2", "Test Product 3")
$oAuthServer = "OAuth2Service"

Connect-AzAccount

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

Write-Host "Adding Product to API"
foreach ($productName in $productNames) {
	$productId = $(Get-AzApiManagementProduct -Context $ApiMgmtContext -Title $productTitle).ProductId
	Add-AzApiManagementApiToProduct -Context $context -ProductId "$productId" -ApiId "$apiId$apiVersion"
}

if (Test-Path $oAuthServer)
{
	Write-Host "Setting OAuth Server"
	Set-AzApiManagementApi -Context $ApiMgmtContext -ApiId "$apiId" -AuthorizationServerId "$oAuthServer" -AuthorizationScope ""
}
