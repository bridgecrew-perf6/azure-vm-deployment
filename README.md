# Azure VM deployment using Powershell
## SH homework

### Prerequisites
- Azure account atleast free one (https://azure.microsoft.com/en-us/free/)
- Browser
- RSA public key

### Deployment
1. Open Powershell console at https://portal.azure.com
2. Upload these files an add also your public key, clicking on upload icon. You can also clone this repository. Your public key shoud be in standard path (~/.ssh/id_rsa.pub). If you have it elsewhere, pelase update script accordingly.
3. Run Powershell sript following way: `./shs-homework.ps1`
4. There will be created VM without SSH access. If you want to log into VM, update security rule named: "testNetworkSecurityGroupRuleSSH" with param "Access" set to "Allow".
