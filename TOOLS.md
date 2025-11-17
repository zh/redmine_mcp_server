# Redmine MCP Server - Available Tools

This document lists all available MCP tools for interacting with Redmine.

## Tool Status Legend

- ✅ **Implemented** - Fully functional and ready to use
- ⏳ **Skeleton** - Structure defined, implementation pending

## Enabling Skeleton Tools

By default, only implemented tools are registered. To enable skeleton tools for testing:

```bash
# Enable all tools including skeletons
MCP_REGISTER_SKELETONS=true bundle exec rackup config.ru -p 3100
```

**Note:** Skeleton tools will raise `NotImplementedError` when called.

---

## Projects (6 tools) ✅ FULLY IMPLEMENTED

All project tools are fully implemented and ready to use.

### `list_projects` ✅
List all accessible projects from Redmine with pagination and filtering.

**Parameters:**
- `limit` (integer, optional): Maximum number of projects (1-100, default: 25)
- `offset` (integer, optional): Pagination offset (default: 0)
- `include` (string, optional): Related data (trackers, issue_categories, enabled_modules)
- `status` (string, optional): Filter by status (active, archived, closed)

### `get_project` ✅
Get detailed information about a specific project.

**Parameters:**
- `id` (string/integer, required): Project ID or identifier
- `include` (string, optional): Related data to include

### `create_project` ✅
Create a new project in Redmine.

**Parameters:**
- `name` (string, required): Project name
- `identifier` (string, required): Unique identifier (lowercase, numbers, dashes, underscores)
- `description` (string, optional): Project description
- `homepage` (string, optional): Homepage URL
- `is_public` (boolean, optional): Public visibility (default: true)
- `parent_id` (integer, optional): Parent project ID for subprojects
- `inherit_members` (boolean, optional): Inherit parent members
- `enabled_module_names` (array, optional): Modules to enable
- `tracker_ids` (array, optional): Tracker IDs to enable
- `custom_fields` (array, optional): Custom field values

### `update_project` ✅
Update an existing project (partial updates supported).

**Parameters:**
- `id` (string/integer, required): Project ID or identifier
- All fields from `create_project` are optional for updates

### `delete_project` ✅
Permanently delete a project and all associated data.

**Parameters:**
- `id` (string/integer, required): Project ID or identifier
- `confirm` (boolean, required): Must be `true` to confirm deletion

---

## Issues (13 tools) ✅ FULLY IMPLEMENTED

All issue management tools are fully implemented using native Redmine API.

### `list_issues` ✅
List issues from Redmine with filtering, sorting, and pagination.

**Parameters:**
- `project_id` (string/integer, optional): Filter by project ID or identifier
- `tracker_id` (integer, optional): Filter by tracker ID
- `status_id` (string/integer, optional): Filter by status ID ("open", "closed", "*", or ID)
- `assigned_to_id` (integer, optional): Filter by assignee user ID
- `limit` (integer, optional): Maximum number to return (1-100, default: 25)
- `offset` (integer, optional): Pagination offset (default: 0)
- `sort` (string, optional): Sort field with optional :desc suffix (e.g., "updated_on:desc")
- `include` (string, optional): Related data (attachments, relations, journals, watchers)

### `get_issue` ✅
Get detailed information about a specific issue.

**Parameters:**
- `issue_id` (integer, required): Issue ID to retrieve
- `include` (string, optional): Related data to include

### `create_issue` ✅
Create a new issue in Redmine.

**Parameters:**
- `project_id` (string/integer, required): Project ID or identifier
- `tracker_id` (integer, required): Tracker ID
- `subject` (string, required): Issue subject/title
- `status_id` (integer, optional): Status ID
- `priority_id` (integer, optional): Priority ID
- `description` (string, optional): Issue description
- `assigned_to_id` (integer, optional): Assignee user ID
- `parent_issue_id` (integer, optional): Parent issue ID
- `estimated_hours` (number, optional): Estimated hours
- `done_ratio` (integer, optional): Done ratio (0-100)
- `start_date` (string, optional): Start date (YYYY-MM-DD)
- `due_date` (string, optional): Due date (YYYY-MM-DD)
- `custom_field_values` (object, optional): Custom field values
- `watcher_user_ids` (array, optional): Array of watcher user IDs

