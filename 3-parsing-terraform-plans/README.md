# Parsing and Working with Terraform Execution Plans

In the previous lesson we worked with a theoretical bit of JSON to understand the basics of Rego and OPA. Now we can starting working with a real Terraform execution plan.

## The Set Up

There is a Terraform configuration stored in this directory that will create a resource group and virtual network in Azure. I chose those resources because they don't cost any money, but they will give you real infrastructure to work with. If you plan to following along, you will need the following:

* An Azure subscription
* The Azure CLI installed
* The Terraform CLI installed
* The OPA CLI installed

You likely have most of this already. If you'd prefer to use another cloud, that's fine, but the examples will be specific to Azure.

## Generating the Execution Plan

Because OPA loves working with JSON, we need to generate an execution plan from Terraform and put it into JSON format. First we are going to run `terraform plan` saving the plan to a file, then we can use `terraform show` to convert the plan to JSON.

```bash
# Log into Azure and set the subscription
az login
az account set --subscription "Your Subscription Name"

# Initialize the Terraform configuration
terraform init

# Generate the execution plan
terraform plan -out="plan.tfplan"

# Convert the execution plan to JSON
terraform show -json "plan.tfplan" > "plan.json"
```

Now that we have an execution plan in JSON format, let's investigate the structure of the data using OPAs interactive shell.

## Exploring the Execution Plan

We will start by simply loading the data into OPA and then using the `data` command to view the contents of the data document.

```bash
# Start the interactive shell
opa run plan.json

# View the contents of the data document
data
```

I'm not going to even show the output here, because this simple execution plan to create a resource group and virtual network takes up almost 500 lines of JSON. Instead, let's talk about the major areas of the execution plan and then we can dive into the details.

We can discover the top level keys of our data by simply using a Rego expression:

```bash
# View the top level keys of the data document
data[keys]

+-----------------------+-------------------------------------------------------------------------------------+
|         keys          |                                     data[keys]                                      |
+-----------------------+-------------------------------------------------------------------------------------+
| "configuration"       | {"provider_config":{"azurerm":{"expressions":{"features":[{}]},"full_name":"regi... |
| "format_version"      | "1.1"                                                                               |
| "planned_values"      | {"root_module":{"resources":[{"address":"azurerm_resource_group.main","mode":"ma... |
| "relevant_attributes" | [{"attribute":["name"],"resource":"azurerm_resource_group.main"},{"attribute":["... |
| "resource_changes"    | [{"address":"azurerm_resource_group.main","change":{"actions":["create"],"after"... |
| "terraform_version"   | "1.3.7"                                                                             |
| "variables"           | {"common_tags":{"value":{"environment":"dev","purpose":"opa"}},"location":{"valu... |
+-----------------------+-------------------------------------------------------------------------------------+

```

The `configuration` key contains the rendered configuration in JSON format.

The `variables` key contains the variables values that were used to generate the execution plan.

The `planned_values` key contains the values that will be used to create the resources. It's essentially a merge of what is in the `configuration` key and the `variables` keys. If you want to know what's in the rendered configuration, this is the place to look.

The `resource_changes` key contains the changes that will be made to target environment. It includes resources that will be created, updated, or destroyed. If you're concerned about changes to the target environment, this is the place to look.

All the other keys aren't really important to us, but feel free to explore them if you're curious. I want to focus in on the `planned_values` and `resource_changes` keys. That's where the action is!

### Planned Values

We can dig deeper into our `planned_values` key by using the `data.planned_values` expression. The area we are most interested in for this example is the key `data.planned_values.root_module.resources`. This key contains a list of all the resources defined in our configuration with the arguments filled out.

