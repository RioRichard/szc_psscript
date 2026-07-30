# Note when learn / create script Powershell

## PSscriptRoot run at place script run

For example, if script is in szc_psscript => root will be szc_psscript
In case script in szc_psscript/src => root will be szc_psscript/src
In case a script in szc_psscript call a script in szc_psscript/src => father's root will be szc_psscript while child root will be szc_psscript/src

## Powershell script have blankspace aware

## JSON Config Id Resolution

The JSON config files (`apps.json`, `printers.json`, `departments.json`) use stable `id` fields to cross-reference items. Departments reference apps/printers by id, not display name. At load time, ids are resolved to display names using lookup hashtables built from `$CommonApps` and `$Printers`. This allows changing display names without breaking department definitions.