### `update_issue` ✅
Update an existing issue.

**Parameters:**
- `issue_id` (integer, required): Issue ID to update
- All fields from `create_issue` are optional for updates
- `notes` (string, optional): Comment/note to add to the issue

### `delete_issue` ✅
Delete an issue.

**Parameters:**
- `issue_id` (integer, required): Issue ID to delete

### `add_issue_watcher` (add_watcher) ✅
Add a watcher to an issue.

**Parameters:**
- `issue_id` (integer, required): Issue ID
- `user_id` (integer, required): User ID to add as watcher

### `remove_issue_watcher` (remove_watcher) ✅
Remove a watcher from an issue.

**Parameters:**
- `issue_id` (integer, required): Issue ID
- `user_id` (integer, required): User ID to remove as watcher

### `get_issue_relations` (get_relations) ✅
Get all relations for an issue (blocks, relates to, precedes, etc.).

**Parameters:**
- `issue_id` (integer, required): Issue ID to get relations for

### `create_issue_relation` (create_relation) ✅
Create a relation between two issues.

**Parameters:**
- `issue_id` (integer, required): Source issue ID
- `issue_to_id` (integer, required): Target issue ID
- `relation_type` (string, required): Relation type (relates, duplicates, duplicated, blocks, blocked, precedes, follows, copied_to, copied_from)
- `delay` (integer, optional): Delay in days (for precedes/follows)

### `delete_issue_relation` (delete_relation) ✅
Delete an issue relation.

**Parameters:**
- `relation_id` (integer, required): Relation ID to delete

### `get_issue_journals` (get_journals) ✅
Get the change history (journals) for an issue.

**Parameters:**
- `issue_id` (integer, required): Issue ID to get journals for

### `copy_issue` ✅
Copy an issue to another project or within the same project.

**Parameters:**
- `issue_id` (integer, required): Source issue ID to copy
- `project_id` (string/integer, optional): Target project (defaults to same project)
- `tracker_id` (integer, optional): New tracker ID
- `copy_attachments` (boolean, optional): Copy attachments (default: false)
- `copy_subtasks` (boolean, optional): Copy subtasks (default: false)
- `copy_watchers` (boolean, optional): Copy watchers (default: false)
- `link_copy` (boolean, optional): Link to original issue (default: false)

### `move_issue` ✅
Move an issue to a different project.

**Parameters:**
- `issue_id` (integer, required): Issue ID to move
- `project_id` (string/integer, required): Target project ID or identifier
- `tracker_id` (integer, optional): New tracker ID
- `copy_subtasks` (boolean, optional): Move subtasks (default: false)

---

## Users (5 tools) ✅ FULLY IMPLEMENTED

All user management tools are fully implemented using native Redmine API. Requires admin privileges.

### `list_users` ✅
List all users from Redmine with filtering and pagination.

**Parameters:**
- `limit` (integer, optional): Maximum number to return (1-100, default: 25)
- `offset` (integer, optional): Pagination offset (default: 0)
- `status` (integer, optional): Filter by status (0=anonymous, 1=active, 2=registered, 3=locked, default: 1)
- `name` (string, optional): Filter by login, firstname, lastname, or mail (partial match)
- `group_id` (integer, optional): Filter by group membership

### `get_user` ✅
Get detailed information about a specific user.

**Parameters:**
- `user_id` (integer/string, required): User ID or "current" for current user
- `include` (string, optional): Related data (groups, memberships)

### `create_user` ✅
Create a new user account in Redmine. Requires admin privileges.