```bash
# View the contents of the planned_values key
> data.planned_values.root_module.resources[keys]

+------+-------------------------------------------------------------------------------------+
| keys |                   data.planned_values.root_module.resources[keys]                   |
+------+-------------------------------------------------------------------------------------+
| 0    | {"address":"azurerm_resource_group.main","mode":"managed","name":"main","provide... |
| 1    | {"address":"azurerm_subnet.main[\"subnet1\"]","index":"subnet1","mode":"managed"... |
| 2    | {"address":"azurerm_subnet.main[\"subnet2\"]","index":"subnet2","mode":"managed"... |
| 3    | {"address":"azurerm_virtual_network.main","mode":"managed","name":"main","provid... |
+------+-------------------------------------------------------------------------------------+

# Inspect a single resource
> data.planned_values.root_module.resources[0]

{
  "address": "azurerm_resource_group.main",
  "mode": "managed",
  "name": "main",
  "provider_name": "registry.terraform.io/hashicorp/azurerm",
  "schema_version": 0,
  "sensitive_values": {
    "tags": {}
  },
  "type": "azurerm_resource_group",
  "values": {
    "location": "westus",
    "name": "opa-test",
    "tags": {
      "environment": "dev",
      "purpose": "opa"
    },
    "timeouts": null
  }
}
```

Within each resource we can grab the type of resource (`type`), the values that will be used (`values`), and the address of the resource (`address`). The `type` is useful if you want to narrow down the resource selection. We can pick all resource of a type, say `azurerm_subnet` with the following expression:

```bash

# Select all resources of a type
>subnets[subnet]{
 subnet := data.planned_values.root_module.resources[_]
 subnet.type = "azurerm_subnet"
}

# View the subnets
> subnets
[
  {
    "address": "azurerm_subnet.main[\"subnet1\"]",
    "index": "subnet1",
    "mode": "managed",
    "name": "main",
    "provider_name": "registry.terraform.io/hashicorp/azurerm",
    "schema_version": 0,
    "sensitive_values": {
      "address_prefixes": [
        false
      ],
      "delegation": []
    },
    "type": "azurerm_subnet",
    "values": {
      "address_prefixes": [
        "10.0.0.0/24"
      ],
      "delegation": [],
      "name": "subnet1",
      "resource_group_name": "opa-test",
      "service_endpoint_policy_ids": null,
      "service_endpoints": null,
      "timeouts": null,
      "virtual_network_name": "opa-test"
    }
  }
    # ... truncated for brevity
]
```

We'll dig more into the `planned_values` key later, but for now let's move on to the `resource_changes` key.

### Resource Changes

This is probably the key of most interest. You want to know what's changing about your environment, right? Unlike `planned_changes`, this key gets directly to the point. Each entry in the `resource_changes` key contains the address of the resource, the change that will be made, and the before and after values.

```bash

# View the contents of the resource_changes key
> data.resource_changes[keys]

+-----+-------------------------------------------------------------------------------------+
| key |                             data.resource_changes[key]                              |
+-----+-------------------------------------------------------------------------------------+
| 0   | {"address":"azurerm_resource_group.main","change":{"actions":["create"],"after":... |
| 1   | {"address":"azurerm_subnet.main[\"subnet1\"]","change":{"actions":["create"],"af... |
| 2   | {"address":"azurerm_subnet.main[\"subnet2\"]","change":{"actions":["create"],"af... |
| 3   | {"address":"azurerm_virtual_network.main","change":{"actions":["create"],"after"... |
+-----+-------------------------------------------------------------------------------------+

# Inspect a single resource
> data.resource_changes[0]

{
  "address": "azurerm_resource_group.main",
  "change": {
    "actions": [
      "create"
    ],
    "after": {
      "location": "westus",
      "name": "opa-test",
      "tags": {
        "environment": "dev",
        "purpose": "opa"
      },
      "timeouts": null
    },
    "after_sensitive": {
      "tags": {}
    },
    "after_unknown": {
      "id": true,
      "tags": {}
    },
    "before": null,
    "before_sensitive": false
  },
  "mode": "managed",
  "name": "main",
  "provider_name": "registry.terraform.io/hashicorp/azurerm",
  "type": "azurerm_resource_group"
}
```

This is awesome. We can filter on the change, the resource type, values before and values after. The world is our oyster! Why don't we filter on resource type and change type? We'll try and find all subnets that are being created.

