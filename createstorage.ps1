Connect-AzAccount
Set-AzContext -SubscriptionID "63449c7b-0ccf-4fcc-ae6e-200f78a118af"

$resourceGroup = "Lab-AzureFiles-TestCreate"
$location = "canadacentral"
New-AzResourceGroup -Name $resourceGroup -Location $location
$accountName = {"finance","marketing","ops"}

New-AzStorageAccount -ResourceGroupName $resourceGroup `
  -Name $accountName+"-SA" `
  -Location $location `
  -SkuName Standard_ZRS `
  -Kind StorageV2