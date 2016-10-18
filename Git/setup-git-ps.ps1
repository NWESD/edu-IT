# Variables for setting up git
$name = "<yourname>"
$email = "<email>"
# if you have a web proxy add it in the format "http://proxy.work.com:8080"
$proxy = ""


#Install the powershell git module

Find-module posh-git | install-module

# Add the git path to the sytem path

$MyPath = $env:Path + ";" + "${env:ProgramFiles}\git\cmd"
[Environment]::SetEnvironmentVariable("Path", $($MyPath ), "Machine")

# Update the path so you don't have to restart the shell
$env:Path = $MyPath


Import-Module posh-git

# Get module version so you can run the install script
$mod_version = Get-Module -name posh-git | select version
$mod_version = $mod_version.Version.ToString()

& "C:\Program Files\WindowsPowerShell\Modules\posh-git\$mod_version\Install.ps1"

# Reload your powershell profile
. $profile



git config --global user.name $name
git config --global user.email $email
git config --global http.proxy $proxy