```bash
subnets_created[subnet]{
    subnet := data.resource_changes[_]
    subnet.type = "azurerm_subnet"
    subnet.change.actions[_] = "create"
}

> subnets_created

[
  {
    "address": "azurerm_subnet.main[\"subnet1\"]",
    "change": {
      "actions": [
        "create"
      ],
      "after": {
        "address_prefixes": [
          "10.0.0.0/24"
        ],
        "delegation": [],
        "name": "subnet1",
        "resource_group_name": "opa-test",
        "service_endpoint_policy_ids": null,
        "service_endpoints": null,
        "timeouts": null,
        "virtual_network_name": "opa-test"
      },
      "after_sensitive": {
        "address_prefixes": [
          false
        ],
        "delegation": []
      },
      "after_unknown": {
        "address_prefixes": [
          false
        ],
        "delegation": [],
        "enforce_private_link_endpoint_network_policies": true,
        "enforce_private_link_service_network_policies": true,
        "id": true,
        "private_endpoint_network_policies_enabled": true,
        "private_link_service_network_policies_enabled": true
      },
      "before": null,
      "before_sensitive": false
    },
    "index": "subnet1",
    "mode": "managed",
    "name": "main",
    "provider_name": "registry.terraform.io/hashicorp/azurerm",
    "type": "azurerm_subnet"
  }
    # ... truncated for brevity
]

```

Filtering on a resource type is going to be a really common operation, so it would be nice to have a function that does it for us. And that's exactly what we'll do next.

### Functions

You can think of partial rules in Rego as functions. You feed in some information and it returns back a result. We can define a function that takes in a list of resources and a resource type and returns all resources of that type.

```bash
get_resources_by_type(resources, type) = filtered_resources {
    filtered_resources := [resource | resource := resources[_]; resource.type = type]
}
```

Then we can use that partial rule by feeding it the list of resources and the type we want to filter on.

```bash
subnets := get_resources_by_type(data.resource_changes, "azurerm_subnet")
```

Woah! That's super useful! It's almost like we could create a whole bunch of rules that deal with common Terraform attributes and then use them to filter on those attributes. What if we put those functions in a file and then imported them into our playground? That would be awesome!

And wouldn't you know it, there's already a file in this repository called `terraform_library.rego` that does exactly that.

First we need to exit our playground and start it back up, this time tagging our plan file as input and adding the library file to our data document.

```bash
opa run repl.input:"plan.json" "terraform_library.rego"

# Import the library
> import data.terraform.library

# Import the plan file as a variable
> import input as tfplan

# Now try a function in the library

> library.get_resources_by_type("azurerm_subnet")

[
  {
    "address": "azurerm_subnet.main[\"subnet1\"]",
    "change": {
      "actions": [
        "create"
      ],
      "after": {
        "address_prefixes": [
          "10.0.0.0/24"
        ],
        "delegation": [],
        "name": "subnet1",
        "resource_group_name": "opa-test",
        "service_endpoint_policy_ids": null,
        "service_endpoints": null,
        "timeouts": null,
        "virtual_network_name": "opa-test"
      },
      "after_sensitive": {
        "address_prefixes": [
          false
        ],
        "delegation": []
      },
      "after_unknown": {
        "address_prefixes": [
          false
        ],
        "delegation": [],
        "enforce_private_link_endpoint_network_policies": true,
        "enforce_private_link_service_network_policies": true,
        "id": true,
        "private_endpoint_network_policies_enabled": true,
        "private_link_service_network_policies_enabled": true
      },
      "before": null,
      "before_sensitive": false
    },
    "index": "subnet1",
    "mode": "managed",
    "name": "main",
    "provider_name": "registry.terraform.io/hashicorp/azurerm",
    "type": "azurerm_subnet"
  }
    # ... truncated for brevity
 ]
}
```

Noice. We can now use the functions in the library to filter on resource types, names, or actions. Based on these queries, we can start crafting policies on what's allowed and what we want to check for. For instance, we might want to have a test to see if there are more than five objects being deleted.

```bash
> too_many_deletes {count(library.get_resources_by_action("delete")) > 5}

> too_many_deletes

undefined
```

Note in the world of Rego, if a query returns undefined, then it is not true. It might not be false, but in this case it is.

## Summary

We now have an understanding of our Terraform plan file, how to interact with it in Rego, and how to use functions from a library to perform common actions. We can now start to craft policies that will help us enforce our security and compliance requirements. That will be the topic for the next video in the series.
