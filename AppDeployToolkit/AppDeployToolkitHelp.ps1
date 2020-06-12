<#
.SYNOPSIS
	Displays a graphical console to browse the help for the App Deployment Toolkit functions
    # LICENSE #
    PowerShell App Deployment Toolkit - Provides a set of functions to perform common application deployment tasks on Windows.
    Copyright (C) 2017 - Sean Lillis, Dan Cunningham, Muhammad Mashwani, Aman Motazedian.
    This program is free software: you can redistribute it and/or modify it under the terms of the GNU Lesser General Public License as published by the Free Software Foundation, either version 3 of the License, or any later version. This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
    You should have received a copy of the GNU Lesser General Public License along with this program. If not, see <http://www.gnu.org/licenses/>.
.DESCRIPTION
	Displays a graphical console to browse the help for the App Deployment Toolkit functions
.EXAMPLE
	AppDeployToolkitHelp.ps1
.NOTES
.LINK
	http://psappdeploytoolkit.com
#>

##*===============================================
##* VARIABLE DECLARATION
##*===============================================

## Variables: Script
[string]$appDeployToolkitHelpName = 'PSAppDeployToolkitHelp'
[string]$appDeployHelpScriptFriendlyName = 'App Deploy Toolkit Help'
[version]$appDeployHelpScriptVersion = [version]'3.8.1'
[string]$appDeployHelpScriptDate = '28/03/2020'

## Variables: Environment
[string]$scriptDirectory = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
#  Dot source the App Deploy Toolkit Functions
. "$scriptDirectory\AppDeployToolkitMain.ps1" -DisableLogging
. "$scriptDirectory\AppDeployToolkitExtensions.ps1"
##*===============================================
##* END VARIABLE DECLARATION
##*===============================================

##*===============================================
##* FUNCTION LISTINGS
##*===============================================

Function Show-HelpConsole {
	## Import the Assemblies
	Add-Type -AssemblyName 'System.Windows.Forms' -ErrorAction 'Stop'
	Add-Type -AssemblyName System.Drawing -ErrorAction 'Stop'

	## Form Objects
	$HelpForm = New-Object -TypeName 'System.Windows.Forms.Form'
	$HelpListBox = New-Object -TypeName 'System.Windows.Forms.ListBox'
	$HelpTextBox = New-Object -TypeName 'System.Windows.Forms.RichTextBox'
	$InitialFormWindowState = New-Object -TypeName 'System.Windows.Forms.FormWindowState'

	## Form Code
	$System_Drawing_Size = New-Object -TypeName 'System.Drawing.Size'
	$System_Drawing_Size.Height = 665
	$System_Drawing_Size.Width = 957
	$HelpForm.ClientSize = $System_Drawing_Size
	$HelpForm.DataBindings.DefaultDataSourceUpdateMode = 0
	$HelpForm.Name = 'HelpForm'
	$HelpForm.Text = 'PowerShell App Deployment Toolkit Help Console'
	$HelpForm.WindowState = 'Normal'
	$HelpForm.ShowInTaskbar = $true
	$HelpForm.FormBorderStyle = 'Fixed3D'
	$HelpForm.MaximizeBox = $false
	$HelpForm.Icon = New-Object -TypeName 'System.Drawing.Icon' -ArgumentList $AppDeployLogoIcon
	$HelpListBox.Anchor = 7
	$HelpListBox.BorderStyle = 1
	$HelpListBox.DataBindings.DefaultDataSourceUpdateMode = 0
	$HelpListBox.Font = New-Object -TypeName 'System.Drawing.Font' -ArgumentList ('Microsoft Sans Serif', 9.75, 1, 3, 1)
	$HelpListBox.FormattingEnabled = $true
	$HelpListBox.ItemHeight = 16
	$System_Drawing_Point = New-Object -TypeName 'System.Drawing.Point'
	$System_Drawing_Point.X = 0
	$System_Drawing_Point.Y = 0
	$HelpListBox.Location = $System_Drawing_Point
	$HelpListBox.Name = 'HelpListBox'
	$System_Drawing_Size = New-Object -TypeName 'System.Drawing.Size'
	$System_Drawing_Size.Height = 658
	$System_Drawing_Size.Width = 271
	$HelpListBox.Size = $System_Drawing_Size
	$HelpListBox.Sorted = $true
	$HelpListBox.TabIndex = 2
	$HelpListBox.add_SelectedIndexChanged({ $HelpTextBox.Text = Get-Help -Name $HelpListBox.SelectedItem -Full | Out-String })
	$helpFunctions = Get-Command -CommandType 'Function' | Where-Object { ($_.HelpUri -match 'psappdeploytoolkit') -and ($_.Definition -notmatch 'internal script function') } | Select-Object -ExpandProperty Name
	$null = $HelpListBox.Items.AddRange($helpFunctions)
	$HelpForm.Controls.Add($HelpListBox)
	$HelpTextBox.Anchor = 11
	$HelpTextBox.BorderStyle = 1
	$HelpTextBox.DataBindings.DefaultDataSourceUpdateMode = 0
	$HelpTextBox.Font = New-Object -TypeName 'System.Drawing.Font' -ArgumentList ('Microsoft Sans Serif', 8.5, 0, 3, 1)
	$HelpTextBox.ForeColor = [System.Drawing.Color]::FromArgb(255, 0, 0, 0)
	$System_Drawing_Point = New-Object -TypeName System.Drawing.Point
	$System_Drawing_Point.X = 277
	$System_Drawing_Point.Y = 0
	$HelpTextBox.Location = $System_Drawing_Point
	$HelpTextBox.Name = 'HelpTextBox'
	$HelpTextBox.ReadOnly = $True
	$System_Drawing_Size = New-Object -TypeName 'System.Drawing.Size'
	$System_Drawing_Size.Height = 658
	$System_Drawing_Size.Width = 680
	$HelpTextBox.Size = $System_Drawing_Size
	$HelpTextBox.TabIndex = 1
	$HelpTextBox.Text = ''
	$HelpForm.Controls.Add($HelpTextBox)

	## Save the initial state of the form
	$InitialFormWindowState = $HelpForm.WindowState
	## Init the OnLoad event to correct the initial state of the form
	$HelpForm.add_Load($OnLoadForm_StateCorrection)
	## Show the Form
	$null = $HelpForm.ShowDialog()
}

