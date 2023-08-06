# Welcome !

This repo holds scripts to add some dual mining on some Helium hotspots.

THIS GITHUB REPO IS NOT AFFILIATED WITH DEFLI NOR WINGBITS NOR ANY OTHER COMPANY.

It is built on my spare time.

# Projects

[Wingbits Website](https://wingbits.com/)  
[Wingbits Discord](https://discord.com/invite/ZmpRW73qRH)  
[Defli Website](https://defli.network/)  
[Defli Discord](https://discord.gg/PpKMhCmewy)

🚨  
🚨 Any project can be a SCAM. Do you own research. Start by reading [how to detect a SCAM](https://www.investopedia.com/articles/forex/042315/beware-these-five-bitcoin-scams.asp)  
🚨  

# Scripts

Execute Defli then Wingbits scripts, in this order. You don't need to complete defli infos but you need to run the defli script first.

The `.ps1` scripts for windows machines will ssh to the given IP and executes the `.sh` script on it.  Instead you can run the ".sh" script directly from a ssh session on the target device.

It supports both balena and docker, so it can run on Pisces, Sensecap, Nebra, and other Raspberry PI devices having docker or balena installed. It will create configuration folders in /mnt/data/ though.

The scripts will ask you all required info for onboarding. You can run the script multiple times, for example to change the location of elevation.

## From Windows
- Install the latest version of [microsoft powershell](https://www.microsoft.com/store/productId/9MZ1SNWT0N5D) from the windows store.
- Download both the `.ps1` and the `.sh` files from this github in some folder
- open a command prompt in that folder (enter "pwsh" in the search box of the window's taskbar)
```powershell
cd "c:\...\the folder where you downloaded the files"
pwsh -ExecutionPolicy Bypass -File ".\windows_defli_installer.ps1" 10.128.12.1
pwsh -ExecutionPolicy Bypass -File ".\wingbits.ps1" 10.128.12.1
```
Replace `10.128.12.1` by the IP of your device.

## Directly from within the device
- ssh into your device, download the .sh file and run it
```shell
cat ./rpi_defli_installer.sh | sudo bash
cat ./wingbits.sh | sudo bash
```

# Tip

Donate if that script helped you !  
I'd love to visit USA.

Multi chain Metamask account (BSC, Etherum, Arbitrum, Doge, Polygon, Avalanche, ...):

0xe0018e74856e68A62d142Ab1C77b0F7B0ca3a2Ea

![image](https://github.com/softlion/defli/assets/190756/9d4f1589-5f7f-46f4-ae0d-1190d2e22762)