**Parameters:**
- `login` (string, required): User login (username)
- `firstname` (string, required): User first name
- `lastname` (string, required): User last name
- `mail` (string, required): User email address
- `password` (string, optional): User password (if omitted, user must activate via email)
- `auth_source_id` (integer, optional): Authentication source ID (LDAP, etc.)
- `mail_notification` (string, optional): Email notification setting (all, selected, only_my_events, only_assigned, only_owner, none)
- `must_change_password` (boolean, optional): Force password change on first login
- `generate_password` (boolean, optional): Generate random password
- `send_information` (boolean, optional): Send account information to user via email
- `admin` (boolean, optional): Grant admin privileges
- `custom_field_values` (object, optional): Custom field values

### `update_user` ✅
Update an existing user account.

**Parameters:**
- `user_id` (integer, required): User ID to update
- All fields from `create_user` are optional for updates

### `delete_user` ✅
Delete a user account. Requires admin privileges.

**Parameters:**
- `user_id` (integer, required): User ID to delete

---

## Time Entries (6 tools) ✅ FULLY IMPLEMENTED

All time entry tools are fully implemented using native Redmine API and Extended API plugin.

### `list_time_entries` ✅
List time entries from Redmine with filtering by user, project, issue, or date range.

**Parameters:**
- `user_id` (integer, optional): Filter by user ID
- `project_id` (integer, optional): Filter by project ID
- `issue_id` (integer, optional): Filter by issue ID
- `spent_on` (string, optional): Filter by specific date (YYYY-MM-DD)
- `from` (string, optional): Filter entries from this date (YYYY-MM-DD)
- `to` (string, optional): Filter entries until this date (YYYY-MM-DD)
- `limit` (integer, optional): Maximum number to return (1-100, default: 25)
- `offset` (integer, optional): Pagination offset (default: 0)

### `get_time_entry` ✅
Get detailed information about a specific time entry including project, issue, user, activity, and custom field values.

**Parameters:**
- `time_entry_id` (integer, required): Time entry ID to retrieve

### `create_time_entry` ✅
Log time on an issue or project. Requires either issue_id or project_id, plus hours and activity.

**Parameters:**
- `issue_id` (integer, optional): Issue ID to log time against (required if project_id not provided)
- `project_id` (integer, optional): Project ID to log time against (required if issue_id not provided)
- `spent_on` (string, optional): Date the time was spent (YYYY-MM-DD, default: today)
- `hours` (number, required): Hours spent
- `activity_id` (integer, required): Activity ID (e.g., Development, Design, Testing)
- `comments` (string, optional): Comments/description of work done
- `custom_field_values` (object, optional): Custom field values as key-value pairs

### `update_time_entry` ✅
Update an existing time entry. Can modify hours, date, activity, comments, or custom fields.

**Parameters:**
- `time_entry_id` (integer, required): Time entry ID to update
- `issue_id` (integer, optional): Issue ID to log time against
- `project_id` (integer, optional): Project ID to log time against
- `spent_on` (string, optional): Date the time was spent (YYYY-MM-DD)
- `hours` (number, optional): Hours spent
- `activity_id` (integer, optional): Activity ID
- `comments` (string, optional): Comments/description of work done
- `custom_field_values` (object, optional): Custom field values as key-value pairs

### `delete_time_entry` ✅
Delete a time entry. Requires appropriate permissions to delete the time entry.

**Parameters:**
- `time_entry_id` (integer, required): Time entry ID to delete

### `bulk_create_time_entries` ✅
Create multiple time entries in a single request. Uses the Extended API plugin. Returns summary of created and failed entries.

**Parameters:**
- `time_entries` (array, required): Array of time entry objects. Each object can have:
  - `issue_id` (integer, optional): Issue ID (required if project_id not provided)
  - `project_id` (integer, optional): Project ID (required if issue_id not provided)
  - `spent_on` (string, optional): Date the time was spent (YYYY-MM-DD)
  - `hours` (number, required): Hours spent
  - `activity_id` (integer, required): Activity ID
  - `comments` (string, optional): Comments/description
  - `custom_field_values` (object, optional): Custom field values

---

## Custom Fields (4 tools) ✅ FULLY IMPLEMENTED

