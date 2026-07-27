# Shared Windows bootstrap across AWS, Azure, and GCP.
# On AWS: wrapped in <powershell> tags via user_data (runs once at first boot).
# On Azure: applied via azurerm_virtual_machine_run_command.
# On GCP: set as windows-startup-script-ps1 metadata.
# Terraform templatefile interpolates ${username}, ${password_to_change}, and ${extra}.

if ('${username}' -ne '' -and '${password_to_change}' -ne '') {
    # Create the local user with the initial password
    $Password = ConvertTo-SecureString '${password_to_change}' -AsPlainText -Force
    New-LocalUser -Name '${username}' -Password $Password -FullName '${username}' -Description 'Created by Terraform via user_data'

    # Rights: local administrator + RDP access
    Add-LocalGroupMember -Group 'Administrators' -Member '${username}'
    Add-LocalGroupMember -Group 'Remote Desktop Users' -Member '${username}'

    # Force password change at first login.
    # The initial password (visible in user_data) becomes unusable after the first login.
    # net user '${username}' /logonpasswordchg:yes

    # Set password to expire in 10 minutes
    net user '${username}' /expires:$(Get-Date).AddMinutes(10).ToString('MM/dd/yyyy')
}

# Install OpenSSH Server to allow SSH access to the instance
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
Start-Service sshd
Set-Service -Name sshd -StartupType Automatic

# Extra user_data from caller
${extra}
