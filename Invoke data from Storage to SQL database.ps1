$rgname = "AngloAmerican"
$location = "northeurope"
$adminlogin = "azureadmin"
$password = "Anglo@123"
$servername = "mneu-db-p-ods-001"
$databasename = "mneu-p-paas-ods-001"
$storageaccountname = "demostor1702"
$storagecontainername = "demoanglo"
# BACPAC file name
$sqlfilename = "table.sql"
# The ip address range that you want to allow to access your server
$startip = "0.0.0.0"
$endip = "0.0.0.0"

# Create a storage account 
$storageaccount = New-AzureRMStorageAccount -Name $storageaccountname -ResourceGroupName $rgname -Location "northeurope" -SkuName Standard_LRS

# For getting key
New-AzureRmStorageAccountKey -ResourceGroupName $rgname -Name $storageaccountname
$key1= (Get-AzureRmStorageAccountKey -ResourceGroupName $rgname -Name $storageaccountname).value
$key1

# Creating context variable
New-AzureStorageContext -StorageAccountName $storageaccountname -StorageAccountKey $key1.GetValue(0)
$context = New-AzureStorageContext -StorageAccountName $storageaccountname -StorageAccountKey $key1.GetValue(0)
$context

# Create a storage container 
New-AzureStorageContainer -Name $storagecontainername -Permission blob -Context $context

# Download sample database from Github
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 #required by Github
Invoke-WebRequest -Uri "https://github.com/Microsoft/sql-server-samples/releases/download/wide-world-importers-v1.0/WideWorldImporters-Standard.bacpac" -OutFile $sqlfilename

# Upload sample database into storage container
Set-AzureStorageBlobContent -Container $storagecontainername `
    -File $bacpacfilename `
    -Context $(New-AzureStorageContext -StorageAccountName $storageaccountname `
        -StorageAccountKey $(Get-AzureRmStorageAccountKey -ResourceGroupName $rgname -StorageAccountName $storageaccountname).Value[0])


# Import bacpac to database with an S3 performance level
$importRequest = New-AzureRmSqlDatabaseImport -ResourceGroupName $rgname `
    -ServerName $servername `
    -DatabaseName $databasename `
    -DatabaseMaxSizeBytes "262144000" `
    -StorageKeyType "StorageAccessKey" `
    -StorageKey $(Get-AzureRmStorageAccountKey -ResourceGroupName $rgname -StorageAccountName $storageaccountname).Value[0] `
    -StorageUri "http://$storageaccountname.blob.core.windows.net/$storagecontainername/$sqlfilename" `
    -Edition "Standard" `
    -ServiceObjectiveName "S3" `
    -AdministratorLogin "$adminlogin" `
    -AdministratorLoginPassword $(ConvertTo-SecureString -String $password -AsPlainText -Force)

# Check import status and wait for the import to complete
$importStatus = Get-AzureRmSqlDatabaseImportExportStatus -OperationStatusLink $importRequest.OperationStatusLink
[Console]::Write("Importing")
while ($importStatus.Status -eq "InProgress")
{
    $importStatus = Get-AzureRmSqlDatabaseImportExportStatus -OperationStatusLink $importRequest.OperationStatusLink
    [Console]::Write(".")
    Start-Sleep -s 10
}
[Console]::WriteLine("")
$importStatus

# Scale down to S0 after import is complete
Set-AzureRmSqlDatabase -ResourceGroupName $rgname `
    -ServerName $servername `
    -DatabaseName $databasename  `
    -Edition "Standard" `
    -RequestedServiceObjectiveName "S0"

# Clean up deployment 
# Remove-AzureRmResourceGroup -ResourceGroupName $resourcegroupname