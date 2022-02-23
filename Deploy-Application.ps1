<#
.SYNOPSIS
	This script performs the installation or uninstallation of an application(s).
	# LICENSE #
	PowerShell App Deployment Toolkit - Provides a set of functions to perform common application deployment tasks on Windows.
	Copyright (C) 2017 - Sean Lillis, Dan Cunningham, Muhammad Mashwani, Aman Motazedian.
	This program is free software: you can redistribute it and/or modify it under the terms of the GNU Lesser General Public License as published by the Free Software Foundation, either version 3 of the License, or any later version. This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
	You should have received a copy of the GNU Lesser General Public License along with this program. If not, see <http://www.gnu.org/licenses/>.
.DESCRIPTION
	The script is provided as a template to perform an install or uninstall of an application(s).
	The script either performs an "Install" deployment type or an "Uninstall" deployment type.
	The install deployment type is broken down into 3 main sections/phases: Pre-Install, Install, and Post-Install.
	The script dot-sources the AppDeployToolkitMain.ps1 script which contains the logic and functions required to install or uninstall an application.
.PARAMETER DeploymentType
	The type of deployment to perform. Default is: Install.
.PARAMETER DeployMode
	Specifies whether the installation should be run in Interactive, Silent, or NonInteractive mode. Default is: Interactive. Options: Interactive = Shows dialogs, Silent = No dialogs, NonInteractive = Very silent, i.e. no blocking apps. NonInteractive mode is automatically set if it is detected that the process is not user interactive.
.PARAMETER AllowRebootPassThru
	Allows the 3010 return code (requires restart) to be passed back to the parent process (e.g. SCCM) if detected from an installation. If 3010 is passed back to SCCM, a reboot prompt will be triggered.
.PARAMETER TerminalServerMode
	Changes to "user install mode" and back to "user execute mode" for installing/uninstalling applications for Remote Destkop Session Hosts/Citrix servers.
.PARAMETER DisableLogging
	Disables logging to file for the script. Default is: $false.
.EXAMPLE
    powershell.exe -Command "& { & '.\Deploy-Application.ps1' -DeployMode 'Silent'; Exit $LastExitCode }"
.EXAMPLE
    powershell.exe -Command "& { & '.\Deploy-Application.ps1' -AllowRebootPassThru; Exit $LastExitCode }"
.EXAMPLE
    powershell.exe -Command "& { & '.\Deploy-Application.ps1' -DeploymentType 'Uninstall'; Exit $LastExitCode }"
.EXAMPLE
    Deploy-Application.exe -DeploymentType "Install" -DeployMode "Silent"
.NOTES
	Toolkit Exit Code Ranges:
	60000 - 68999: Reserved for built-in exit codes in Deploy-Application.ps1, Deploy-Application.exe, and AppDeployToolkitMain.ps1
	69000 - 69999: Recommended for user customized exit codes in Deploy-Application.ps1
	70000 - 79999: Recommended for user customized exit codes in AppDeployToolkitExtensions.ps1
.LINK
	http://psappdeploytoolkit.com
#>

