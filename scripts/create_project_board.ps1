Param(
  [string]$Owner = "AvaPrime",
  [string]$Repo = "AvaPrime/codessa-code-alchemist",
  [string]$ProjectTitle = "Validation & Governance"
)

$ErrorActionPreference = "Stop"

function RequireGh() {
  if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    Write-Error "GitHub CLI (gh) is not installed. Install from https://cli.github.com/"
  }
  gh --version | Out-Host
  gh auth status | Out-Host
}

function GhGraphQL([string]$Query) {
  return gh api graphql -f query=$Query --jq '.' | ConvertFrom-Json
}

RequireGh

# 1) Get owner user ID
$viewer = GhGraphQL 'query { viewer { id login } }'
if ($viewer.data.viewer.login -ne $Owner) {
  Write-Host "Authenticated as $($viewer.data.viewer.login); targeting owner $Owner"
}

# 2) Get owner ID and existing projects
$ownerQuery = @'
query($login: String!) {
  user(login: $login) {
    id
    projectsV2(first: 50) {
      nodes { id title number url }
    }
  }
}
'@
$ownerData = gh api graphql -f query="$ownerQuery" -F login=$Owner | ConvertFrom-Json
$userId = $ownerData.data.user.id
$existing = $ownerData.data.user.projectsV2.nodes | Where-Object { $_.title -eq $ProjectTitle }

if (-not $existing) {
  Write-Host "Creating project '$ProjectTitle' for owner '$Owner'..."
$createProject = @' 
  mutation($ownerId: ID!, $title: String!) {
    createProjectV2(input: { ownerId: $ownerId, title: $title }) {
      projectV2 { id title number url }
    }
  }
'@
  $projRes = gh api graphql -f query="$createProject" -F ownerId=$userId -F title=$ProjectTitle | ConvertFrom-Json
  $project = $projRes.data.createProjectV2.projectV2
} else {
  $project = $existing
  Write-Host "Project already exists: $($project.url)"
}

Write-Host "Project Number: $($project.number)"
Write-Host "Project URL:     $($project.url)"

# 3) Ensure 'Status' single-select field with options
$fieldsQuery = @' 
query($projectId: ID!) {
  node(id: $projectId) {
    ... on ProjectV2 {
      id
      fields(first: 50) {
        nodes {
          id
          name
          __typename
          ... on ProjectV2SingleSelectField { options { id name } }
        }
      }
    }
  }
}
'@
$fieldsData = gh api graphql -f query="$fieldsQuery" -F projectId=$($project.id) | ConvertFrom-Json
$fields = $fieldsData.data.node.fields.nodes
$statusField = $fields | Where-Object { $_.name -eq 'Status' }

if (-not $statusField) {
  Write-Host "Adding 'Status' field..."
$addField = @' 
  mutation($projectId: ID!) {
    addProjectV2Field(input: { projectId: $projectId, name: "Status", dataType: SINGLE_SELECT }) {
      projectV2Field { id }
    }
  }
'@
  $addFieldRes = gh api graphql -f query="$addField" -F projectId=$($project.id) | ConvertFrom-Json
  $statusFieldId = $addFieldRes.data.addProjectV2Field.projectV2Field.id
  # Set options
$setOptions = @' 
  mutation($projectId: ID!, $fieldId: ID!) {
    updateProjectV2SingleSelectField(input: {
      projectId: $projectId,
      fieldId: $fieldId,
      options: [
        { name: "Backlog" },
        { name: "In Progress" },
        { name: "Done" }
      ]
    }) { projectV2SingleSelectField { id options { id name } } }
  }
'@
  $optRes = gh api graphql -f query="$setOptions" -F projectId=$($project.id) -F fieldId=$statusFieldId | ConvertFrom-Json
  $statusField = $optRes.data.updateProjectV2SingleSelectField.projectV2SingleSelectField
} else {
  $statusFieldId = $statusField.id
}

$backlogOption = $statusField.options | Where-Object { $_.name -eq 'Backlog' }
if (-not $backlogOption) {
  Write-Error "Backlog option missing on Status field"
}

# 4) Get open issues in milestone 'Validation & Readiness'
$issuesQuery = @' 
query($owner: String!, $name: String!) {
  repository(owner: $owner, name: $name) {
    id
    issues(first: 100, states: OPEN, orderBy: {field: CREATED_AT, direction: ASC}) {
      nodes { id number title milestone { title } }
    }
  }
}
'@
$repoParts = $Repo.Split('/')
$issuesData = gh api graphql -f query="$issuesQuery" -F owner=$($repoParts[0]) -F name=$($repoParts[1]) | ConvertFrom-Json
$allIssues = $issuesData.data.repository.issues.nodes
$milestoneIssues = $allIssues | Where-Object { $_.milestone -and $_.milestone.title -eq 'Validation & Readiness' }

if (-not $milestoneIssues) {
  Write-Host "No open issues found for milestone 'Validation & Readiness'. Exiting."
  exit 0
}

# 5) Add each issue to project and set Status=Backlog
foreach ($issue in $milestoneIssues) {
  Write-Host "Adding issue #$($issue.number): $($issue.title)"
$addItem = @' 
  mutation($projectId: ID!, $contentId: ID!) {
    addProjectV2ItemById(input: { projectId: $projectId, contentId: $contentId }) {
      item { id }
    }
  }
'@
  $addItemRes = gh api graphql -f query="$addItem" -F projectId=$($project.id) -F contentId=$($issue.id) | ConvertFrom-Json
  $itemId = $addItemRes.data.addProjectV2ItemById.item.id

$setField = @' 
  mutation($projectId: ID!, $itemId: ID!, $fieldId: ID!, $optionId: String!) {
    updateProjectV2ItemFieldValue(input: {
      projectId: $projectId,
      itemId: $itemId,
      fieldId: $fieldId,
      value: { singleSelectOptionId: $optionId }
    }) { projectV2Item { id } }
  }
'@
  gh api graphql -f query="$setField" -F projectId=$($project.id) -F itemId=$itemId -F fieldId=$statusFieldId -F optionId=$($backlogOption.id) | Out-Null
}

Write-Host "Done. Project populated: $($project.url)"
