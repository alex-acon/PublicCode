# Load Windows Forms assembly
Add-Type -AssemblyName System.Windows.Forms

# Create a new form
$form = New-Object System.Windows.Forms.Form
$form.Text = "OAuth Input"
$form.Size = New-Object System.Drawing.Size(300,200)
$form.StartPosition = "CenterScreen"

# Create labels and text boxes
$labels = @("Client ID:", "Resource ID:", "Redirect URI:")
$textBoxes = @()

for ($i = 0; $i -lt $labels.Length; $i++) {
    $label = New-Object System.Windows.Forms.Label
    $label.Text = $labels[$i]
    $label.AutoSize = $true
    $label.Location = New-Object System.Drawing.Point(10, 20 + ($i * 40))
    $form.Controls.Add($label)

    $textBox = New-Object System.Windows.Forms.TextBox
    $textBox.Location = New-Object System.Drawing.Point(100, 20 + ($i * 40))
    $textBox.Size = New-Object System.Drawing.Size(150, 20)
    $form.Controls.Add($textBox)
    $textBoxes += $textBox
}

# Create a submit button
$submitButton = New-Object System.Windows.Forms.Button
$submitButton.Location = New-Object System.Drawing.Point(100, 140)
$submitButton.Size = New-Object System.Drawing.Size(75, 25)
$submitButton.Text = "Submit"
$submitButton.Add_Click({
    $clientId = $textBoxes[0].Text
    $resourceId = $textBoxes[1].Text
    $redirectUri = $textBoxes[2].Text

    # Output the values (you can handle them as required here)
    [System.Windows.Forms.MessageBox]::Show("Client ID: $clientId`nResource ID: $resourceId`nRedirect URI: $redirectUri")
    
    # Optionally, close the form after submission
    $form.Close()
})
$form.Controls.Add($submitButton)

# Show the form
$form.ShowDialog()
