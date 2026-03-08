[PSCustomObject]@{
    KeyId = Read-Host -Prompt 'Key ID'
    ClientId = Read-Host -Prompt 'Client ID'
    PrivateKey = Read-Host -AsSecureString -Prompt 'Private Key'
} | Export-Clixml -Force -Path ".claimsData.xml"
