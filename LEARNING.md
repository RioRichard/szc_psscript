# Note when learn / create script Powershell

## PSscriptRoot run at place script run

For example, if script is in szc_psscript => root will be szc_psscript
In case script in szc_psscript/src => root will be szc_psscript/src
In case a script in szc_psscript call a script in szc_psscript/src => father's root will be szc_psscript while child root will be szc_psscript/src

## Powershell script have blankspace aware
