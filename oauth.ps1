Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Function to perform the OAuth 2.0 authorization code flow
function Get-OAuthToken {
    param (
        [string]$ClientId,
        [string]$ResourceId,
        [string]$RedirectUri,
        [string]$AuthEndpoint,
        [string]$TokenEndpoint,
        [string]$AuthCode,
        [bool]$RequireCredentials = $false
    )

    # Exchange the authorization code for a token
    $body = @{
        grant_type    = "authorization_code"
        code          = $AuthCode
        redirect_uri  = $RedirectUri
        client_id     = $ClientId
        resource      = $ResourceId
    }

    if ($RequireCredentials) {
        # Prompt for credentials
        $credential = $host.ui.PromptForCredential("Token Endpoint Credentials", "Please enter your credentials for the token endpoint:", "", "")
        if (-not $credential) {
            throw "Credentials are required for the token endpoint."
        }

        $username = $credential.UserName
        $password = $credential.GetNetworkCredential().Password

        # Add credentials to the body
        $body.Add("username", $username)
        $body.Add("password", $password)
    }

    $response = Invoke-RestMethod -Uri $TokenEndpoint -Method Post -Body $body

    return $response.access_token
}

# Function to validate Active Directory credentials and check an attribute
function Validate-ADCredentials {
    param (
        [string]$Username,
        [string]$Password,
        [string]$Attribute
    )

    try {
        $domain = "yourdomain.com"  # Replace with your domain
        $securePassword = ConvertTo-SecureString $Password -AsPlainText -Force
        $credentials = New-Object System.Management.Automation.PSCredential($Username, $securePassword)

        $user = Get-ADUser -Identity $Username -Credential $credentials -Properties $Attribute -ErrorAction Stop

        if ($user.$Attribute -eq $true) {  # Replace with your attribute check logic
            return $true
        } else {
            return $false
        }
    } catch {
        return $false
    }
}

# Create the form
$form = New-Object System.Windows.Forms.Form
$form.Text = "OAuth 2.0 Token Generator"
$form.Size = New-Object System.Drawing.Size(500,450)
$form.StartPosition = "CenterScreen"

# Create labels and textboxes for input fields
$labelClientId = New-Object System.Windows.Forms.Label
$labelClientId.Text = "Client ID:"
$labelClientId.Location = New-Object System.Drawing.Point(10,20)
$form.Controls.Add($labelClientId)

$textBoxClientId = New-Object System.Windows.Forms.TextBox
$textBoxClientId.Location = New-Object System.Drawing.Point(100,20)
$textBoxClientId.Size = New-Object System.Drawing.Size(350,25)
$form.Controls.Add($textBoxClientId)

$labelResourceId = New-Object System.Windows.Forms.Label
$labelResourceId.Text = "Resource ID:"
$labelResourceId.Location = New-Object System.Drawing.Point(10,60)
$form.Controls.Add($labelResourceId)

$textBoxResourceId = New-Object System.Windows.Forms.TextBox
$textBoxResourceId.Location = New-Object System.Drawing.Point(100,60)
$textBoxResourceId.Size = New-Object System.Drawing.Size(350,25)
$form.Controls.Add($textBoxResourceId)

$labelRedirectUri = New-Object System.Windows.Forms.Label
$labelRedirectUri.Text = "Redirect URI:"
$labelRedirectUri.Location = New-Object System.Drawing.Point(10,100)
$form.Controls.Add($labelRedirectUri)

$textBoxRedirectUri = New-Object System.Windows.Forms.TextBox
$textBoxRedirectUri.Location = New-Object System.Drawing.Point(100,100)
$textBoxRedirectUri.Size = New-Object System.Drawing.Size(350,25)
$form.Controls.Add($textBoxRedirectUri)

# Create radio buttons for environment selection
$labelEnvironment = New-Object System.Windows.Forms.Label
$labelEnvironment.Text = "Environment:"
$labelEnvironment.Location = New-Object System.Drawing.Point(10,140)
$form.Controls.Add($labelEnvironment)

$radioButtonProduction = New-Object System.Windows.Forms.RadioButton
$radioButtonProduction.Text = "Production"
$radioButtonProduction.Location = New-Object System.Drawing.Point(100,140)
$form.Controls.Add($radioButtonProduction)

$radioButtonUAT = New-Object System.Windows.Forms.RadioButton
$radioButtonUAT.Text = "UAT"
$radioButtonUAT.Location = New-Object System.Drawing.Point(100,170)
$form.Controls.Add($radioButtonUAT)

$radioButtonDevelopment = New-Object System.Windows.Forms.RadioButton
$radioButtonDevelopment.Text = "Development"
$radioButtonDevelopment.Location = New-Object System.Drawing.Point(100,200)
$form.Controls.Add($radioButtonDevelopment)

