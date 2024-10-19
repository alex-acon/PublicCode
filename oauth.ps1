Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Function to perform the OAuth 2.0 authorization code flow
function Get-OAuthToken {
    param (
        [string]$ClientId,
        [string]$ResourceId,
        [string]$RedirectUri,
        [string]$AuthEndpoint,
        [string]$TokenEndpoint
    )

    # Construct the authorization URL
    $authUrl = "$AuthEndpoint?response_type=code&client_id=$ClientId&resource=$ResourceId&redirect_uri=$RedirectUri"

    # Open the authorization URL in the default browser
    Start-Process $authUrl

    # Prompt the user to enter the authorization code
    $authCode = Read-Host "Enter the authorization code"

    # Exchange the authorization code for a token
    $body = @{
        grant_type    = "authorization_code"
        code          = $authCode
        redirect_uri  = $RedirectUri
        client_id     = $ClientId
        resource      = $ResourceId
    }

    $response = Invoke-RestMethod -Uri $TokenEndpoint -Method Post -Body $body

    return $response.access_token
}

# Create the form
$form = New-Object System.Windows.Forms.Form
$form.Text = "OAuth 2.0 Token Generator"
$form.Size = New-Object System.Drawing.Size(400,300)
$form.StartPosition = "CenterScreen"

# Create labels and textboxes for input fields
$labelClientId = New-Object System.Windows.Forms.Label
$labelClientId.Text = "Client ID:"
$labelClientId.Location = New-Object System.Drawing.Point(10,20)
$form.Controls.Add($labelClientId)

$textBoxClientId = New-Object System.Windows.Forms.TextBox
$textBoxClientId.Location = New-Object System.Drawing.Point(100,20)
$textBoxClientId.Size = New-Object System.Drawing.Size(250,20)
$form.Controls.Add($textBoxClientId)

$labelResourceId = New-Object System.Windows.Forms.Label
$labelResourceId.Text = "Resource ID:"
$labelResourceId.Location = New-Object System.Drawing.Point(10,50)
$form.Controls.Add($labelResourceId)

$textBoxResourceId = New-Object System.Windows.Forms.TextBox
$textBoxResourceId.Location = New-Object System.Drawing.Point(100,50)
$textBoxResourceId.Size = New-Object System.Drawing.Size(250,20)
$form.Controls.Add($textBoxResourceId)

$labelRedirectUri = New-Object System.Windows.Forms.Label
$labelRedirectUri.Text = "Redirect URI:"
$labelRedirectUri.Location = New-Object System.Drawing.Point(10,80)
$form.Controls.Add($labelRedirectUri)

$textBoxRedirectUri = New-Object System.Windows.Forms.TextBox
$textBoxRedirectUri.Location = New-Object System.Drawing.Point(100,80)
$textBoxRedirectUri.Size = New-Object System.Drawing.Size(250,20)
$form.Controls.Add($textBoxRedirectUri)

# Create radio buttons for environment selection
$labelEnvironment = New-Object System.Windows.Forms.Label
$labelEnvironment.Text = "Environment:"
$labelEnvironment.Location = New-Object System.Drawing.Point(10,110)
$form.Controls.Add($labelEnvironment)

$radioButtonProduction = New-Object System.Windows.Forms.RadioButton
$radioButtonProduction.Text = "Production"
$radioButtonProduction.Location = New-Object System.Drawing.Point(100,110)
$form.Controls.Add($radioButtonProduction)

$radioButtonUAT = New-Object System.Windows.Forms.RadioButton
$radioButtonUAT.Text = "UAT"
$radioButtonUAT.Location = New-Object System.Drawing.Point(100,135)
$form.Controls.Add($radioButtonUAT)

$radioButtonDevelopment = New-Object System.Windows.Forms.RadioButton
$radioButtonDevelopment.Text = "Development"
$radioButtonDevelopment.Location = New-Object System.Drawing.Point(100,160)
$form.Controls.Add($radioButtonDevelopment)

# Create a button to get the token
$buttonGetToken = New-Object System.Windows.Forms.Button
$buttonGetToken.Text = "Get Token"
$buttonGetToken.Location = New-Object System.Drawing.Point(150,190)
$buttonGetToken.Size = New-Object System.Drawing.Size(100,30)
$form.Controls.Add($buttonGetToken)

# Create a label to display the token
$labelToken = New-Object System.Windows.Forms.Label
$labelToken.Text = "Token:"
$labelToken.Location = New-Object System.Drawing.Point(10,230)
$form.Controls.Add($labelToken)

$textBoxToken = New-Object System.Windows.Forms.TextBox
$textBoxToken.Location = New-Object System.Drawing.Point(100,230)
$textBoxToken.Size = New-Object System.Drawing.Size(250,20)
$textBoxToken.ReadOnly = $true
$form.Controls.Add($textBoxToken)

# Event handler for the button click
$buttonGetToken.Add_Click({
    $clientId = $textBoxClientId.Text
    $resourceId = $textBoxResourceId.Text
    $redirectUri = $textBoxRedirectUri.Text

    if ($radioButtonProduction.Checked) {
        $authEndpoint = "https://login.production.com/oauth2/authorize"
        $tokenEndpoint = "https://login.production.com/oauth2/token"
    } elseif ($radioButtonUAT.Checked) {
        $authEndpoint = "https://login.uat.com/oauth2/authorize"
        $tokenEndpoint = "https://login.uat.com/oauth2/token"
    } elseif ($radioButtonDevelopment.Checked) {
        $authEndpoint = "https://login.development.com/oauth2/authorize"
        $tokenEndpoint = "https://login.development.com/oauth2/token"
    } else {
        [System.Windows.Forms.MessageBox]::Show("Please select an environment.", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        return
    }

    $token = Get-OAuthToken -ClientId $clientId -ResourceId $resourceId -RedirectUri $redirectUri -AuthEndpoint $authEndpoint -TokenEndpoint $tokenEndpoint
    $textBoxToken.Text = $token
})

# Show the form
$form.Add_Shown({$form.Activate()})
[void] $form.ShowDialog()
