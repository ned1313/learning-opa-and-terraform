# learning-opa-and-terraform

A Tutorial on Using Open Policy Agent with Terraform

## Watch me WIP

This is a work in progress (WIP) and as such is not in any way complete. If you're watching this repository, just know that I am working on building out a tutorial for using OPA, Rego, and Terraform along with a series of YouTube videos on [my channel](https://youtube.com/@NedintheCloud). As each video is published, the supporting code will land here.

## Watch me Nae nae?

No not really. I don't know how to nae nae. I do know something about building a tutorial. So watch me toot toot? No, that's worse.

## Summary

Open Policy Agent (OPA) is a graduated CNCF project used to define and evaluate policy as code written in Rego. Since OPA is a general purpose solution, it can evaulate anything that can be expressed using JSON. How does this fit into the world of Terraform? When you generate an execution plan in Terraform, the plan can be expressed as JSON using the `terraform show` command. The execution plan includes the current state data, the proposed changes to resources and outputs, and the interpreted configuration with variable values submitted during the planning run. Based on the contents of the execution plan, you can determine through policy whether the plan should proceed as expressed, and any additional actions that are necessary from an operational standpoint.

That's it. That's the summary.

## Planning

Here's the plan for learning about OPA and Terraform:

1. Describe how OPA and Terraform can work together (see summary)
1. Go over the basics of the Rego language
1. Review the contents of a Terraform execution plan
1. Develop basic policies using Rego with an execution plan
1. Implement evaluation as part of a pipeline
  1. GitHub Actions
  1. Azure DevOps
  1. Terraform Cloud
1. Create reusable OPA policies for Terraform
1. Win Win Win
  1. All I do ☝️

I may add more components or revise the order as we go, but I think this is a good start.
