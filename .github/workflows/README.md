# GitHub Project Automation

This directory contains GitHub Actions workflows that automatically manage your GitHub Projects board.

## Workflows

### 1. `auto-populate-project.yml`
**Comprehensive project population workflow**

**Triggers:**
- 🆕 When issues are opened or reopened
- ⏰ Daily at 9 AM UTC (scheduled cleanup)
- 🔄 Manual trigger via GitHub UI

**Features:**
- Populates all open issues into the specified project
- Configurable project number and default status
- Handles bulk operations efficiently
- Runs daily to catch any missed issues

**Manual Trigger:**
1. Go to Actions tab in GitHub
2. Select "Auto-Populate GitHub Project"
3. Click "Run workflow"
4. Optionally customize project number and default status

### 2. `add-issue-to-project.yml`
**Real-time issue tracking**

**Triggers:**
- 🆕 When issues are opened
- 🔄 When issues are reopened  
- 🏷️ When issues are labeled

**Features:**
- Immediately adds new issues to project
- Lightweight and fast execution
- Provides real-time feedback

## Configuration

### Project Settings
- **Default Project Number:** 17 (Valen Roadmap)
- **Default Status:** Backlog
- **Repository:** JoshLuedeman/Valen

### Permissions
The workflows use the built-in `GITHUB_TOKEN` which has the necessary permissions to:
- Read repository contents
- Read and write issues
- Access GitHub Projects

## Monitoring

### Check Workflow Status
- Go to the "Actions" tab in your repository
- Monitor workflow runs and view logs
- Failed runs will show error details

### Troubleshooting
- Workflows log detailed output for debugging
- Check that project number 17 exists and is accessible
- Verify the Status field has the expected options

## Customization

### Change Project Number
Edit the workflows and update the project number:
```yaml
PROJECT_NUMBER: ${{ github.event.inputs.project_number || '17' }}
```

### Change Default Status
Update the default status in the workflow:
```yaml
DEFAULT_STATUS: ${{ github.event.inputs.default_status || 'Backlog' }}
```

### Add Label-Based Automation
The `project-populate.sh` script already includes intelligent label mapping:
- `committed` → Committed status
- `in progress` → In Progress status  
- `review` → In Review status
- `done` → Done status

## Scripts Used

- `scripts/project-populate.sh` - Main population script
- Automatically handles duplicate detection
- Smart status assignment based on labels
- Supports dry-run mode for testing

## Workflow Files Location
```
.github/
└── workflows/
    ├── auto-populate-project.yml
    ├── add-issue-to-project.yml
    └── ci.yml
```
