## Variables

* `script_name`: `scripts/create_project_board.ps1`

* `config_file_path`: `.config/project.json`

* `log_file`: `logs/project_board_automation.log`

## Authentication

* Option A (classic PAT):

  * Create a token with `repo` and `project` (read/write).

  * Login: `printf '%s' '<YOUR_CLASSIC_PAT>' | gh auth login -h github.com -p https --with-token`.

* Option B (fine‑grained PAT):

  * Create a token scoped to your owner, grant repo access to `AvaPrime/codessa-code-alchemist`, set Projects: Read & Write (and Metadata: Read if prompted).

  * Login: `printf '%s' '<YOUR_FINE_GRAINED_PAT>' | gh auth login -h github.com -p https --with-token`.

## Scope Verification

* Verify header scopes (classic): `(gh api -i /user)` and confirm `X-OAuth-Scopes` includes `project`.

* For fine‑grained tokens, confirm Projects permission and approval in the token settings UI.

* Confirm repo permissions: `gh api repos/AvaPrime/codessa-code-alchemist --jq '.permissions'` → expect `admin: true`, `push: true`.

## Projects Access Sanity Check

* CLI check: `gh project create --owner AvaPrime --title "TEMP Projects Access Check"`.

* List: `gh project list --owner AvaPrime --format json` and confirm the temp project exists. Delete it if desired.

## Automation Execution

* Run: `powershell -ExecutionPolicy Bypass -File scripts/create_project_board.ps1 -Owner AvaPrime -Repo AvaPrime/codessa-code-alchemist -ProjectTitle "Validation & Governance" 2>&1 | Tee-Object -FilePath logs/project_board_automation.log -Append`.

* Capture `$ProjectUrl` and `$ProjectId` from script output; if missing, fetch via GraphQL:

  * User projects: `gh api graphql -f query='query($user:String!){ user(login:$user){ projectsV2(first:50){ nodes{ id title url number } } } }' -f user='AvaPrime'` and select by title.

## Persist Outputs

* Update config JSON (PowerShell-native):

  * `($cfg = Get-Content .config/project.json | ConvertFrom-Json); $cfg.project_url = $ProjectUrl; $cfg.project_id = $ProjectId; $cfg.status = "created"; $cfg.updated = (Get-Date).ToString("o"); $cfg | ConvertTo-Json -Depth 4 | Set-Content -Encoding utf8 .config/project.json`.

* Update documentation:

  * `"$((Get-Date).ToString('sK')) Created project: $ProjectUrl (id: $ProjectId)" | Add-Content final_status_next_steps.md` under "Deployment Details".

## Validation

* URL accessibility: `Invoke-WebRequest -Uri $ProjectUrl -Method Head -UseBasicParsing` → expect status `200`.

* Identifier check: `Invoke-WebRequest -Uri $ProjectUrl -UseBasicParsing` → ensure `$ProjectId` appears in content or confirm via GraphQL:

  * `gh api graphql -f query='query($id:ID!){ node(id:$id){ __typename ... on ProjectV2 { id title number url } } }' -F id="$ProjectId"`.

* Critical endpoints: verify primary page and key assets respond `200` via `Invoke-WebRequest -Method Head`.

* Timestamp: compare `updated` in `.config/project.json` and the appended line in `final_status_next_steps.md` to current time.

## Deviation Logging

* Append any errors or unexpected responses with timestamps to `logs/project_board_automation.log`.

* Include headers (for scope visibility), status codes, GraphQL error messages, and remediation steps taken.

## Fallbacks

* Use `gh project create`/`gh project` commands to create and fetch `id`/`url` if the PowerShell script encounters schema drift.

* If Projects access still fails, proceed with manual board creation and record the manual URL in `config_file_path` and documentation.

## Success Criteria

* `project` scope (classic) or Projects permission (fine‑grained) confirmed.

* Automation completes and outputs `ProjectUrl` and `ProjectId`.

* `.config/project.json` updated with `project_url`, `project_id`, `status: created`, and `updated` timestamp.

* `final_status_next_steps.md` updated under "Deployment Details" with timestamp, URL, and ID.

* URL returns `200`, identifier validates, endpoints respond, timestamps match.

* `log_file` contains a complete trace of actions and any deviations.

