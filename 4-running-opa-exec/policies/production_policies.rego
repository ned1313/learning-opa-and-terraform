package production

import data.terraform.plan_functions
import data.terraform.tag_validation
import input.resource_changes

# Required tags for all resources
required_tags := {"environment","project","owner"}

# Change maximums
max_additions := 10
max_deletions := 10
max_modifications := 10

# Get different resource change types
# Get all creates
resources_added := plan_functions.get_resources_by_action("create", resource_changes)

# Get all deletes
resources_removed := plan_functions.get_resources_by_action("delete", resource_changes)

# Get all modifies
resource_changed := plan_functions.get_resources_by_action("update", resource_changes)

# Check to see if there are too many changes
warn[msg] {
    count(resources_added) > max_additions
    msg := sprintf("Too many resources added. Only %d resources can be added at a time.", [max_additions])
}

deny[msg] {
    count(resources_removed) > max_deletions
    msg := sprintf("Too many resources deleted. Only %d resources can be added at a time.", [max_deletions])
}

warn[msg] {
    count(resource_changed) > max_modifications
    msg := sprintf("Too many resources updated. Only %d resources can be added at a time.", [max_modifications])
}

# Check to see if there are Virtual networks missing tags
vnets := plan_functions.get_resources_by_type("azurerm_virtual_network", resource_changes)

tags_contain_required(resource_checks) = resources {
    resources := [ resource | 
      resource := resource_checks[_]
      not (tag_validation.missingTags(resource, required_tags))
    ]
}

deny[msg] {
    resources := tags_contain_required(vnets)
    resources != []
    msg := sprintf("The following resources are missing required tags: %s", [resources[_].address])
}