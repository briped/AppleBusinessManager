[PSCustomObject]@{
    TokenAlgorithm = 'ES256'
    KeyId = Read-Host -AsSecureString -Prompt 'Key ID'
    TokenType = 'JWT'
    TokenUrl = 'https://account.apple.com/auth/oauth2/v2/token'
    ClientId = Read-Host -AsSecureString -Prompt 'Client ID'
    TeamId = Read-Host -AsSecureString -Prompt 'Client ID'
    PrivateKey = Read-Host -AsSecureString -Prompt 'Private Key'
} | Export-Clixml -Force -Path ".apiData.xml"
