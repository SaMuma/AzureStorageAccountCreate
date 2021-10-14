
#reference docs: https://docs.microsoft.com/en-us/powershell/module/az.storage/new-azstorageaccount?view=azps-6.5.0
###The sample scripts are not supported under any Microsoft standard support program or service. The sample scripts are provided AS IS without warranty of any kind. Microsoft further disclaims all implied warranties including, without limitation, any implied warranties of merchantability or of fitness for a particular purpose. The entire risk arising out of the use or performance of the sample scripts and documentation remains with you. In no event shall Microsoft, its authors, or anyone else involved in the creation, production, or delivery of the scripts be liable for any damages whatsoever (including, without limitation, damages for loss of business profits, business interruption, loss of business information, or other pecuniary loss) arising out of the use of or inability to use the sample scripts or documentation, even if Microsoft has been advised of the possibility of such damages.

Connect-AzAccount
Set-AzContext -SubscriptionID "<insert subscription ID here>"

#SET VARIABLES
$resourceGroup = "<ResourceGroupName>"
$location = "canadacentral"
$sasuffix = "<uniquestring>sa"
$fssuffix = "<uniquestring>slmfs"
$sgsuffix = "<uniquestring>slmsg"
$syncServiceName = "<StorageSyncServiceName>"
$cloudEndpointName = "<CloudEndpointName>"
$tenant = "<AzureTenantID>"

#Fill in with your desired storage account names, delimited by commas. 
#storage account names need to be globally unique and less than 24 characters. 
$COOLaccountNames = @("accountname")
$HOTaccountNames = @("accountname","accountname")
$ALLaccountNames = $COOLaccountNames+$HOTaccountNames

#CREATE RESOURCE GROUP
New-AzResourceGroup -Name $resourceGroup -Location $location

#CREATE COOL STORAGE ACCOUNTS
foreach ($item in $COOLaccountNames) {
    New-AzStorageAccount -ResourceGroupName $resourceGroup `
    -Name $item$sasuffix `
    -Location $location `
    -SkuName Standard_ZRS `
    -AccessTier Cool `
    -Kind StorageV2
    
    $key = (Get-AzStorageAccountKey -ResourceGroupName $resourceGroup -StorageAccountName $item$sasuffix)[0].value
    $context = New-AzStorageContext -StorageAccountName $item$sasuffix -StorageAccountKey $key
    
    #All file shares will be created as Transaction Optimized and can be changed manually after deployment
    New-AzStorageShare -Name $item$fssuffix -Context $context
}

#CREATE HOT STORAGE ACCOUNTS
foreach ($item in $HOTaccountNames) {
    New-AzStorageAccount -ResourceGroupName $resourceGroup `
    -Name $item$sasuffix `
    -Location $location `
    -SkuName Standard_ZRS `
    -AccessTier Hot `
    -Kind StorageV2
    
    $key = (Get-AzStorageAccountKey -ResourceGroupName $resourceGroup -StorageAccountName $item$sasuffix)[0].value
    $context = New-AzStorageContext -StorageAccountName $item$sasuffix -StorageAccountKey $key
    
    #All file shares will be created as Transaction Optimized and can be changed manually after deployment
    New-AzStorageShare -Name $item$fssuffix -Context $context
}

#CREATE SYNC SERVICE
$syncservice = New-AzStorageSyncService `
-ResourceGroupName $resourceGroup `
-Location $location `
-StorageSyncServiceName $syncServiceName

#CREATE SYNC GROUPS WITH CLOUD ENDPOINTS - run after giving the storage sync service a few minutes to spin up
foreach ($item in $ALLaccountNames) {
    $syncgroup = (New-AzStorageSyncGroup `
    -ResourceGroupName $resourceGroup `
    -StorageSyncServiceName $syncservice `
    -Name $item$sgsuffix).SyncGroupName

    New-AzStorageSyncCloudEndpoint `
    -ResourceGroupName $resourceGroup `
    -StorageSyncServiceName $syncservice `
    -SyncGroupName $syncgroup `
    -Name $cloudEndpointName `
    -StorageAccountResourceId (Get-AzStorageAccount -ResourceGroupName $resourceGroup -Name $item$sasuffix).Id `
    -AzureFileShareName $item$fssuffix `
    -StorageAccountTenantId $tenant
}



