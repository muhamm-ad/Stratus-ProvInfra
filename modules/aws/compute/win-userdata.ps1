<powershell>
# Executed ONLY ONCE by EC2Launch at the first boot.
# No <persist> tag: a reboot or a future apply will not re-execute this script.

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
net user ${username} /expires:$(Get-Date).AddMinutes(10).ToString('MM/dd/yyyy')

# Install OpenSSH Server to allow SSH access to the instance
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
Start-Service sshd
Set-Service -Name sshd -StartupType Automatic

# Extra user_data from caller
${extra}
</powershell>