##*===============================================
##* END FUNCTION LISTINGS
##*===============================================

##*===============================================
##* SCRIPT BODY
##*===============================================

Write-Log -Message "Load [$appDeployHelpScriptFriendlyName] console..." -Source $appDeployToolkitHelpName

## Show the help console
Show-HelpConsole

Write-Log -Message "[$appDeployHelpScriptFriendlyName] console closed." -Source $appDeployToolkitHelpName

##*===============================================
##* END SCRIPT BODY
##*===============================================
# SIG # Begin signature block
# MIIf1wYJKoZIhvcNAQcCoIIfyDCCH8QCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBGxvUS9me0ARni
# jx0sgjjtSUJK4whHiTdhuiXjFjcgOqCCGZswggWuMIIElqADAgECAhAHA3HRD3la
# QHGZK5QHYpviMA0GCSqGSIb3DQEBCwUAMHwxCzAJBgNVBAYTAlVTMQswCQYDVQQI
# EwJNSTESMBAGA1UEBxMJQW5uIEFyYm9yMRIwEAYDVQQKEwlJbnRlcm5ldDIxETAP
# BgNVBAsTCEluQ29tbW9uMSUwIwYDVQQDExxJbkNvbW1vbiBSU0EgQ29kZSBTaWdu
# aW5nIENBMB4XDTE4MDYyMTAwMDAwMFoXDTIxMDYyMDIzNTk1OVowgbkxCzAJBgNV
# BAYTAlVTMQ4wDAYDVQQRDAU4MDIwNDELMAkGA1UECAwCQ08xDzANBgNVBAcMBkRl
# bnZlcjEYMBYGA1UECQwPMTIwMSA1dGggU3RyZWV0MTAwLgYDVQQKDCdNZXRyb3Bv
# bGl0YW4gU3RhdGUgVW5pdmVyc2l0eSBvZiBEZW52ZXIxMDAuBgNVBAMMJ01ldHJv
# cG9saXRhbiBTdGF0ZSBVbml2ZXJzaXR5IG9mIERlbnZlcjCCASIwDQYJKoZIhvcN
# AQEBBQADggEPADCCAQoCggEBAMtXiSjEDjYNBIYXsPnFGHwZqvS5lgRNSaQjsyxg
# LsGI6yLLDCpaYy3CBwN1on4QnYzEQpsHV+TJ/3K61ZvqAxhR6Anw8TjVjaB3kPdt
# KJjEUlgiXNK0nDRyMVasZyeXALR5STSf1SxoMt8HIDd0KTB8yhME6ezFdFzwB5He
# 2/jyOswfYsN+n4k2Q9UcaVtWgCzWua39anwNva7M4GugPO5ZkF6XkrGzRHpXctV/
# Fk6LmqPY6sRm45nScnC1KQ3NN/t6ZBHzmAtgbZa41o5+AvNdkv9TVF6S3ODGpf3q
# KW8kjFt82LLYdZi0V07ln+S/BtAlGUPOvqem4EkbMtZ5M3MCAwEAAaOCAewwggHo
# MB8GA1UdIwQYMBaAFK41Ixf//wY9nFDgjCRlMx5wEIiiMB0GA1UdDgQWBBSl6Yhu
# vPlIpfXzOIq+Y/mkDGObDzAOBgNVHQ8BAf8EBAMCB4AwDAYDVR0TAQH/BAIwADAT
# BgNVHSUEDDAKBggrBgEFBQcDAzARBglghkgBhvhCAQEEBAMCBBAwZgYDVR0gBF8w
# XTBbBgwrBgEEAa4jAQQDAgEwSzBJBggrBgEFBQcCARY9aHR0cHM6Ly93d3cuaW5j
# b21tb24ub3JnL2NlcnQvcmVwb3NpdG9yeS9jcHNfY29kZV9zaWduaW5nLnBkZjBJ
# BgNVHR8EQjBAMD6gPKA6hjhodHRwOi8vY3JsLmluY29tbW9uLXJzYS5vcmcvSW5D
# b21tb25SU0FDb2RlU2lnbmluZ0NBLmNybDB+BggrBgEFBQcBAQRyMHAwRAYIKwYB
# BQUHMAKGOGh0dHA6Ly9jcnQuaW5jb21tb24tcnNhLm9yZy9JbkNvbW1vblJTQUNv
# ZGVTaWduaW5nQ0EuY3J0MCgGCCsGAQUFBzABhhxodHRwOi8vb2NzcC5pbmNvbW1v
# bi1yc2Eub3JnMC0GA1UdEQQmMCSBIml0c3N5c3RlbWVuZ2luZWVyaW5nQG1zdWRl
# bnZlci5lZHUwDQYJKoZIhvcNAQELBQADggEBAIc2PVq7BamWAujyCQPHsGCDbM3i
# 1OY5nruA/fOtbJ6mJvT9UJY4+61grcHLzV7op1y0nRhV459TrKfHKO42uRyZpdnH
# aOoC080cfg/0EwFJRy3bYB0vkVP8TeUkvUhbtcPVofI1P/wh9ZT2iYVCerOOAqiv
# xWqh8Dt+8oSbjSGhPFWyu04b8UczbK/97uXdgK0zNcXDJUjMKr6CbevfLQLfQiFP
# izaej+2fvR/jZHAvxO9W2rhd6Nw6gFs2q3P4CFK0+yAkFCLk+9wsp+RsRvRkvdWJ
# p+anNvAKOyVfCj6sz5dQPAIYIyLhy9ze3taVKm99DQQZV/wN/ATPDftLGm0wggXr
# MIID06ADAgECAhBl4eLj1d5QRYXzJiSABeLUMA0GCSqGSIb3DQEBDQUAMIGIMQsw
# CQYDVQQGEwJVUzETMBEGA1UECBMKTmV3IEplcnNleTEUMBIGA1UEBxMLSmVyc2V5
# IENpdHkxHjAcBgNVBAoTFVRoZSBVU0VSVFJVU1QgTmV0d29yazEuMCwGA1UEAxMl
# VVNFUlRydXN0IFJTQSBDZXJ0aWZpY2F0aW9uIEF1dGhvcml0eTAeFw0xNDA5MTkw
# MDAwMDBaFw0yNDA5MTgyMzU5NTlaMHwxCzAJBgNVBAYTAlVTMQswCQYDVQQIEwJN
# STESMBAGA1UEBxMJQW5uIEFyYm9yMRIwEAYDVQQKEwlJbnRlcm5ldDIxETAPBgNV
# BAsTCEluQ29tbW9uMSUwIwYDVQQDExxJbkNvbW1vbiBSU0EgQ29kZSBTaWduaW5n
# IENBMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAwKAvix56u2p1rPg+
# 3KO6OSLK86N25L99MCfmutOYMlYjXAaGlw2A6O2igTXrC/Zefqk+aHP9ndRnec6q
# 6mi3GdscdjpZh11emcehsriphHMMzKuHRhxqx+85Jb6n3dosNXA2HSIuIDvd4xwO
# PzSf5X3+VYBbBnyCV4RV8zj78gw2qblessWBRyN9EoGgwAEoPgP5OJejrQLyAmj9
# 1QGr9dVRTVDTFyJG5XMY4DrkN3dRyJ59UopPgNwmucBMyvxR+hAJEXpXKnPE4CEq
# bMJUvRw+g/hbqSzx+tt4z9mJmm2j/w2nP35MViPWCb7hpR2LB8W/499Yqu+kr4LL
# BfgKCQIDAQABo4IBWjCCAVYwHwYDVR0jBBgwFoAUU3m/WqorSs9UgOHYm8Cd8rID
# ZsswHQYDVR0OBBYEFK41Ixf//wY9nFDgjCRlMx5wEIiiMA4GA1UdDwEB/wQEAwIB
# hjASBgNVHRMBAf8ECDAGAQH/AgEAMBMGA1UdJQQMMAoGCCsGAQUFBwMDMBEGA1Ud
# IAQKMAgwBgYEVR0gADBQBgNVHR8ESTBHMEWgQ6BBhj9odHRwOi8vY3JsLnVzZXJ0
# cnVzdC5jb20vVVNFUlRydXN0UlNBQ2VydGlmaWNhdGlvbkF1dGhvcml0eS5jcmww
# dgYIKwYBBQUHAQEEajBoMD8GCCsGAQUFBzAChjNodHRwOi8vY3J0LnVzZXJ0cnVz
# dC5jb20vVVNFUlRydXN0UlNBQWRkVHJ1c3RDQS5jcnQwJQYIKwYBBQUHMAGGGWh0
# dHA6Ly9vY3NwLnVzZXJ0cnVzdC5jb20wDQYJKoZIhvcNAQENBQADggIBAEYstn9q
# TiVmvZxqpqrQnr0Prk41/PA4J8HHnQTJgjTbhuET98GWjTBEE9I17Xn3V1yTphJX
# bat5l8EmZN/JXMvDNqJtkyOh26owAmvquMCF1pKiQWyuDDllxR9MECp6xF4wnH1M
# cs4WeLOrQPy+C5kWE5gg/7K6c9G1VNwLkl/po9ORPljxKKeFhPg9+Ti3JzHIxW7L
# dyljffccWiuNFR51/BJHAZIqUDw3LsrdYWzgg4x06tgMvOEf0nITelpFTxqVvMtJ
# hnOfZbpdXZQ5o1TspxfTEVOQAsp05HUNCXyhznlVLr0JaNkM7edgk59zmdTbSGdM
# q8Ztuu6VyrivOlMSPWmay5MjvwTzuNorbwBv0DL+7cyZBp7NYZou+DoGd1lFZN0j
# U5IsQKgm3+00pnnJ67crdFwfz/8bq3MhTiKOWEb04FT3OZVp+jzvaChHWLQ8gbCO
# RgClaZq1H3aqI7JeRkWEEEp6Tv4WAVsr/i7LoXU72gOb8CAzPFqwI4Excdrxp0I4
# OXbECHlDqU4sTInqwlMwofmxeO4u94196qIqJQl+8Sykl06VktqMux84Iw3ZQLH0
# 8J8LaJ+WDUycc4OjY61I7FGxCDkbSQf3npXeRFm0IBn8GiW+TRDk6J2XJFLWEtVZ
# mhboFlBLoUlqHUCKu0QOhU/+AEOqnY98j2zRMIIG7DCCBNSgAwIBAgIQMA9vrN1m
# mHR8qUY2p3gtuTANBgkqhkiG9w0BAQwFADCBiDELMAkGA1UEBhMCVVMxEzARBgNV
# BAgTCk5ldyBKZXJzZXkxFDASBgNVBAcTC0plcnNleSBDaXR5MR4wHAYDVQQKExVU
# aGUgVVNFUlRSVVNUIE5ldHdvcmsxLjAsBgNVBAMTJVVTRVJUcnVzdCBSU0EgQ2Vy
# dGlmaWNhdGlvbiBBdXRob3JpdHkwHhcNMTkwNTAyMDAwMDAwWhcNMzgwMTE4MjM1
# OTU5WjB9MQswCQYDVQQGEwJHQjEbMBkGA1UECBMSR3JlYXRlciBNYW5jaGVzdGVy
# MRAwDgYDVQQHEwdTYWxmb3JkMRgwFgYDVQQKEw9TZWN0aWdvIExpbWl0ZWQxJTAj
# BgNVBAMTHFNlY3RpZ28gUlNBIFRpbWUgU3RhbXBpbmcgQ0EwggIiMA0GCSqGSIb3
# DQEBAQUAA4ICDwAwggIKAoICAQDIGwGv2Sx+iJl9AZg/IJC9nIAhVJO5z6A+U++z
# WsB21hoEpc5Hg7XrxMxJNMvzRWW5+adkFiYJ+9UyUnkuyWPCE5u2hj8BBZJmbyGr
# 1XEQeYf0RirNxFrJ29ddSU1yVg/cyeNTmDoqHvzOWEnTv/M5u7mkI0Ks0BXDf56i
# XNc48RaycNOjxN+zxXKsLgp3/A2UUrf8H5VzJD0BKLwPDU+zkQGObp0ndVXRFzs0
# IXuXAZSvf4DP0REKV4TJf1bgvUacgr6Unb+0ILBgfrhN9Q0/29DqhYyKVnHRLZRM
# yIw80xSinL0m/9NTIMdgaZtYClT0Bef9Maz5yIUXx7gpGaQpL0bj3duRX58/Nj4O
# MGcrRrc1r5a+2kxgzKi7nw0U1BjEMJh0giHPYla1IXMSHv2qyghYh3ekFesZVf/Q
# OVQtJu5FGjpvzdeE8NfwKMVPZIMC1Pvi3vG8Aij0bdonigbSlofe6GsO8Ft96XZp
# kyAcSpcsdxkrk5WYnJee647BeFbGRCXfBhKaBi2fA179g6JTZ8qx+o2hZMmIklnL
# qEbAyfKm/31X2xJ2+opBJNQb/HKlFKLUrUMcpEmLQTkUAx4p+hulIq6lw02C0I3a
# a7fb9xhAV3PwcaP7Sn1FNsH3jYL6uckNU4B9+rY5WDLvbxhQiddPnTO9GrWdod6V
# QXqngwIDAQABo4IBWjCCAVYwHwYDVR0jBBgwFoAUU3m/WqorSs9UgOHYm8Cd8rID
# ZsswHQYDVR0OBBYEFBqh+GEZIA/DQXdFKI7RNV8GEgRVMA4GA1UdDwEB/wQEAwIB
# hjASBgNVHRMBAf8ECDAGAQH/AgEAMBMGA1UdJQQMMAoGCCsGAQUFBwMIMBEGA1Ud
# IAQKMAgwBgYEVR0gADBQBgNVHR8ESTBHMEWgQ6BBhj9odHRwOi8vY3JsLnVzZXJ0
# cnVzdC5jb20vVVNFUlRydXN0UlNBQ2VydGlmaWNhdGlvbkF1dGhvcml0eS5jcmww
# dgYIKwYBBQUHAQEEajBoMD8GCCsGAQUFBzAChjNodHRwOi8vY3J0LnVzZXJ0cnVz
# dC5jb20vVVNFUlRydXN0UlNBQWRkVHJ1c3RDQS5jcnQwJQYIKwYBBQUHMAGGGWh0
# dHA6Ly9vY3NwLnVzZXJ0cnVzdC5jb20wDQYJKoZIhvcNAQEMBQADggIBAG1UgaUz
# XRbhtVOBkXXfA3oyCy0lhBGysNsqfSoF9bw7J/RaoLlJWZApbGHLtVDb4n35nwDv
# QMOt0+LkVvlYQc/xQuUQff+wdB+PxlwJ+TNe6qAcJlhc87QRD9XVw+K81Vh4v0h2
# 4URnbY+wQxAPjeT5OGK/EwHFhaNMxcyyUzCVpNb0llYIuM1cfwGWvnJSajtCN3wW
# eDmTk5SbsdyybUFtZ83Jb5A9f0VywRsj1sJVhGbks8VmBvbz1kteraMrQoohkv6o
# b1olcGKBc2NeoLvY3NdK0z2vgwY4Eh0khy3k/ALWPncEvAQ2ted3y5wujSMYuaPC
# Rx3wXdahc1cFaJqnyTdlHb7qvNhCg0MFpYumCf/RoZSmTqo9CfUFbLfSZFrYKiLC
# S53xOV5M3kg9mzSWmglfjv33sVKRzj+J9hyhtal1H3G/W0NdZT1QgW6r8NDT/LKz
# H7aZlib0PHmLXGTMze4nmuWgwAxyh8FuTVrTHurwROYybxzrF06Uw3hlIDsPQaof
# 6aFBnf6xuKBlKjTg3qj5PObBMLvAoGMs/FwWAKjQxH/qEZ0eBsambTJdtDgJK0kH
# qv3sMNrxpy/Pt/360KOE2See+wFmd7lWEOEgbsausfm2usg1XTN2jvF8IAwqd661
# ogKGuinutFoAsYyr4/kKyVRd1LlqdJ69SK6YMIIHBjCCBO6gAwIBAgIQPRo1cjAV
# gmMw0BNxfoJBCDANBgkqhkiG9w0BAQwFADB9MQswCQYDVQQGEwJHQjEbMBkGA1UE
# CBMSR3JlYXRlciBNYW5jaGVzdGVyMRAwDgYDVQQHEwdTYWxmb3JkMRgwFgYDVQQK
# Ew9TZWN0aWdvIExpbWl0ZWQxJTAjBgNVBAMTHFNlY3RpZ28gUlNBIFRpbWUgU3Rh
# bXBpbmcgQ0EwHhcNMTkwNTAyMDAwMDAwWhcNMzAwODAxMjM1OTU5WjCBhDELMAkG
# A1UEBhMCR0IxGzAZBgNVBAgMEkdyZWF0ZXIgTWFuY2hlc3RlcjEQMA4GA1UEBwwH
# U2FsZm9yZDEYMBYGA1UECgwPU2VjdGlnbyBMaW1pdGVkMSwwKgYDVQQDDCNTZWN0
# aWdvIFJTQSBUaW1lIFN0YW1waW5nIFNpZ25lciAjMTCCAiIwDQYJKoZIhvcNAQEB
# BQADggIPADCCAgoCggIBAMtRUP9W/vx4Y3ABk1qeGPQ7U/YHryFs9aIPfR1wLYR0
# SIucipUFPVmE+ZGAeVEs2Yq3wQuaugqKzWZPA4sBuzDKq73bwE8SXvwKzOJFsAE4
# irtN59QcVJjtOVjPW8IvRZgxCvk1OLgxLm20Hjly4bgqvp+MjBqlRq4LK0yZ/ixL
# /Ci5IjpmF9CqVoohwPOWJLTQhSZruvBvZJh5pq29XNhTaysK1nKKhUbjDRgG2sZ7
# QVY2mxU+8WoRoPdm9RjQgFVjh2hm6w55VYJco+1JuHGGnpM3sGuj6mJso66W6Ln9
# i6vG9llbADxXIBgtcAOnnO+S63mhx13sfLSPS9/rXfyjIN2SOOVqUTprhZxMoJgI
# aVsG5yoZ0JWTiztrigUJKdjW2tvjcvpcSi97FVaGMr9/BQmdLSrPUOHmYSDbxwaA
# XE4URr6uV3Giqmwwkxx+d8sG6VfNkfXVM3Ic4drKbuvzD+x5W7snnuge/i/yu3/p
# 5dBn67gNfKQrWQOLle0iKM36LDvHFhGv49axUGdpxY71edCt/4fM+H+q+aLtYfjI
# jWnasfRRketnV9FkEetkywO9SVU6RUMYLCVs0S8MLW/1QTUkoPJjWRZf2aTpLE7b
# uzESxm34W24D3MsVjxuNcuzbDxWQ1hJO7uIAMSWTNW9qW6USY0ABirlpiDqIuA8Z
# AgMBAAGjggF4MIIBdDAfBgNVHSMEGDAWgBQaofhhGSAPw0F3RSiO0TVfBhIEVTAd
# BgNVHQ4EFgQUb02GB9gyJ54sKdLQEwOAgd0FgykwDgYDVR0PAQH/BAQDAgbAMAwG
# A1UdEwEB/wQCMAAwFgYDVR0lAQH/BAwwCgYIKwYBBQUHAwgwQAYDVR0gBDkwNzA1
# BgwrBgEEAbIxAQIBAwgwJTAjBggrBgEFBQcCARYXaHR0cHM6Ly9zZWN0aWdvLmNv
# bS9DUFMwRAYDVR0fBD0wOzA5oDegNYYzaHR0cDovL2NybC5zZWN0aWdvLmNvbS9T
# ZWN0aWdvUlNBVGltZVN0YW1waW5nQ0EuY3JsMHQGCCsGAQUFBwEBBGgwZjA/Bggr
# BgEFBQcwAoYzaHR0cDovL2NydC5zZWN0aWdvLmNvbS9TZWN0aWdvUlNBVGltZVN0
# YW1waW5nQ0EuY3J0MCMGCCsGAQUFBzABhhdodHRwOi8vb2NzcC5zZWN0aWdvLmNv
# bTANBgkqhkiG9w0BAQwFAAOCAgEAwGjts9jUUJvv03XLDzv3JNN6N0WNLO8W+1Gp
# LB+1JbWKn10LwhsgdI1mDzbLqvY2DQ9+j0tKdENlrA0q9grta23FCTjtABv45dym
# CkAFR++Eygm8Q2aDv5/t24490UFksXACLQNXWxhvHCzLHrIA6LoJL1uBBDW5qWNt
# jgjFGNHhIaz5EgoUwBLbfiWdrB0QwFqlg9IfGmZV/Jsq4uw3V47l35Yw+MCTC0MY
# +QJvqVGvuFcK8xwHaTmPN5xt15GupS5J6Ures9CMvzmQDcCBzvAqBzoMpi1R0nLz
# U8b5ve/vDGlJd58sVsTpoQg9B67FHtaEIse8fUMbWDhiTtEFJYTFQvgfL/bb+quM
# VOxFimwSTTBaUuWkFwki5u9v9V+GQ9+hLb1KRpKggZYsYZd/QG/YP4w1WqvRxqA7
# hWZUgO8fGvXxm7ChJ32y5wvP9i2cWBOUqYb8RVKiKG1/dA9SkUl66RL4qTuwkv19
# kRTpW21IlPLIlu4FOLPF7DA/4QcgBLHYi7z9sz5v8gJTBvSg7cmacqOXXwD7y2PQ
# 6M10/XXJ1DZFunsSWXLt5/J6UAB4+EOaRtjfv1TUXrHH0bwbg/Qr5wvoR8hTnswa
# rPb6inVTbCCFqdW4arokjoorCJGfNwQc9m+i3TSqkf/GFS4eQhoJKU/0xs3ikaLT
# QAyOeOMxggWSMIIFjgIBATCBkDB8MQswCQYDVQQGEwJVUzELMAkGA1UECBMCTUkx
# EjAQBgNVBAcTCUFubiBBcmJvcjESMBAGA1UEChMJSW50ZXJuZXQyMREwDwYDVQQL
# EwhJbkNvbW1vbjElMCMGA1UEAxMcSW5Db21tb24gUlNBIENvZGUgU2lnbmluZyBD
# QQIQBwNx0Q95WkBxmSuUB2Kb4jANBglghkgBZQMEAgEFAKCBhDAYBgorBgEEAYI3
# AgEMMQowCKACgAChAoAAMBkGCSqGSIb3DQEJAzEMBgorBgEEAYI3AgEEMBwGCisG
# AQQBgjcCAQsxDjAMBgorBgEEAYI3AgEVMC8GCSqGSIb3DQEJBDEiBCD0tcVCeDzm
# E4Hora9p6ByRW9hGIHjXiQbVQBjk8i6MNjANBgkqhkiG9w0BAQEFAASCAQAB4Sqx
# pHPhyA7LeGS+5t8Bb+w5cAIh4+DRrMiJ2+AOyqhAASlX3+LPkbeTUOc4YStQjYLz
# 1WpRjD1xpOcysmqSQpH9N+hJ1OiWb7rtm2YPmq0kqtQ6WV1KszSGt4DU7Tm1lgpA
# eyuZ+i6xz1oRxHOunuoDFk+aB4/twiFgKpfWTWDVQlF1RQ3dzzanTikHzovT5PmS
# AMs3fnEkhGHbOd4/imDi8fWzsIQkiGD3ykeE10qdzkdRq2UKPtH0v/UhG1nhTqxL
# vSSt3W1icJYUpn9EUafQnLq2kcfjH4pk1Gc7o85xZmISOYTVfKZEeXujMzc1qzd6
# jcSIr2lWjue2gL90oYIDSzCCA0cGCSqGSIb3DQEJBjGCAzgwggM0AgEBMIGRMH0x
# CzAJBgNVBAYTAkdCMRswGQYDVQQIExJHcmVhdGVyIE1hbmNoZXN0ZXIxEDAOBgNV
# BAcTB1NhbGZvcmQxGDAWBgNVBAoTD1NlY3RpZ28gTGltaXRlZDElMCMGA1UEAxMc
# U2VjdGlnbyBSU0EgVGltZSBTdGFtcGluZyBDQQIQPRo1cjAVgmMw0BNxfoJBCDAN
# BglghkgBZQMEAgIFAKB5MBgGCSqGSIb3DQEJAzELBgkqhkiG9w0BBwEwHAYJKoZI
# hvcNAQkFMQ8XDTIwMDYxMTE5NDU1OVowPwYJKoZIhvcNAQkEMTIEMGNYBBJb8zgL
# PFbp5/vhxqP0lNMvrCvMTjh5xr7EkcRwlufJowyyEL+8bE3uag0ORTANBgkqhkiG
# 9w0BAQEFAASCAgBSMR3evqCcHPOzfe/xJT+/DMZbl0Z2ZlmRwRxqJDISPSbL2gcN
# np+S80RhQzDdh0XTHdz18UlrjrJ1uji9k82Gu6JCeEF3AuQMymQIWMroCGr8+AQx
# zPgC63as0HR6mZ6SXw+3ajnTO+EISzCv1DsRkF3G/kQyrLUsLNEVF+59VDb/gL7F
# D8Xaqy1D2ewhYkTudJ5IZwVSyiaGyAZBXx46ys4GhwPAXlUUF3ax+CpKvlBAGWkp
# ClKq9oh5NwOAZvcnCzwF9bwe/unS3ss3B4parAVhB4RWn+D3JPKaQI8dzfUkBVhk
# L366hyhzdTU6naoI5wEYqY3frQNFWeQdu6WqED2d1pciiQsaK1WqSkuV435hPb8q
# 3OnCPyV2Rgm2RWWBJ0BW3nS3nDEJDcECD3c7NZ9vjzkfl0r5p6y2/pqp74Pt9XGz
# i8HV4kpJCrU/bQfZyf27dhlPskcspJ9ZiMhC/T3ilHBJpKxvTTVMmwRQxRilyak/
# 4p8NYh2/iGCv4IGf9H6lV4SD98/qaqL/aJ948LmDLhQAy5+7g5F7SgCn0R3C9Slj
# v2X+W/3IUfGRFzEOjXEEYCP76sOsFsQ6DM3pz2fng1qQxY+X3DrOv3LLDm7BQ4fE
# XKvHC01GHt68Y/G5Hpqu+wRlXWLLNJErLcdf9Cpkknc6dIHtLy63eklMXg==
# SIG # End signature block
