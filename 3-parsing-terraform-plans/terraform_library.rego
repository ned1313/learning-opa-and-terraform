package terraform.library

# TFPLAN should be the terraform execution plan file in JSON format
# You can create it with the following command: terraform show -json plan_file_name > plan.json

import input as tfplan
import future.keywords
import input.resource_changes as resources

# Get resources by type
get_resources_by_type(type) = filtered_resources {
    filtered_resources := [resource | resource := resources[_]; resource.type = type]
}

# Get resources by action
get_resources_by_action(action) = filtered_resources {
    filtered_resources := [resource | resource := resources[_]; resource.change.actions[_] = action]
}

# Get resources by type and action
get_resources_by_type_and_action(type, action) = filtered_resources {
    filtered_resources := [resource | resource := resources[_]; resource.type = type; resource.change.actions[_] = action]
}

# Get resource by name
get_resource_by_name(resource_name) = filtered_resources {
    filtered_resources := [resource | resource := resources[_]; resource.name = resource_name]
}

# Get resource by type and name
get_resource_by_type_and_name(type, resource_name) = filtered_resources {
    filtered_resources := [resource | resource := resources[_]; resource.type = type; resource.name = resource_name]
}