## Suppress PSScriptAnalyzer errors for not using declared variables during AppVeyor build
[Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", "", Justification="Suppress AppVeyor errors on unused variables below")]

[CmdletBinding()]
Param (
	[Parameter(Mandatory=$false)]
	[ValidateSet('Install','Uninstall','Repair')]
	[string]$DeploymentType = 'Install',
	[Parameter(Mandatory=$false)]
	[ValidateSet('Interactive','Silent','NonInteractive')]
	[string]$DeployMode = 'Interactive',
	[Parameter(Mandatory=$false)]
	[switch]$AllowRebootPassThru = $false,
	[Parameter(Mandatory=$false)]
	[switch]$TerminalServerMode = $false,
	[Parameter(Mandatory=$false)]
	[switch]$DisableLogging = $false
)

Try {
	## Set the script execution policy for this process
	Try { Set-ExecutionPolicy -ExecutionPolicy 'ByPass' -Scope 'Process' -Force -ErrorAction 'Stop' } Catch { Write-Error "Failed to set the execution policy to Bypass for this process." }

	##*===============================================
	##* VARIABLE DECLARATION
	##*===============================================
	## Variables: Application
	[string]$appVendor = ''
	[string]$appName = 'Audacity'
	[string]$appVersion = ''
	[string]$appArch = ''
	[string]$appLang = 'EN'
	[string]$appRevision = '01'
	[string]$appScriptVersion = '3.1.3'
	[string]$appScriptDate = '02/08/2022'
	[string]$appScriptAuthor = 'Ryan McKenna'
	##*===============================================
	## Variables: Install Titles (Only set here to override defaults set by the toolkit)
	[string]$installName = ''
	[string]$installTitle = ''

	##* Do not modify section below
	#region DoNotModify

	## Variables: Exit Code
	[int32]$mainExitCode = 0

	## Variables: Script
	[string]$deployAppScriptFriendlyName = 'Deploy Application'
	[version]$deployAppScriptVersion = [version]'3.8.3'
	[string]$deployAppScriptDate = '30/09/2020'
	[hashtable]$deployAppScriptParameters = $psBoundParameters

	## Variables: Environment
	If (Test-Path -LiteralPath 'variable:HostInvocation') { $InvocationInfo = $HostInvocation } Else { $InvocationInfo = $MyInvocation }
	[string]$scriptDirectory = Split-Path -Path $InvocationInfo.MyCommand.Definition -Parent

	## Dot source the required App Deploy Toolkit Functions
	Try {
		[string]$moduleAppDeployToolkitMain = "$scriptDirectory\AppDeployToolkit\AppDeployToolkitMain.ps1"
		If (-not (Test-Path -LiteralPath $moduleAppDeployToolkitMain -PathType 'Leaf')) { Throw "Module does not exist at the specified location [$moduleAppDeployToolkitMain]." }
		If ($DisableLogging) { . $moduleAppDeployToolkitMain -DisableLogging } Else { . $moduleAppDeployToolkitMain }
	}
	Catch {
		If ($mainExitCode -eq 0){ [int32]$mainExitCode = 60008 }
		Write-Error -Message "Module [$moduleAppDeployToolkitMain] failed to load: `n$($_.Exception.Message)`n `n$($_.InvocationInfo.PositionMessage)" -ErrorAction 'Continue'
		## Exit the script, returning the exit code to SCCM
		If (Test-Path -LiteralPath 'variable:HostInvocation') { $script:ExitCode = $mainExitCode; Exit } Else { Exit $mainExitCode }
	}

	#endregion
	##* Do not modify section above
	##*===============================================
	##* END VARIABLE DECLARATION
	##*===============================================

	If ($deploymentType -ine 'Uninstall' -and $deploymentType -ine 'Repair') {
		##*===============================================
		##* PRE-INSTALLATION
		##*===============================================
		[string]$installPhase = 'Pre-Installation'

		## Show Welcome Message, close Internet Explorer if required, verify there is enough disk space to complete the install, and persist the prompt
		Show-InstallationWelcome -CloseApps 'audacity' -CheckDiskSpace -PersistPrompt

		## Show Progress Message (with the default message)
		Show-InstallationProgress

		## <Perform Pre-Installation tasks here>
		If (Test-Path -path "C:\Program Files (x86)\Audacity\Audacity.exe") {
		Execute-Process -Path "C:\Program Files (x86)\Audacity\unins000.exe" -Parameters "/silent" -WindowStyle "Hidden" -PassThru }
		If (Test-Path -path "C:\Program Files\Audacity\Audacity.exe") {
		Execute-Process -Path "C:\Program Files\Audacity\unins000.exe" -Parameters "/silent" -WindowStyle "Hidden" -PassThru }



		##*===============================================
		##* INSTALLATION
		##*===============================================
		[string]$installPhase = 'Installation'

		## Handle Zero-Config MSI Installations
		If ($useDefaultMsi) {
			[hashtable]$ExecuteDefaultMSISplat =  @{ Action = 'Install'; Path = $defaultMsiFile }; If ($defaultMstFile) { $ExecuteDefaultMSISplat.Add('Transform', $defaultMstFile) }
			Execute-MSI @ExecuteDefaultMSISplat; If ($defaultMspFiles) { $defaultMspFiles | ForEach-Object { Execute-MSI -Action 'Patch' -Path $_ } }
		}

		## <Perform Installation tasks here>
		$exitCode = Execute-Process -Path "$dirFiles\audacity-win-3.1.3-64bit.exe" -Parameters "/verysilent /suppressmsgboxes /closeapplications" -WindowStyle "Hidden" -PassThru
		If (($exitCode.ExitCode -ne "0") -and ($mainExitCode -ne "3010")) { $mainExitCode = $exitCode.ExitCode }


		##*===============================================
		##* POST-INSTALLATION
		##*===============================================
		[string]$installPhase = 'Post-Installation'

		## <Perform Post-Installation tasks here>
		Remove-File -Path "$envCommonDesktop\Audacity.lnk"

		## Display a message at the end of the install
		If (-not $useDefaultMsi) {}
	}
	ElseIf ($deploymentType -ieq 'Uninstall')
	{
		##*===============================================
		##* PRE-UNINSTALLATION
		##*===============================================
		[string]$installPhase = 'Pre-Uninstallation'

		## Show Welcome Message, close Audacity with a 60 second countdown before automatically closing
		Show-InstallationWelcome -CloseApps 'audacity' -CloseAppsCountdown 60

		## Show Progress Message (with the default message)
		Show-InstallationProgress

		## <Perform Pre-Uninstallation tasks here>



		##*===============================================
		##* UNINSTALLATION
		##*===============================================
		[string]$installPhase = 'Uninstallation'

		## Handle Zero-Config MSI Uninstallations
		If ($useDefaultMsi) {
			[hashtable]$ExecuteDefaultMSISplat =  @{ Action = 'Uninstall'; Path = $defaultMsiFile }; If ($defaultMstFile) { $ExecuteDefaultMSISplat.Add('Transform', $defaultMstFile) }
			Execute-MSI @ExecuteDefaultMSISplat
		}

		# <Perform Uninstallation tasks here>

		If (Test-Path -path "C:\Program Files (x86)\Audacity") {
			$exitCode = Execute-Process -Path "C:\Program Files (x86)\Audacity\unins000.exe" -Parameters "/silent" -WindowStyle "Hidden" -PassThru }
		If (Test-Path -path "C:\Program Files\Audacity") {
			$exitCode = Execute-Process -Path "C:\Program Files\Audacity\unins000.exe" -Parameters "/silent" -WindowStyle "Hidden" -PassThru }
		If (($exitCode.ExitCode -ne "0") -and ($mainExitCode -ne "3010")) { $mainExitCode = $exitCode.ExitCode }

		##*===============================================
		##* POST-UNINSTALLATION
		##*===============================================
		[string]$installPhase = 'Post-Uninstallation'

		## <Perform Post-Uninstallation tasks here>

		Remove-File -Path "$envProgramFiles\Audacity"
		Remove-File -Path "$envProgramFilesx86\Audacity"


	}
	ElseIf ($deploymentType -ieq 'Repair')
	{
		##*===============================================
		##* PRE-REPAIR
		##*===============================================
		[string]$installPhase = 'Pre-Repair'

		## Show Progress Message (with the default message)
		Show-InstallationProgress

		## <Perform Pre-Repair tasks here>

		##*===============================================
		##* REPAIR
		##*===============================================
		[string]$installPhase = 'Repair'

		## Handle Zero-Config MSI Repairs
		If ($useDefaultMsi) {
			[hashtable]$ExecuteDefaultMSISplat =  @{ Action = 'Repair'; Path = $defaultMsiFile; }; If ($defaultMstFile) { $ExecuteDefaultMSISplat.Add('Transform', $defaultMstFile) }
			Execute-MSI @ExecuteDefaultMSISplat
		}
		# <Perform Repair tasks here>

		##*===============================================
		##* POST-REPAIR
		##*===============================================
		[string]$installPhase = 'Post-Repair'

		## <Perform Post-Repair tasks here>


	}
	##*===============================================
	##* END SCRIPT BODY
	##*===============================================

	## Call the Exit-Script function to perform final cleanup operations
	Exit-Script -ExitCode $mainExitCode
}
Catch {
	[int32]$mainExitCode = 60001
	[string]$mainErrorMessage = "$(Resolve-Error)"
	Write-Log -Message $mainErrorMessage -Severity 3 -Source $deployAppScriptFriendlyName
	Show-DialogBox -Text $mainErrorMessage -Icon 'Stop'
	Exit-Script -ExitCode $mainExitCode
}
# SIG # Begin signature block
# MIImZwYJKoZIhvcNAQcCoIImWDCCJlQCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
<<<<<<< HEAD
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAtHNvkCiSzV/YG
# lYvJaW57S6xc4sw9NwtKGoFGk7sT5aCCH9IwggVvMIIEV6ADAgECAhBI/JO0YFWU
=======
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDjZeaWRYBDBqkx
# PDkvjFP0CKA12NQYucd0n55vwhXjbaCCH9IwggVvMIIEV6ADAgECAhBI/JO0YFWU
>>>>>>> a993a5eed41b4544e8cfee2ed8d325b4d2fb0e5d
# jTanyYqJ1pQWMA0GCSqGSIb3DQEBDAUAMHsxCzAJBgNVBAYTAkdCMRswGQYDVQQI
# DBJHcmVhdGVyIE1hbmNoZXN0ZXIxEDAOBgNVBAcMB1NhbGZvcmQxGjAYBgNVBAoM
# EUNvbW9kbyBDQSBMaW1pdGVkMSEwHwYDVQQDDBhBQUEgQ2VydGlmaWNhdGUgU2Vy
# dmljZXMwHhcNMjEwNTI1MDAwMDAwWhcNMjgxMjMxMjM1OTU5WjBWMQswCQYDVQQG
# EwJHQjEYMBYGA1UEChMPU2VjdGlnbyBMaW1pdGVkMS0wKwYDVQQDEyRTZWN0aWdv
# IFB1YmxpYyBDb2RlIFNpZ25pbmcgUm9vdCBSNDYwggIiMA0GCSqGSIb3DQEBAQUA
# A4ICDwAwggIKAoICAQCN55QSIgQkdC7/FiMCkoq2rjaFrEfUI5ErPtx94jGgUW+s
# hJHjUoq14pbe0IdjJImK/+8Skzt9u7aKvb0Ffyeba2XTpQxpsbxJOZrxbW6q5KCD
# J9qaDStQ6Utbs7hkNqR+Sj2pcaths3OzPAsM79szV+W+NDfjlxtd/R8SPYIDdub7
# P2bSlDFp+m2zNKzBenjcklDyZMeqLQSrw2rq4C+np9xu1+j/2iGrQL+57g2extme
# me/G3h+pDHazJyCh1rr9gOcB0u/rgimVcI3/uxXP/tEPNqIuTzKQdEZrRzUTdwUz
# T2MuuC3hv2WnBGsY2HH6zAjybYmZELGt2z4s5KoYsMYHAXVn3m3pY2MeNn9pib6q
# RT5uWl+PoVvLnTCGMOgDs0DGDQ84zWeoU4j6uDBl+m/H5x2xg3RpPqzEaDux5mcz
# mrYI4IAFSEDu9oJkRqj1c7AGlfJsZZ+/VVscnFcax3hGfHCqlBuCF6yH6bbJDoEc
# QNYWFyn8XJwYK+pF9e+91WdPKF4F7pBMeufG9ND8+s0+MkYTIDaKBOq3qgdGnA2T
# OglmmVhcKaO5DKYwODzQRjY1fJy67sPV+Qp2+n4FG0DKkjXp1XrRtX8ArqmQqsV/
# AZwQsRb8zG4Y3G9i/qZQp7h7uJ0VP/4gDHXIIloTlRmQAOka1cKG8eOO7F/05QID
# AQABo4IBEjCCAQ4wHwYDVR0jBBgwFoAUoBEKIz6W8Qfs4q8p74Klf9AwpLQwHQYD
# VR0OBBYEFDLrkpr/NZZILyhAQnAgNpFcF4XmMA4GA1UdDwEB/wQEAwIBhjAPBgNV
# HRMBAf8EBTADAQH/MBMGA1UdJQQMMAoGCCsGAQUFBwMDMBsGA1UdIAQUMBIwBgYE
# VR0gADAIBgZngQwBBAEwQwYDVR0fBDwwOjA4oDagNIYyaHR0cDovL2NybC5jb21v
# ZG9jYS5jb20vQUFBQ2VydGlmaWNhdGVTZXJ2aWNlcy5jcmwwNAYIKwYBBQUHAQEE
# KDAmMCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5jb21vZG9jYS5jb20wDQYJKoZI
# hvcNAQEMBQADggEBABK/oe+LdJqYRLhpRrWrJAoMpIpnuDqBv0WKfVIHqI0fTiGF
# OaNrXi0ghr8QuK55O1PNtPvYRL4G2VxjZ9RAFodEhnIq1jIV9RKDwvnhXRFAZ/ZC
# J3LFI+ICOBpMIOLbAffNRk8monxmwFE2tokCVMf8WPtsAO7+mKYulaEMUykfb9gZ
# pk+e96wJ6l2CxouvgKe9gUhShDHaMuwV5KZMPWw5c9QLhTkg4IUaaOGnSDip0TYl
# d8GNGRbFiExmfS9jzpjoad+sPKhdnckcW67Y8y90z7h+9teDnRGWYpquRRPaf9xH
# +9/DUp/mBlXpnYzyOmJRvOwkDynUWICE5EV7WtgwggYaMIIEAqADAgECAhBiHW0M
# UgGeO5B5FSCJIRwKMA0GCSqGSIb3DQEBDAUAMFYxCzAJBgNVBAYTAkdCMRgwFgYD
# VQQKEw9TZWN0aWdvIExpbWl0ZWQxLTArBgNVBAMTJFNlY3RpZ28gUHVibGljIENv
# ZGUgU2lnbmluZyBSb290IFI0NjAeFw0yMTAzMjIwMDAwMDBaFw0zNjAzMjEyMzU5
# NTlaMFQxCzAJBgNVBAYTAkdCMRgwFgYDVQQKEw9TZWN0aWdvIExpbWl0ZWQxKzAp
# BgNVBAMTIlNlY3RpZ28gUHVibGljIENvZGUgU2lnbmluZyBDQSBSMzYwggGiMA0G
# CSqGSIb3DQEBAQUAA4IBjwAwggGKAoIBgQCbK51T+jU/jmAGQ2rAz/V/9shTUxjI
# ztNsfvxYB5UXeWUzCxEeAEZGbEN4QMgCsJLZUKhWThj/yPqy0iSZhXkZ6Pg2A2NV
# DgFigOMYzB2OKhdqfWGVoYW3haT29PSTahYkwmMv0b/83nbeECbiMXhSOtbam+/3
# 6F09fy1tsB8je/RV0mIk8XL/tfCK6cPuYHE215wzrK0h1SWHTxPbPuYkRdkP05Zw
# mRmTnAO5/arnY83jeNzhP06ShdnRqtZlV59+8yv+KIhE5ILMqgOZYAENHNX9SJDm
# +qxp4VqpB3MV/h53yl41aHU5pledi9lCBbH9JeIkNFICiVHNkRmq4TpxtwfvjsUe
# dyz8rNyfQJy/aOs5b4s+ac7IH60B+Ja7TVM+EKv1WuTGwcLmoU3FpOFMbmPj8pz4
# 4MPZ1f9+YEQIQty/NQd/2yGgW+ufflcZ/ZE9o1M7a5Jnqf2i2/uMSWymR8r2oQBM
# dlyh2n5HirY4jKnFH/9gRvd+QOfdRrJZb1sCAwEAAaOCAWQwggFgMB8GA1UdIwQY
# MBaAFDLrkpr/NZZILyhAQnAgNpFcF4XmMB0GA1UdDgQWBBQPKssghyi47G9IritU
# pimqF6TNDDAOBgNVHQ8BAf8EBAMCAYYwEgYDVR0TAQH/BAgwBgEB/wIBADATBgNV
# HSUEDDAKBggrBgEFBQcDAzAbBgNVHSAEFDASMAYGBFUdIAAwCAYGZ4EMAQQBMEsG
# A1UdHwREMEIwQKA+oDyGOmh0dHA6Ly9jcmwuc2VjdGlnby5jb20vU2VjdGlnb1B1
# YmxpY0NvZGVTaWduaW5nUm9vdFI0Ni5jcmwwewYIKwYBBQUHAQEEbzBtMEYGCCsG
# AQUFBzAChjpodHRwOi8vY3J0LnNlY3RpZ28uY29tL1NlY3RpZ29QdWJsaWNDb2Rl
# U2lnbmluZ1Jvb3RSNDYucDdjMCMGCCsGAQUFBzABhhdodHRwOi8vb2NzcC5zZWN0
# aWdvLmNvbTANBgkqhkiG9w0BAQwFAAOCAgEABv+C4XdjNm57oRUgmxP/BP6YdURh
# w1aVcdGRP4Wh60BAscjW4HL9hcpkOTz5jUug2oeunbYAowbFC2AKK+cMcXIBD0Zd
# OaWTsyNyBBsMLHqafvIhrCymlaS98+QpoBCyKppP0OcxYEdU0hpsaqBBIZOtBajj
# cw5+w/KeFvPYfLF/ldYpmlG+vd0xqlqd099iChnyIMvY5HexjO2AmtsbpVn0OhNc
# WbWDRF/3sBp6fWXhz7DcML4iTAWS+MVXeNLj1lJziVKEoroGs9Mlizg0bUMbOalO
# hOfCipnx8CaLZeVme5yELg09Jlo8BMe80jO37PU8ejfkP9/uPak7VLwELKxAMcJs
# zkyeiaerlphwoKx1uHRzNyE6bxuSKcutisqmKL5OTunAvtONEoteSiabkPVSZ2z7
# 6mKnzAfZxCl/3dq3dUNw4rg3sTCggkHSRqTqlLMS7gjrhTqBmzu1L90Y1KWN/Y5J
# KdGvspbOrTfOXyXvmPL6E52z1NZJ6ctuMFBQZH3pwWvqURR8AgQdULUvrxjUYbHH
# j95Ejza63zdrEcxWLDX6xWls/GDnVNueKjWUH3fTv1Y8Wdho698YADR7TNx8X8z2
# Bev6SivBBOHY+uqiirZtg0y9ShQoPzmCcn63Syatatvx157YK9hlcPmVoa1oDE5/
# L9Uo2bC5a4CH2RwwggZCMIIEqqADAgECAhEApU3fcPvc8UxUgrjysXLKMTANBgkq
# hkiG9w0BAQwFADBUMQswCQYDVQQGEwJHQjEYMBYGA1UEChMPU2VjdGlnbyBMaW1p
# dGVkMSswKQYDVQQDEyJTZWN0aWdvIFB1YmxpYyBDb2RlIFNpZ25pbmcgQ0EgUjM2
# MB4XDTIxMDYwOTAwMDAwMFoXDTI0MDYwODIzNTk1OVowgZUxCzAJBgNVBAYTAlVT
# MREwDwYDVQQIDAhDb2xvcmFkbzEPMA0GA1UEBwwGRGVudmVyMTAwLgYDVQQKDCdN
# ZXRyb3BvbGl0YW4gU3RhdGUgVW5pdmVyc2l0eSBvZiBEZW52ZXIxMDAuBgNVBAMM
# J01ldHJvcG9saXRhbiBTdGF0ZSBVbml2ZXJzaXR5IG9mIERlbnZlcjCCAaIwDQYJ
# KoZIhvcNAQEBBQADggGPADCCAYoCggGBAKboC13rIRz9blQI2n+HkGKRao8qAg0x
# ItxGNohGKXOT1Ua7hDWG5+l2MBpddbQQfMSOyFT+AyisStRfFRb1TU1aSI8QxHJ1
# vkOq64AZKXIKuNxTEQv71RKyTgnjzduII4QqBhsIsrX4vN5PaFq/yKjJqKSsYQjF
# ej4Kx2fORXMFRHnqaAGW7qAwJvKcTUCzVn/1hq9dh6b3TxOd3t1x2L0Paz/4aF+J
# AhkNOF9Gc2B8heToRllTQOOSUdPz3wkW3y7u6zcJMEgxenniTP7fk348hXlrPBjy
# Z7qizCJ3wWH+QRqBqSheKZN/Olw6aYdqLAmbl9LZ3Z0/rvQMk/ADTHsY5jAXwARj
# xAlU+gnxj/6kysS6JDFP+0H7CD3fRlSBOWscPbg314zeGMx8eOLN81WWKu/79S3W
# HWAf84uxNnp2DcV/8aNsjXoaxfdQWXJp6s3V1wf5Jywv7nxcZgtS5+MJzHTv+Yc3
# hPUP7XjLpaAinHf8+rae6yP7OV6r3JZ39QIDAQABo4IByzCCAccwHwYDVR0jBBgw
# FoAUDyrLIIcouOxvSK4rVKYpqhekzQwwHQYDVR0OBBYEFMtdqsyLtKCxfncLB6Dk
# r4Az8FclMA4GA1UdDwEB/wQEAwIHgDAMBgNVHRMBAf8EAjAAMBMGA1UdJQQMMAoG
# CCsGAQUFBwMDMBEGCWCGSAGG+EIBAQQEAwIEEDBKBgNVHSAEQzBBMDUGDCsGAQQB
# sjEBAgEDAjAlMCMGCCsGAQUFBwIBFhdodHRwczovL3NlY3RpZ28uY29tL0NQUzAI
# BgZngQwBBAEwSQYDVR0fBEIwQDA+oDygOoY4aHR0cDovL2NybC5zZWN0aWdvLmNv
# bS9TZWN0aWdvUHVibGljQ29kZVNpZ25pbmdDQVIzNi5jcmwweQYIKwYBBQUHAQEE
# bTBrMEQGCCsGAQUFBzAChjhodHRwOi8vY3J0LnNlY3RpZ28uY29tL1NlY3RpZ29Q
# dWJsaWNDb2RlU2lnbmluZ0NBUjM2LmNydDAjBggrBgEFBQcwAYYXaHR0cDovL29j
# c3Auc2VjdGlnby5jb20wLQYDVR0RBCYwJIEiaXRzc3lzdGVtZW5naW5lZXJpbmdA
# bXN1ZGVudmVyLmVkdTANBgkqhkiG9w0BAQwFAAOCAYEAf8UAUe7L6IftWT8u5nDy
# eSlAgGxBzj4Dd3xgjRwkshSH7H5TvyTadkZlBBooTL390IG1X1uvLHmOC23qGI0Y
# ytYLCfNcKpq1Jjo8V0Jc9e1RwHGH/z653cJ4TsCYYdGTgtwz1J1OZHHVeMwr0p6y
# 3g7t0ERRuBClq1vnixURJyWRwg7mlSjBriRpv2AKY8xwSB3JMcDF9+YsRYCShih+
# hLcPp4YygkaHjlVhc5K/iKsoS1j7CT4qbjVl077CmVysO8KMDSTATMfOaYFngaxF
# vPfOcqNxCu8n1IMIFnMndoiWe/St3tDdwgSdQQqBxZ24KZZGDqa9j+jlvcO7AviT
# 258+icvZibXngUBM1aTePvMnW91uTJlwyl58K1W2CDnXVps8TZUMXQq8uD9Yn4VA
# 1MDNkfN5meHBUmmiI8ZMHBr2trzM94U/EpTCVK+HuSlOB0oTVC09tMqrcoK3UJXN
# dNc+j+IKHek+dzUcwi4VgmJG+dgrgSXPVPc2s0+AvTfzMIIG7DCCBNSgAwIBAgIQ
# MA9vrN1mmHR8qUY2p3gtuTANBgkqhkiG9w0BAQwFADCBiDELMAkGA1UEBhMCVVMx
# EzARBgNVBAgTCk5ldyBKZXJzZXkxFDASBgNVBAcTC0plcnNleSBDaXR5MR4wHAYD
# VQQKExVUaGUgVVNFUlRSVVNUIE5ldHdvcmsxLjAsBgNVBAMTJVVTRVJUcnVzdCBS
# U0EgQ2VydGlmaWNhdGlvbiBBdXRob3JpdHkwHhcNMTkwNTAyMDAwMDAwWhcNMzgw
# MTE4MjM1OTU5WjB9MQswCQYDVQQGEwJHQjEbMBkGA1UECBMSR3JlYXRlciBNYW5j
# aGVzdGVyMRAwDgYDVQQHEwdTYWxmb3JkMRgwFgYDVQQKEw9TZWN0aWdvIExpbWl0
# ZWQxJTAjBgNVBAMTHFNlY3RpZ28gUlNBIFRpbWUgU3RhbXBpbmcgQ0EwggIiMA0G
# CSqGSIb3DQEBAQUAA4ICDwAwggIKAoICAQDIGwGv2Sx+iJl9AZg/IJC9nIAhVJO5
# z6A+U++zWsB21hoEpc5Hg7XrxMxJNMvzRWW5+adkFiYJ+9UyUnkuyWPCE5u2hj8B
# BZJmbyGr1XEQeYf0RirNxFrJ29ddSU1yVg/cyeNTmDoqHvzOWEnTv/M5u7mkI0Ks
# 0BXDf56iXNc48RaycNOjxN+zxXKsLgp3/A2UUrf8H5VzJD0BKLwPDU+zkQGObp0n
# dVXRFzs0IXuXAZSvf4DP0REKV4TJf1bgvUacgr6Unb+0ILBgfrhN9Q0/29DqhYyK
# VnHRLZRMyIw80xSinL0m/9NTIMdgaZtYClT0Bef9Maz5yIUXx7gpGaQpL0bj3duR
# X58/Nj4OMGcrRrc1r5a+2kxgzKi7nw0U1BjEMJh0giHPYla1IXMSHv2qyghYh3ek
# FesZVf/QOVQtJu5FGjpvzdeE8NfwKMVPZIMC1Pvi3vG8Aij0bdonigbSlofe6GsO
# 8Ft96XZpkyAcSpcsdxkrk5WYnJee647BeFbGRCXfBhKaBi2fA179g6JTZ8qx+o2h
# ZMmIklnLqEbAyfKm/31X2xJ2+opBJNQb/HKlFKLUrUMcpEmLQTkUAx4p+hulIq6l
# w02C0I3aa7fb9xhAV3PwcaP7Sn1FNsH3jYL6uckNU4B9+rY5WDLvbxhQiddPnTO9
# GrWdod6VQXqngwIDAQABo4IBWjCCAVYwHwYDVR0jBBgwFoAUU3m/WqorSs9UgOHY
# m8Cd8rIDZsswHQYDVR0OBBYEFBqh+GEZIA/DQXdFKI7RNV8GEgRVMA4GA1UdDwEB
# /wQEAwIBhjASBgNVHRMBAf8ECDAGAQH/AgEAMBMGA1UdJQQMMAoGCCsGAQUFBwMI
# MBEGA1UdIAQKMAgwBgYEVR0gADBQBgNVHR8ESTBHMEWgQ6BBhj9odHRwOi8vY3Js
# LnVzZXJ0cnVzdC5jb20vVVNFUlRydXN0UlNBQ2VydGlmaWNhdGlvbkF1dGhvcml0
# eS5jcmwwdgYIKwYBBQUHAQEEajBoMD8GCCsGAQUFBzAChjNodHRwOi8vY3J0LnVz
# ZXJ0cnVzdC5jb20vVVNFUlRydXN0UlNBQWRkVHJ1c3RDQS5jcnQwJQYIKwYBBQUH
# MAGGGWh0dHA6Ly9vY3NwLnVzZXJ0cnVzdC5jb20wDQYJKoZIhvcNAQEMBQADggIB
# AG1UgaUzXRbhtVOBkXXfA3oyCy0lhBGysNsqfSoF9bw7J/RaoLlJWZApbGHLtVDb
# 4n35nwDvQMOt0+LkVvlYQc/xQuUQff+wdB+PxlwJ+TNe6qAcJlhc87QRD9XVw+K8
# 1Vh4v0h24URnbY+wQxAPjeT5OGK/EwHFhaNMxcyyUzCVpNb0llYIuM1cfwGWvnJS
# ajtCN3wWeDmTk5SbsdyybUFtZ83Jb5A9f0VywRsj1sJVhGbks8VmBvbz1kteraMr
# Qoohkv6ob1olcGKBc2NeoLvY3NdK0z2vgwY4Eh0khy3k/ALWPncEvAQ2ted3y5wu
# jSMYuaPCRx3wXdahc1cFaJqnyTdlHb7qvNhCg0MFpYumCf/RoZSmTqo9CfUFbLfS
# ZFrYKiLCS53xOV5M3kg9mzSWmglfjv33sVKRzj+J9hyhtal1H3G/W0NdZT1QgW6r
# 8NDT/LKzH7aZlib0PHmLXGTMze4nmuWgwAxyh8FuTVrTHurwROYybxzrF06Uw3hl
# IDsPQaof6aFBnf6xuKBlKjTg3qj5PObBMLvAoGMs/FwWAKjQxH/qEZ0eBsambTJd
# tDgJK0kHqv3sMNrxpy/Pt/360KOE2See+wFmd7lWEOEgbsausfm2usg1XTN2jvF8
# IAwqd661ogKGuinutFoAsYyr4/kKyVRd1LlqdJ69SK6YMIIHBzCCBO+gAwIBAgIR
# AIx3oACP9NGwxj2fOkiDjWswDQYJKoZIhvcNAQEMBQAwfTELMAkGA1UEBhMCR0Ix
# GzAZBgNVBAgTEkdyZWF0ZXIgTWFuY2hlc3RlcjEQMA4GA1UEBxMHU2FsZm9yZDEY
# MBYGA1UEChMPU2VjdGlnbyBMaW1pdGVkMSUwIwYDVQQDExxTZWN0aWdvIFJTQSBU
# aW1lIFN0YW1waW5nIENBMB4XDTIwMTAyMzAwMDAwMFoXDTMyMDEyMjIzNTk1OVow
# gYQxCzAJBgNVBAYTAkdCMRswGQYDVQQIExJHcmVhdGVyIE1hbmNoZXN0ZXIxEDAO
# BgNVBAcTB1NhbGZvcmQxGDAWBgNVBAoTD1NlY3RpZ28gTGltaXRlZDEsMCoGA1UE
# AwwjU2VjdGlnbyBSU0EgVGltZSBTdGFtcGluZyBTaWduZXIgIzIwggIiMA0GCSqG
# SIb3DQEBAQUAA4ICDwAwggIKAoICAQCRh0ssi8HxHqCe0wfGAcpSsL55eV0JZgYt
# LzV9u8D7J9pCalkbJUzq70DWmn4yyGqBfbRcPlYQgTU6IjaM+/ggKYesdNAbYrw/
# ZIcCX+/FgO8GHNxeTpOHuJreTAdOhcxwxQ177MPZ45fpyxnbVkVs7ksgbMk+bP3w
# m/Eo+JGZqvxawZqCIDq37+fWuCVJwjkbh4E5y8O3Os2fUAQfGpmkgAJNHQWoVdNt
# UoCD5m5IpV/BiVhgiu/xrM2HYxiOdMuEh0FpY4G89h+qfNfBQc6tq3aLIIDULZUH
# jcf1CxcemuXWmWlRx06mnSlv53mTDTJjU67MximKIMFgxvICLMT5yCLf+SeCoYNR
# wrzJghohhLKXvNSvRByWgiKVKoVUrvH9Pkl0dPyOrj+lcvTDWgGqUKWLdpUbZuvv
# 2t+ULtka60wnfUwF9/gjXcRXyCYFevyBI19UCTgqYtWqyt/tz1OrH/ZEnNWZWcVW
# ZFv3jlIPZvyYP0QGE2Ru6eEVYFClsezPuOjJC77FhPfdCp3avClsPVbtv3hntlvI
# XhQcua+ELXei9zmVN29OfxzGPATWMcV+7z3oUX5xrSR0Gyzc+Xyq78J2SWhi1Yv1
# A9++fY4PNnVGW5N2xIPugr4srjcS8bxWw+StQ8O3ZpZelDL6oPariVD6zqDzCIEa
# 0USnzPe4MQIDAQABo4IBeDCCAXQwHwYDVR0jBBgwFoAUGqH4YRkgD8NBd0UojtE1
# XwYSBFUwHQYDVR0OBBYEFGl1N3u7nTVCTr9X05rbnwHRrt7QMA4GA1UdDwEB/wQE
# AwIGwDAMBgNVHRMBAf8EAjAAMBYGA1UdJQEB/wQMMAoGCCsGAQUFBwMIMEAGA1Ud
# IAQ5MDcwNQYMKwYBBAGyMQECAQMIMCUwIwYIKwYBBQUHAgEWF2h0dHBzOi8vc2Vj
# dGlnby5jb20vQ1BTMEQGA1UdHwQ9MDswOaA3oDWGM2h0dHA6Ly9jcmwuc2VjdGln
# by5jb20vU2VjdGlnb1JTQVRpbWVTdGFtcGluZ0NBLmNybDB0BggrBgEFBQcBAQRo
# MGYwPwYIKwYBBQUHMAKGM2h0dHA6Ly9jcnQuc2VjdGlnby5jb20vU2VjdGlnb1JT
# QVRpbWVTdGFtcGluZ0NBLmNydDAjBggrBgEFBQcwAYYXaHR0cDovL29jc3Auc2Vj
# dGlnby5jb20wDQYJKoZIhvcNAQEMBQADggIBAEoDeJBCM+x7GoMJNjOYVbudQAYw
# a0Vq8ZQOGVD/WyVeO+E5xFu66ZWQNze93/tk7OWCt5XMV1VwS070qIfdIoWmV7u4
# ISfUoCoxlIoHIZ6Kvaca9QIVy0RQmYzsProDd6aCApDCLpOpviE0dWO54C0PzwE3
# y42i+rhamq6hep4TkxlVjwmQLt/qiBcW62nW4SW9RQiXgNdUIChPynuzs6XSALBg
# NGXE48XDpeS6hap6adt1pD55aJo2i0OuNtRhcjwOhWINoF5w22QvAcfBoccklKOy
# PG6yXqLQ+qjRuCUcFubA1X9oGsRlKTUqLYi86q501oLnwIi44U948FzKwEBcwp/V
# Mhws2jysNvcGUpqjQDAXsCkWmcmqt4hJ9+gLJTO1P22vn18KVt8SscPuzpF36CAT
# 6Vwkx+pEC0rmE4QcTesNtbiGoDCni6GftCzMwBYjyZHlQgNLgM7kTeYqAT7AXoWg
# JKEXQNXb2+eYEKTx6hkbgFT6R4nomIGpdcAO39BolHmhoJ6OtrdCZsvZ2WsvTdje
# PjIeIOTsnE1CjZ3HM5mCN0TUJikmQI54L7nu+i/x8Y/+ULh43RSW3hwOcLAqhWqx
# bGjpKuQQK24h/dN8nTfkKgbWw/HXaONPB3mBCBP+smRe6bE85tB4I7IJLOImYr87
# qZdRzMdEMoGyr8/fMYIF6zCCBecCAQEwaTBUMQswCQYDVQQGEwJHQjEYMBYGA1UE
# ChMPU2VjdGlnbyBMaW1pdGVkMSswKQYDVQQDEyJTZWN0aWdvIFB1YmxpYyBDb2Rl
# IFNpZ25pbmcgQ0EgUjM2AhEApU3fcPvc8UxUgrjysXLKMTANBglghkgBZQMEAgEF
# AKCBhDAYBgorBgEEAYI3AgEMMQowCKACgAChAoAAMBkGCSqGSIb3DQEJAzEMBgor
# BgEEAYI3AgEEMBwGCisGAQQBgjcCAQsxDjAMBgorBgEEAYI3AgEVMC8GCSqGSIb3
<<<<<<< HEAD
# DQEJBDEiBCCvUv00hZL+ZbMZYDDDdh5MOpxZE3cJnsZyPd6C7/EVsTANBgkqhkiG
# 9w0BAQEFAASCAYASDPRRZlytHBUWbwg/kVDkFO99clMwGB3UarUs+xZVYAu/CCr1
# A47jPHImKo/HDQkAzjWVqYdOUWBjvv4PnuWmSFBBE2j2KQi6Eal74KJK7mTMs3Je
# DdVHHmWHS9rkpQvHlNWL++vIVBZFP0HuX5Lvst8+Cu+nlB7omgWJFhK8QKPN02H6
# NTryUsapWYF9BZApnEPGQvdpsgQe4MrDVD7AdNYYDymGVd9cRwqCbZi8BbeMa7ex
# VFkR93jGVGGLXUvUhtow41MRj5Vpe7pj+aCswpH54f2sv29f0bKm84xQYOy9MhQI
# PxYeAW0M+DzsCLvw9O75jxRigaTfcy7LoV+fpdhBk3re4wmaU/TVuBHMGeXt6q1k
# p+OZyM5iSfXV8s2y6Xl7oPY6J0sXRO/L95Bk+7zrXbEP4mxlb3ww1gnHEMuuFQIB
# SgD0GC7Xgd7QTbn6W5zAr2xC0DOFj6Uic2JH95ngiKIZ7oZRY6N0PNDXDaM53fxt
# TSqquLf7p0RB+ymhggNMMIIDSAYJKoZIhvcNAQkGMYIDOTCCAzUCAQEwgZIwfTEL
=======
# DQEJBDEiBCDPe/8F1+7PZSiFpVmtw+qlemPM0ztGtzaMmZoZ+jWOjjANBgkqhkiG
# 9w0BAQEFAASCAYCQ8a85QyDMaSIhI64JFeh/gtyq0pMymCByShfIbunV3zgxE/Rr
# C3g5KPZIlChkx/80NraK92leS2RJfWGcldIlCOA/NBKvJxT8Pni682eq4l1fGSzd
# kZgifPiFgtCEGL5vsQA7iwgFcTLDB0XY2BYHKIyPQ9Fxv0ikhTX/wrxmSmFgiDQu
# P1VCwMu1gS+vCjU38EYzsRDiOP8UMozUmMAIx1MA97CY3Bj1f4TxLphgBRZypT/e
# zD6/X4/9vkyFG5F2oXq2HbYwp2FR+r45PvZzThS/L0PGYujjgFhjZsZKTxXy4JnY
# qxfQVu+rdiVHdbSqkgSivtETvemYa3zy9CPf+EOq28VIDk1uSEf+k+oS3615Sf35
# 8ViPuJNAPxcAKI71B37611lExapMDX92OnSnsqxSGhpkF1StqAEWf15vN/ZcLrCE
# bWqzZePJizNRh2/bOjZnHgpiJQHGSa02i2wnfwtQfyzU8RigceoXAlDrX+Yh2YZA
# Vy0m8w7YCX/aFPyhggNMMIIDSAYJKoZIhvcNAQkGMYIDOTCCAzUCAQEwgZIwfTEL
>>>>>>> a993a5eed41b4544e8cfee2ed8d325b4d2fb0e5d
# MAkGA1UEBhMCR0IxGzAZBgNVBAgTEkdyZWF0ZXIgTWFuY2hlc3RlcjEQMA4GA1UE
# BxMHU2FsZm9yZDEYMBYGA1UEChMPU2VjdGlnbyBMaW1pdGVkMSUwIwYDVQQDExxT
# ZWN0aWdvIFJTQSBUaW1lIFN0YW1waW5nIENBAhEAjHegAI/00bDGPZ86SIONazAN
# BglghkgBZQMEAgIFAKB5MBgGCSqGSIb3DQEJAzELBgkqhkiG9w0BBwEwHAYJKoZI
<<<<<<< HEAD
# hvcNAQkFMQ8XDTIyMDIyMzE3MTUzMlowPwYJKoZIhvcNAQkEMTIEMAjIpbeCaP8G
# KoJ/NUdBLi/2qSuDuarrWWQIkNbK+q7a+BB7xtDJI5BvWv/AmiWi3zANBgkqhkiG
# 9w0BAQEFAASCAgB87XBLbXkChTlaJv9uIlVgJhLcOMNjtY5AXYnxNzUcIywIEFtH
# AsRhWgWjzmQZW/FrFf9pq9Di5+TaJnsjRrk9ct17UtKFcJ3Dy1/I87ef9V7El51K
# vNerVimvBzZUK4ZOZZKdp0g4gqDng6D/mAj06jBOotDSiqDHqZ40oOKHrEiZUg3b
# aqzS55We5c6Y9xymWOvgDUAt12lWnWzvqSEGZsVgnCpebUpkPiRhtN3EgaQ9T3gz
# IedHZPCQRDVFMid3kQyTy1ypqYgEVWOcqrsDKAIjLOcfu8TH2ZfZSXHfUWTMgLJf
# gnguRahQHJHGFoXd1b4ffTgHMWmSolWvg9g1U73yX1O5JcomrKjoIAdy52RleTXS
# MeXR/2r9kkVEMXdSxyXY9lG4LAI9MLe4nzJuSjy7Nr0YeHCiIhjQ9maqfpLHy8lY
# hqCfshxd5TE1yh+9CqDGYKVu+lbuvK0Lp99CRFh70xYEljjG1eWQfaJD6vIJK5qi
# npu/PiFkVtaAkMAMid0x3MwNV4fbT/W8y5sfHPH1IdfDL1wXyvlkwp4O1UEBOH9X
# txcwfnt8dE+J9g9A8E21BW34HnJFeOq+vR7s0A4MVnNOZahKUsouy0r+c5HVavuB
# bnvSSOpUaO7ljrlNGYQNGuIeUiJMeZVJ8N7tNwBk4KJ4VHsHPx0mktE9Rw==
=======
# hvcNAQkFMQ8XDTIyMDIwOTIyMDYwMlowPwYJKoZIhvcNAQkEMTIEMO2XVzGcRIfc
# P3g0jOV3dlxBN2blk9UV8mJcHek9ovBMTInrF1ggIaZGKIGTif5P0DANBgkqhkiG
# 9w0BAQEFAASCAgCQ9w19TEPR6CT4cJ61grGedxQGKz6dO+ye2IZTqBztrEKeEwa0
# CuyfyoAUPPleVI+WwzsSLLDzCxAQkOkFPzGtDnWNcpXxqB4p4KAOX9foH0b7zg9k
# PFU96lqqulXtCxu1WkPGCrhXH7jUtIyLysxGUxuvFh7eRB/uGZSgu3unij9NQl8u
# 3QO2u28kvedIC9CwFAI/50YALg+9VHtHz4co04Ng6YvvZr2EKUZJKBQuxdeaF8lw
# TJBuFKhAjGw9Rvz7qQm/fwelGWXTJlcoYDIrwcW47iW1OJD5FGSD7iZo1wey/Xgk
# 1eNoKeF2t7seZ2DB8Yv2U6b/6lpiRGgGwCkALOGlbeCd/zfCU2MJHPrGHCcMQU1k
# VQjgiB++9WH49uBqPc84Y5TEQno1FxHBfeRZjBIsZ3p4YUDccEMklKw6Ckf13g/l
# obcDUa+26Jnz7JckHdxepx2qshidMqFLxaSPo60aY/bsMmWtdboupfwQpvPw9a4M
# KG3bpDNAd5PdlGx4erzSFhltqrhEaleCqOpfKhoICeuvDeQ6PWbY+PqrC6lUFIe1
# GYYPdHTalk/6imMvIY1zXFJyxvMNasK27x+jek1k78cx29H45/znzIU9E4swPked
# ITwY9L8SajDAUd1lVtdpjUxmc6O10U9fRLhSEPiWhq0L9/m/mtcp7FGzjA==
>>>>>>> a993a5eed41b4544e8cfee2ed8d325b4d2fb0e5d
# SIG # End signature block
