$KeyFile = "C:\Users\thoma\Desktop\Project D3\Scripts\MasterKey.key"
$PasswordFile = "C:\Users\thoma\Desktop\Project D3\Scripts\VC-Password.txt"

$Password = Get-Content $PasswordFile | ConvertTo-SecureString -Key (Get-Content $KeyFile)
$UserName = "thomas.vanhaute@vsphere.local" 
$credential = New-Object System.Management.Automation.PsCredential($UserName,$Password)

$auth = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($Credential.UserName+':'+$Credential.GetNetworkCredential().Password))
$head = @{
  'Authorization' = "Basic $auth"
}

#Ignore SelfSign Cert 
if (-not ([System.Management.Automation.PSTypeName]'ServerCertificateValidationCallback').Type)
{
$certCallback = @"
    using System;
    using System.Net;
    using System.Net.Security;
    using System.Security.Cryptography.X509Certificates;
    public class ServerCertificateValidationCallback
    {
        public static void Ignore()
        {
            if(ServicePointManager.ServerCertificateValidationCallback ==null)
            {
                ServicePointManager.ServerCertificateValidationCallback += 
                    delegate
                    (
                        Object obj, 
                        X509Certificate certificate, 
                        X509Chain chain, 
                        SslPolicyErrors errors
                    )
                    {
                        return true;
                    };
            }
        }
    }
"@
    Add-Type $certCallback
 }
[ServerCertificateValidationCallback]::Ignore()

$VCSA_IP = "10.129.28.192"
$RestApi = Invoke-WebRequest -Uri https://$VCSA_IP/rest/com/vmware/cis/session -Method Post -Headers $head
$token = (ConvertFrom-Json $RestApi.Content).value
$session = @{'vmware-api-session-id' = $token}

$r1 = Invoke-WebRequest -Uri https://$VCSA_IP/rest/vcenter/vm -Method Get -Headers $session
$vms = (ConvertFrom-Json $r1.Content).value
$vms
$vms.Count