All custom field tools are fully implemented using native Redmine API (read) and Extended API plugin (CRUD).

### `list_custom_fields` ✅
List all custom fields in Redmine. Returns all field types (Issue, Project, User, etc.) with their configuration including field format, validators, and visibility settings.

**Parameters:**
None

### `create_custom_field` ✅
Create a new custom field in Redmine. Uses the Extended API plugin. Requires admin permissions. Supports Issue, Project, User, Time Entry, and other field types.

**Parameters:**
- `type` (string, optional): Custom field type (default: IssueCustomField). Options: IssueCustomField, ProjectCustomField, TimeEntryCustomField, UserCustomField, GroupCustomField, VersionCustomField, DocumentCustomField
- `name` (string, required): Custom field name
- `field_format` (string, required): Field format. Options: string, text, int, float, date, bool, list, user, version, link, attachment
- `is_required` (boolean, optional): Whether the field is required
- `is_for_all` (boolean, optional): Whether the field is available for all projects (for Issue custom fields)
- `default_value` (string, optional): Default value for the field
- `min_length` (integer, optional): Minimum length for text fields
- `max_length` (integer, optional): Maximum length for text fields
- `regexp` (string, optional): Regular expression for validation
- `multiple` (boolean, optional): Allow multiple values (for list fields)
- `visible` (boolean, optional): Whether the field is visible
- `searchable` (boolean, optional): Whether the field is searchable
- `description` (string, optional): Description of the custom field
- `editable` (boolean, optional): Whether the field is editable
- `tracker_ids` (array, optional): Array of tracker IDs (for Issue custom fields)
- `possible_values` (array, optional): Possible values for list fields
- `project_ids` (array, optional): Array of project IDs (when is_for_all is false)
- `role_ids` (array, optional): Array of role IDs that can see this field

### `update_custom_field` ✅
Update an existing custom field in Redmine. Uses the Extended API plugin. Requires admin permissions. Can modify name, validators, visibility, and other settings.

**Parameters:**
- `custom_field_id` (integer, required): Custom field ID to update
- All fields from `create_custom_field` are optional for updates (except `custom_field_id`)

### `delete_custom_field` ✅
Delete a custom field from Redmine. Uses the Extended API plugin. Requires admin permissions. Cannot delete custom fields that are in use.

**Parameters:**
- `custom_field_id` (integer, required): Custom field ID to delete

**Note on Custom Field Values:** Custom field values can be set in issues, projects, users, and other entities using the `custom_field_values` or `custom_fields` parameter in their respective create/update tools. For example:
- `create_issue` with `custom_field_values: { "1": "value", "2": "value" }`
- `update_project` with `custom_fields: [{ id: 1, value: "value" }]`

---

## Versions (5 tools) ✅ FULLY IMPLEMENTED

All version/milestone tools are fully implemented using native Redmine API.

### `list_versions` ✅
List all versions/milestones for a specific project.

**Parameters:**
- `project_id` (integer, required): Project ID to list versions for

### `get_version` ✅
Get detailed information about a specific version/milestone.

**Parameters:**
- `version_id` (integer, required): Version ID to retrieve

### `create_version` ✅
Create a new version/milestone for a project.

**Parameters:**
- `project_id` (integer, required): Project ID to create the version in
- `name` (string, required): Version name
- `description` (string, optional): Version description
- `status` (string, optional): Version status (open, locked, closed)
- `sharing` (string, optional): Sharing mode (none, descendants, hierarchy, tree, system)
- `due_date` (string, optional): Due date in YYYY-MM-DD format
- `wiki_page_title` (string, optional): Associated wiki page title

### `update_version` ✅
Update an existing version/milestone.

**Parameters:**
- `version_id` (integer, required): Version ID to update
- All fields from `create_version` are optional for updates

### `delete_version` ✅
Delete a version/milestone from a project.

**Parameters:**
- `version_id` (integer, required): Version ID to delete
**Note:** Version must not have any assigned issues.

---

## Wiki Pages (6 tools) ⏳ SKELETON

