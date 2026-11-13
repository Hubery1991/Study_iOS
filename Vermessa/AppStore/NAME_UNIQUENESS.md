# Vermessa name check

Checked on 13 November 2026 against the iTunes Search API.

Request pattern:

`https://itunes.apple.com/search?term=Vermessa&country=CODE&entity=software&limit=200`

Countries: US, GB, JP, CN, DE, FR, CA, AU, KR.

An exact match means a software result whose `trackName` is `Vermessa`, ignoring case and surrounding spaces.

## Result

| Country | Result count | Exact Vermessa match |
| --- | ---: | --- |
| US | 4 | No |
| GB | 4 | No |
| JP | 0 | No |
| CN | 0 | No |
| DE | 0 | No |
| FR | 0 | No |
| CA | 4 | No |
| AU | 4 | No |
| KR | 0 | No |

The raw responses are in `name-search/`. None of the JSON files contain the string Vermessa.

The nearby US, GB, CA, and AU hits are unrelated apps: Verena Russia, VushtrriaOnline, VEXORA AI, and TK Veículos. They do not use the name Vermessa.

## Decision

Keep the name Vermessa. There is no exact App Store software match in the nine storefronts above, so the name is free to use for this app. The bundle ID, icon wordmark, listing, and interface all use Vermessa.
