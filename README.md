<p align="center">
  <a href="" rel="noopener">
 <img width=200px height=200px src="./images/drinkwater.png" alt="Project logo"></a>
</p>

<h3 align="center">Hydration Reminder</h3>

<div align="center">

[![Status](https://img.shields.io/badge/status-active-success.svg)]()
[![GitHub Issues](https://img.shields.io/github/issues/mmcmd/HydrationReminder.svg)](https://github.com/kylelobo/The-Documentation-Compendium/issues)
[![GitHub Pull Requests](https://img.shields.io/github/issues-pr/mmcmd/HydrationReminder.svg)](https://github.com/mmcmd/HydrationReminder/pulls)
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![CodeFactor](https://www.codefactor.io/repository/github/mmcmd/hydrationreminder/badge)](https://www.codefactor.io/repository/github/mmcmd/hydrationreminder)
</div>

---

<p align="center"> A PowerShell module designed to remind you via Windows notification to drink some water every so often in order to stay hydrated!
    <br> 
</p>

## 📝 Table of Contents

- [About](#about)
- [Getting Started](#getting_started)
- [Deployment](#deployment)
- [Usage](#usage)
- [Built Using](#built_using)
- [Contributing](../CONTRIBUTING.md)
- [Authors](#authors)
- [Acknowledgments](#acknowledgement)

## 🧐 About <a name = "about"></a>

A fairly simple module to remind you (by default every hour) to drink some water in order to stay hydrated. Inspired by a Twitch [Hydration bot](https://github.com/Vuurvos1/stayHydratedFox)

## 🏁 Getting Started <a name = "getting_started"></a>

### Prerequisites

- Powershell 5.1 or higher

- BurntToast PowerShell module from the PowerShell gallery
```powershell
Install-Module BurntToast
```

- Windows 10/Windows Server 2019 or higher

### Installing

- This module can be obtained from the PSGallery. Simply run the following command in an elevated command prompt:
```powershell
Install-Module HydrationReminder
```

## 🎈 Usage <a name="usage"></a>

Running `Get-Help Start-HydrationReminder` will provide additional examples and details on how to use the command

Parameter list and description:
Parameters | Type | Functionality
-----------|------|---------------
ReminderInterval | Integer | Interval in minutes at which you will receive a notification to drink. Default is 60 minutes (1 hour)
DailyWaterInstake | Integer | Amount of daily water intake needed (in mL). Default is 2000mL (2L)
Duration | Integer | Amount in hours you want to be reminded for. Default is 16 hours (average amount of time a human is awake for before going to sleep)



## 🚀 Deployment <a name = "deployment"></a>

It is encouraged to create a task with Task Scheduler to run the command `Start-HydrationReminder` on logon.
It is possible to simply run the code below in order to create this sort of task:
```powershell
# Insert code here
```

## ⛏️ Built Using <a name = "built_using"></a>

- [PowerShell](https://docs.microsoft.com/en-us/powershell/scripting/overview?view=powershell-5.1)
- [BurntToast](https://github.com/Windos/BurntToast)

## ✍️ Authors <a name = "authors"></a>

- [@mmcmd](https://github.com/mmcmd) - Idea & Initial work

See also the list of [contributors](https://github.com/mmcmd/HydrationReminder/contributors) who participated in this project.

## 🎉 Acknowledgements <a name = "acknowledgement"></a>

- [BurntToast](https://github.com/Windos/BurntToast) for simplifying sending Windows notifications
- Inspired by Twitch's [Hydration bot](https://github.com/Vuurvos1/stayHydratedFox)