### `list_wiki_pages` ⏳
List wiki pages in a project.

### `get_wiki_page` ⏳
Get content of a specific wiki page.

### `create_wiki_page` ⏳
Create a new wiki page.

### `update_wiki_page` ⏳
Update an existing wiki page.

### `delete_wiki_page` ⏳
Delete a wiki page.

### `list_wiki_versions` ⏳
List version history of a wiki page.

---

## Attachments (3 tools) ⏳ SKELETON

### `upload_attachment` ⏳
Upload a file attachment to Redmine.

### `get_attachment` ⏳
Get information about an attachment.

### `delete_attachment` ⏳
Delete an attachment.

---

## Memberships (5 tools) ✅ FULLY IMPLEMENTED

All membership management tools are fully implemented using native Redmine API.

### `list_memberships` ✅
List all memberships for a specific project.

**Parameters:**
- `project_id` (integer, required): Project ID to list memberships for
- `limit` (integer, optional): Maximum number to return (1-100, default: 25)
- `offset` (integer, optional): Pagination offset (default: 0)

### `get_membership` ✅
Get details of a specific project membership.

**Parameters:**
- `membership_id` (integer, required): Membership ID to retrieve

### `create_membership` ✅
Add a user or group to a project with specified roles.

**Parameters:**
- `project_id` (integer, required): Project ID to add the member to
- `user_id` (integer, required): User ID or Group ID to add
- `role_ids` (array of integers, required): Role IDs to assign (at least one)

### `update_membership` ✅
Update the roles assigned to a project membership.

**Parameters:**
- `membership_id` (integer, required): Membership ID to update
- `role_ids` (array of integers, required): New role IDs to assign (at least one)

### `delete_membership` ✅
Remove a user or group from a project.

**Parameters:**
- `membership_id` (integer, required): Membership ID to delete

---

## Groups (5 tools) ✅ FULLY IMPLEMENTED

All group management tools are fully implemented using native Redmine API. Requires admin privileges.

### `list_groups` ✅
List all groups from Redmine. Groups are used to organize users and manage permissions.

**Parameters:**
- None (returns all groups)

### `get_group` ✅
Get detailed information about a specific group including members.

**Parameters:**
- `group_id` (integer, required): Group ID to retrieve
- `include` (string, optional): Related data (users, memberships)

### `create_group` ✅
Create a new group in Redmine. Can optionally add initial members.

**Parameters:**
- `name` (string, required): Group name
- `user_ids` (array of integers, optional): Array of user IDs to add as initial members
- `custom_field_values` (object, optional): Custom field values

### `update_group` ✅
Update an existing group including name and membership.

**Parameters:**
- `group_id` (integer, required): Group ID to update
- `name` (string, optional): New group name
- `user_ids` (array of integers, optional): Complete list of user IDs (replaces current members)

### `delete_group` ✅
Delete a group. Group memberships and permissions will be removed.

**Parameters:**
- `group_id` (integer, required): Group ID to delete

---

## News (2 tools) ⏳ SKELETON

### `list_news` ⏳
List news items.

### `get_news` ⏳
Get details of a specific news item.

---

## Reference Data (7 tools) ⏳ SKELETON

Read-only tools for retrieving Redmine configuration data.

### `list_trackers` ⏳
List all trackers (Bug, Feature, Support, etc.).

### `list_issue_statuses` ⏳
List all issue statuses (New, In Progress, Resolved, etc.).

### `list_issue_priorities` ⏳
List all issue priorities (Low, Normal, High, Urgent).

### `list_time_entry_activities` ⏳
List all time entry activities (Development, Design, Testing, etc.).

### `list_custom_fields` ⏳
List all custom fields.

### `list_roles` ⏳
List all roles (Manager, Developer, Reporter, etc.).

### `search` ⏳
Perform a global search across Redmine.

---

## Summary

