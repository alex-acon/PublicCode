Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Create the main form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Enhanced Remote File Copy Tool"
$form.Size = New-Object System.Drawing.Size(700,650)
$form.StartPosition = "CenterScreen"

$mainMenu = New-Object System.Windows.Forms.MainMenu

$fileMenu = New-Object System.Windows.Forms.MenuItem "File"
$exitMenuItem = New-Object System.Windows.Forms.MenuItem "Exit"
$exitMenuItem.Add_Click({$form.Close()})
$fileMenu.MenuItems.Add($exitMenuItem)

$helpMenu = New-Object System.Windows.Forms.MenuItem "Help"
$aboutMenuItem = New-Object System.Windows.Forms.MenuItem "About"
$aboutMenuItem.Add_Click({
    [System.Windows.Forms.MessageBox]::Show("About this application", "About", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
})
$helpMenu.MenuItems.Add($aboutMenuItem)

$mainMenu.MenuItems.Add($fileMenu)
$mainMenu.MenuItems.Add($helpMenu)

$form.Menu = $mainMenu

#$profilesPath = "$env:USERPROFILE\RemoteFileCopyProfiles.json"
$profilesPath = "RemoteFileCopyProfiles.json"

# Function to load saved profiles
function Load-Profiles {
    if (Test-Path $profilesPath) {
        $profiles = Get-Content $profilesPath | ConvertFrom-Json
        
        # Convert to hashtable if it's not already one
        if ($profiles -isnot [hashtable]) {
            $hashProfiles = @{}
            # Check if we have any properties to iterate through
            if ($profiles.PSObject.Properties) {
                foreach ($property in $profiles.PSObject.Properties) {
                    $hashProfiles[$property.Name] = $property.Value
                }
            }
            return $hashProfiles
        }
        return $profiles
    }
    return @{}
}

# Function to save profiles
function Save-Profiles($profiles) {
    $profiles | ConvertTo-Json | Set-Content $profilesPath
}

# Remote Host section
$hostLabel = New-Object System.Windows.Forms.Label
$hostLabel.Location = New-Object System.Drawing.Point(20,20)
$hostLabel.Size = New-Object System.Drawing.Size(100,20)
$hostLabel.Text = "Remote Host:"
$form.Controls.Add($hostLabel)

$hostTextBox = New-Object System.Windows.Forms.TextBox
$hostTextBox.Location = New-Object System.Drawing.Point(120,20)
$hostTextBox.Size = New-Object System.Drawing.Size(200,20)
$form.Controls.Add($hostTextBox)

# Profiles Dropdown
$profilesLabel = New-Object System.Windows.Forms.Label
$profilesLabel.Location = New-Object System.Drawing.Point(330,20)
$profilesLabel.Size = New-Object System.Drawing.Size(100,20)
$profilesLabel.Text = "Saved Profiles:"
$form.Controls.Add($profilesLabel)

$profilesComboBox = New-Object System.Windows.Forms.ComboBox
$profilesComboBox.Location = New-Object System.Drawing.Point(430,20)
$profilesComboBox.Size = New-Object System.Drawing.Size(200,20)
$form.Controls.Add($profilesComboBox)

# Populate profiles
$savedProfiles = Load-Profiles
$profilesComboBox.Items.AddRange($savedProfiles.Keys)

# Profile Load Event
$profilesComboBox.Add_SelectedIndexChanged({
    $selectedProfile = $savedProfiles[$profilesComboBox.SelectedItem]
    $hostTextBox.Text = $selectedProfile.Host
    $userTextBox.Text = $selectedProfile.Username
})

# Credentials section
$userLabel = New-Object System.Windows.Forms.Label
$userLabel.Location = New-Object System.Drawing.Point(20,60)
$userLabel.Size = New-Object System.Drawing.Size(100,20)
$userLabel.Text = "Username:"
$form.Controls.Add($userLabel)

$userTextBox = New-Object System.Windows.Forms.TextBox
$userTextBox.Location = New-Object System.Drawing.Point(120,60)
$userTextBox.Size = New-Object System.Drawing.Size(200,20)
$form.Controls.Add($userTextBox)

$passLabel = New-Object System.Windows.Forms.Label
$passLabel.Location = New-Object System.Drawing.Point(20,100)
$passLabel.Size = New-Object System.Drawing.Size(100,20)
$passLabel.Text = "Password:"
$form.Controls.Add($passLabel)

$passTextBox = New-Object System.Windows.Forms.TextBox
$passTextBox.Location = New-Object System.Drawing.Point(120,100)
$passTextBox.Size = New-Object System.Drawing.Size(200,20)
$passTextBox.PasswordChar = '*'
$form.Controls.Add($passTextBox)

# Save Profile Button
$saveProfileButton = New-Object System.Windows.Forms.Button
$saveProfileButton.Location = New-Object System.Drawing.Point(330,60)
$saveProfileButton.Size = New-Object System.Drawing.Size(100,30)
$saveProfileButton.Text = "Save Profile"
$saveProfileButton.Add_Click({
    $profileName = [Microsoft.VisualBasic.Interaction]::InputBox("Enter a name for this profile:", "Save Profile")
    if ($profileName) {
        $savedProfiles[$profileName] = @{
            Host = $hostTextBox.Text
            Username = $userTextBox.Text
        }
        Save-Profiles $savedProfiles
        $profilesComboBox.Items.Add($profileName)
    }
})
$form.Controls.Add($saveProfileButton)

# Multiple File Selection
$filesListView = New-Object System.Windows.Forms.ListView
$filesListView.Location = New-Object System.Drawing.Point(20,140)
$filesListView.Size = New-Object System.Drawing.Size(540,100)
$filesListView.View = 'Details'
$filesListView.FullRowSelect = $true
$filesListView.MultiSelect = $true
$filesListView.Columns.Add('Source File', 400)
$filesListView.Columns.Add('Destination', 140)
$form.Controls.Add($filesListView)

# Add Files Button
$addFilesBtn = New-Object System.Windows.Forms.Button
$addFilesBtn.Location = New-Object System.Drawing.Point(570,140)
$addFilesBtn.Size = New-Object System.Drawing.Size(100,30)
$addFilesBtn.Text = "Add Files"
$addFilesBtn.Add_Click({
    $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $openFileDialog.Multiselect = $true
    $openFileDialog.InitialDirectory = [Environment]::GetFolderPath('Desktop')
    if($openFileDialog.ShowDialog() -eq 'OK'){
        foreach($filename in $openFileDialog.FileNames){
            $listItem = New-Object System.Windows.Forms.ListViewItem($filename)
            $listItem.SubItems.Add((Split-Path $filename -Leaf))
            $filesListView.Items.Add($listItem)
        }
    }
})
$form.Controls.Add($addFilesBtn)

# Remove Files Button
$removeFilesBtn = New-Object System.Windows.Forms.Button
$removeFilesBtn.Location = New-Object System.Drawing.Point(570,180)
$removeFilesBtn.Size = New-Object System.Drawing.Size(100,30)
$removeFilesBtn.Text = "Remove Files"
$removeFilesBtn.Add_Click({
    foreach($item in $filesListView.SelectedItems){
        $filesListView.Items.Remove($item)
    }
})
$form.Controls.Add($removeFilesBtn)

# Destination Folder Selection
$destLabel = New-Object System.Windows.Forms.Label
$destLabel.Location = New-Object System.Drawing.Point(20,250)
$destLabel.Size = New-Object System.Drawing.Size(100,20)
$destLabel.Text = "Destination Folder:"
$form.Controls.Add($destLabel)

$destTextBox = New-Object System.Windows.Forms.TextBox
$destTextBox.Location = New-Object System.Drawing.Point(120,250)
$destTextBox.Size = New-Object System.Drawing.Size(350,20)
$form.Controls.Add($destTextBox)

#$browseBtnDest = New-Object System.Windows.Forms.Button
#$browseBtnDest.Location = New-Object System.Drawing.Point(480,250)
#$browseBtnDest.Size = New-Object System.Drawing.Size(80,20)
#$browseBtnDest.Text = "Browse"
#$browseBtnDest.Add_Click({
#    $folderDialog = New-Object System.Windows.Forms.FolderBrowserDialog
#    $folderDialog.Description = "Select Destination Folder"
#    if($folderDialog.ShowDialog() -eq 'OK'){
#        $destTextBox.Text = $folderDialog.SelectedPath
#    }
#})
#$form.Controls.Add($browseBtnDest)

# Progress Bar
$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Location = New-Object System.Drawing.Point(20,290)
$progressBar.Size = New-Object System.Drawing.Size(540,20)
$progressBar.Minimum = 0
$progressBar.Maximum = 100
$form.Controls.Add($progressBar)

# Status output
$statusBox = New-Object System.Windows.Forms.TextBox
$statusBox.Location = New-Object System.Drawing.Point(20,320)
$statusBox.Size = New-Object System.Drawing.Size(540,180)
$statusBox.Multiline = $true
$statusBox.ScrollBars = "Vertical"
$statusBox.ReadOnly = $true
$form.Controls.Add($statusBox)

# Copy button
$copyButton = New-Object System.Windows.Forms.Button
$copyButton.Location = New-Object System.Drawing.Point(20,520)
$copyButton.Size = New-Object System.Drawing.Size(540,30)
$copyButton.Text = "Copy Files"
$copyButton.Add_Click({
    $statusBox.Clear()
    $progressBar.Value = 0
    $statusBox.AppendText("Starting file copy process...`r`n")
    
    try {
        # Create credential object
        $securePass = ConvertTo-SecureString $passTextBox.Text -AsPlainText -Force
        $cred = New-Object System.Management.Automation.PSCredential ($userTextBox.Text, $securePass)
        
        # Create new PSSession
        $session = New-PSSession -ComputerName $hostTextBox.Text -Credential $cred
        $statusBox.AppendText("Connected to remote host successfully`r`n")
        
        # Copy multiple files
        $totalFiles = $filesListView.Items.Count
        $filesCopied = 0

        foreach($item in $filesListView.Items){
            $sourcePath = $item.Text
            $destPath = [System.IO.Path]::Combine($destTextBox.Text, (Split-Path $sourcePath -Leaf))
            
            # Copy file
            Copy-Item -Path $sourcePath -Destination $destPath -ToSession $session
            
            $filesCopied++
            $progressPercentage = [math]::Floor(($filesCopied / $totalFiles) * 100)
            $progressBar.Value = $progressPercentage
            $statusBox.AppendText("Copied: $sourcePath -> $destPath`r`n")
        }
        
        # Close session
        Remove-PSSession $session
        $statusBox.AppendText("All files copied successfully. Session closed.`r`n")
        $progressBar.Value = 100
    }
    catch {
        $statusBox.AppendText("Error: $($_.Exception.Message)`r`n")
        $progressBar.Value = 0
    }
})
$form.Controls.Add($copyButton)

# Add required assembly for InputBox
Add-Type -AssemblyName Microsoft.VisualBasic

# Show the form
$form.ShowDialog()
