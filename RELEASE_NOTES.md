# pickle_airport v1.1.3

## Fixes

- Validate flight routes, fares and passenger reservations on the server.
- Charge fares after confirmed boarding or completed NPC transport.
- Validate mission progression and restrict aircraft tracking to authorized viewers.
- Improve cancellation, disconnect handling and ESX job-grade installation data.

## Upgrade notes

- Requires ESX or QBCore and ox_lib; standalone is unsupported.
- For an existing ESX job installation, review __INSTALLATION/Jobs/esx_grades_migration.sql.
- This resource uses ox_lib UI and has no separate nui directory.

## Package and validation

- The ZIP contains one pickle_airport/ folder with the complete resource, installation files, license and runtime NUI assets where applicable. Unbuilt web/ sources, node_modules/ and Git metadata are excluded.
- Required local NUI scripts and stylesheets were checked before packaging. Prior remediation validation passed targeted mocked regressions and Lua/JavaScript syntax checks; this is not a live FiveM integration test.
- Test the resource with your installed frameworks, inventory, database and other integrations before use. Transactions spanning framework persistence, SQL and local KVP still have crash-recovery boundaries.

Source: [audit remediation PR #7](https://github.com/PickleModsCommunity/pickle_airport/pull/7), branch `fix/audit-remediation`. This release includes the PR changes without merging the PR.