# Create a button to get the token
$buttonGetToken = New-Object System.Windows.Forms.Button
$buttonGetToken.Text = "Get Token"
$buttonGetToken.Location = New-Object System.Drawing.Point(200,240)
$buttonGetToken.Size = New-Object System.Drawing.Size(100,30)
$form.Controls.Add($buttonGetToken)

# Create a label and textbox for the authorization code
$labelAuthCode = New-Object System.Windows.Forms.Label
$labelAuthCode.Text = "Authorization Code:"
$labelAuthCode.Location = New-Object System.Drawing.Point(10,280)
$form.Controls.Add($labelAuthCode)

$textBoxAuthCode = New-Object System.Windows.Forms.TextBox
$textBoxAuthCode.Location = New-Object System.Drawing.Point(150,280)
$textBoxAuthCode.Size = New-Object System.Drawing.Size(300,25)
$form.Controls.Add($textBoxAuthCode)

# Create a label to display the token
$labelToken = New-Object System.Windows.Forms.Label
$labelToken.Text = "Token:"
$labelToken.Location = New-Object System.Drawing.Point(10,320)
$form.Controls.Add($labelToken)

$textBoxToken = New-Object System.Windows.Forms.TextBox
$textBoxToken.Location = New-Object System.Drawing.Point(100,320)
$textBoxToken.Size = New-Object System.Drawing.Size(350,125)  # Change the height to 125 (5 times the original height of 25)
$textBoxToken.ReadOnly = $true
$textBoxToken.Multiline = $true  # Enable multiline for the textbox
$textBoxToken.ScrollBars = [System.Windows.Forms.ScrollBars]::Vertical  # Add vertical scrollbars
$form.Controls.Add($textBoxToken)

# Create a button to copy the token to the clipboard
$buttonCopyToken = New-Object System.Windows.Forms.Button
$buttonCopyToken.Text = "Copy Token"
$buttonCopyToken.Location = New-Object System.Drawing.Point(200,450)
$buttonCopyToken.Size = New-Object System.Drawing.Size(100,30)
$form.Controls.Add($buttonCopyToken)

# Event handler for the "Get Token" button click
$buttonGetToken.Add_Click({
    $clientId = $textBoxClientId.Text
    $resourceId = $textBoxResourceId.Text
    $redirectUri = $textBoxRedirectUri.Text
    $authCode = $textBoxAuthCode.Text

    if ($radioButtonProduction.Checked) {
        $authEndpoint = "https://login.production.com/oauth2/authorize"
        $tokenEndpoint = "https://login.production.com/oauth2/token"
        $requireCredentials = $false
    } elseif ($radioButtonUAT.Checked) {
        $authEndpoint = "https://login.uat.com/oauth2/authorize"
        $tokenEndpoint = "https://login.uat.com/oauth2/token"
        $requireCredentials = $false
    } elseif ($radioButtonDevelopment.Checked) {
        $authEndpoint = "https://login.development.com/oauth2/authorize"
        $tokenEndpoint = "https://login.development.com/oauth2/token"
        $requireCredentials = $true

        # Prompt for credentials
        $credential = $host.ui.PromptForCredential("Active Directory Credentials", "Please enter your credentials:", "", "")
        if (-not $credential) {
            [System.Windows.Forms.MessageBox]::Show("Credentials are required for the Development environment.", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
            return
        }

        $username = $credential.UserName
        $password = $credential.GetNetworkCredential().Password

        # Validate Active Directory credentials and check an attribute
        if (-not (Validate-ADCredentials -Username $username -Password $password -Attribute "yourAttribute")) {  # Replace with your attribute
            [System.Windows.Forms.MessageBox]::Show("Invalid credentials or attribute check failed.", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
            return
        }
    } else {
        [System.Windows.Forms.MessageBox]::Show("Please select an environment.", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        return
    }

    # Construct the authorization URL
    $authUrl = "$authEndpoint?response_type=code&client_id=$clientId&resource=$resourceId&redirect_uri=$redirectUri"

    # Open the authorization URL in the default browser
    Start-Process $authUrl

    # Prompt the user to enter the authorization code
    [System.Windows.Forms.MessageBox]::Show("Please copy the authorization code from the browser and paste it into the Authorization Code field.", "Authorization Code", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)

    $token = Get-OAuthToken -ClientId $clientId -ResourceId $resourceId -RedirectUri $redirectUri -AuthEndpoint $authEndpoint -TokenEndpoint $tokenEndpoint -AuthCode $authCode -RequireCredentials $requireCredentials
    $textBoxToken.Text = $token
})

# Event handler for the "Copy Token" button click
$buttonCopyToken.Add_Click({
    if ($textBoxToken.Text) {
        [System.Windows.Forms.Clipboard]::SetText($textBoxToken.Text)
        [System.Windows.Forms.MessageBox]::Show("Token copied to clipboard.", "Success", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    } else {
        [System.Windows.Forms.MessageBox]::Show("No token to copy.", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
})

# Show the form
$form.Add_Shown({$form.Activate()})
[void] $form.ShowDialog()