| Category | Implemented | Skeleton | Total |
|----------|-------------|----------|-------|
| Projects | 5 | 0 | 5 |
| Issues | 13 | 0 | 13 |
| Users | 5 | 0 | 5 |
| Time Entries | 6 | 0 | 6 |
| Custom Fields | 4 | 0 | 4 |
| Versions | 5 | 0 | 5 |
| Wiki | 0 | 6 | 6 |
| Attachments | 0 | 3 | 3 |
| Memberships | 5 | 0 | 5 |
| Groups | 5 | 0 | 5 |
| News | 0 | 2 | 2 |
| Reference | 0 | 7 | 7 |
| **TOTAL** | **48** | **21** | **69** |

---

## Implementation Priority

Recommended order for implementing remaining skeleton tools:

1. **Reference Data** (7 tools) - Read-only, simple to implement
2. **Wiki** (6 tools) - Documentation management
3. **Attachments** (3 tools) - File management
4. **News** (2 tools) - News/announcements

**Completed:**
- ✅ **Projects** (5 tools) - Project management
- ✅ **Versions** (5 tools) - Milestone/release management
- ✅ **Memberships** (5 tools) - Project access control
- ✅ **Issues** (13 tools) - Issue tracking and management
- ✅ **Users** (5 tools) - User account management
- ✅ **Groups** (5 tools) - User group management
- ✅ **Time Entries** (6 tools) - Time tracking including bulk operations
- ✅ **Custom Fields** (4 tools) - Custom field definition and management

---

## Development Guide

To implement a skeleton tool:

1. Open the tool file in `lib/tools/{category}/{tool_name}.rb`
2. Replace `raise NotImplementedError` in the `execute` method with actual implementation
3. Use `redmine_client.get/post/put/delete` to call Redmine API
4. Handle errors appropriately (they're caught by `BaseTool#call`)
5. Return the result data (don't wrap in success/error - that's automatic)
6. Test the tool manually before committing

**Example:**

```ruby
def execute(params)
  validate_required_params(params, :id)

  response = redmine_client.get("/issues/#{params[:id]}")
  response['issue'] || response
end
```

For more details, see the implemented Project tools in `lib/tools/projects/` for reference.

## Testing Guide

All tools have comprehensive RSpec test coverage. Tests verify:
- Tool metadata (name, description, input_schema)
- Successful operations with minimum and optional parameters
- Required parameter validation
- Error handling (authentication, authorization, validation, not found)

### Running Tests

**Run all tests:**
```bash
bundle exec rspec
```

**Run specific tool category tests:**
```bash
bundle exec rspec spec/tools/time_entries/
bundle exec rspec spec/tools/custom_fields/
```

**Run individual tool tests:**
```bash
bundle exec rspec spec/tools/time_entries/create_time_entry_spec.rb
```

### Test Coverage

Current test coverage:
- **Projects**: 6 tools, ~60 tests
- **Issues**: 13 tools, ~130 tests
- **Users**: 5 tools, ~50 tests
- **Groups**: 5 tools, ~50 tests
- **Time Entries**: 6 tools, ~55 tests
- **Custom Fields**: 4 tools, ~38 tests

**Total**: 93 tests for Time Entries and Custom Fields, 300+ tests overall

### Writing Tests

When implementing new tools, follow the existing test patterns:

1. **Test structure**: `#name`, `#description`, `#input_schema`, `#call`
2. **Use WebMock** for API stubbing
3. **Test success cases** with minimum and full parameters
4. **Test error cases**: missing params, validation, auth, not found
5. **Verify tool responses** include `:success` and `:data` keys

**Example test structure:**
```ruby
RSpec.describe RedmineMcpServer::Tools::ToolNameTool do
  let(:tool) { described_class.new }
  let(:base_url) { RedmineMcpServer.config[:redmine_url] }

  describe '#call' do
    context 'with valid parameters' do
      it 'performs the operation successfully' do
        stub_request(:post, "#{base_url}/endpoint.json")
          .to_return(status: 201, body: { data: 'value' }.to_json)

        result = tool.call({ param: 'value' })
        expect(result[:success]).to be true
      end
    end
  end
end
```
