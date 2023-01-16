# Learning the Basics of Rego

The policy language used by OPA is Rego (pronounced ray-go). For this section of the tutorial we are going to learn some of the basics of using Rego by interacting with a set of JSON data provided by the file [taco_truck.json](./taco_truck.json). 

For me, the best way to learn a new language is through immediate feedback, so we are going to set up the equivalent of a OPA sandbox to do our testing. You are going to need the OPA interactive command line to do this. It's called REPL which stands for read-evaluate-print loop. Installing OPA is as simple as downloading the latest [release from their GitHub page](https://github.com/open-policy-agent/opa/releases).

Once you've downloaded the OPA binary, put it somewhere that's included in your path file and you're ready to go!

## Running REPL

Assuming everything is installed properly, you should be able to drop into REPL by running the following:

```bash
opa run
```

*Output*

```bash
OPA 0.48.0 (commit 572e5c7ea0ed118900382908e7f1b68e1e665c04, built at 2023-01-09T16:07:13Z)

Run 'help' to see a list of commands and check for updates.
```

Excellent. Now we just need to feed in some data and start messing around with Rego language. To do that, we'll briefly exit REPL and go back in including our data file as part of the command (this assumes you're already in the directory with the `taco_truck.json` file):

```bash
exit

opa run taco_truck.json
```

The data stored in the `taco_truck.json` file has been load into the interactive shell, and we can view what data is loaded using the `data` command from REPL. Here's an example of the command with output:

```bash
$> data

{
  "menu": {
    "drinks": [
      "soda",
      "milk",
      "water"
    ],
    "entrees": [
      {
        "cheese": "jack",
        "filling": "chicken",
        "type": "taco"
      },
      ...
# Output truncated
```

You can use dot notation to explore the data that has been loaded. Try some of the following commands to view the results.

```bash
# View the contents of the menu
data.menu

# View the drinks
data.menu.drinks

# Select the first drink in the list
data.menu.drinks[0]
```

If you've worked with `jq` in the past or any other data structure that uses dot-notation, this should feel familiar. But there is some syntax you'll find that is new. Let's start by introducing the `import` keyword. Referring to an established path in the data document is going to get old fast, instead we can create a shortand by importing a specific path with a shortname:

```bash
> import data.menu.drinks

> drinks

[
  "soda",
  "milk",
  "water"
]
```

By default, the `import` statement will use the end of the path as the shorthand name, but you can also specify as name with the `as` keyword like this:

```bash
> import data.menu.entrees as meals

> meals
[
  {
    "cheese": "jack",
    "filling": "chicken",
    "type": "taco"
  },
...
# Output truncated
```

Now we probably want to do some data transformation, let's start by simply defining a variable assigment:

```bash
> first_drink := drinks[0]
Rule 'first_drink' defined in package repl. Type 'show' to see rules.

> first_drink
"soda"
```

Wait, what? We just created a rule? In the parlance of Rego, yes we did. To grasp why, let's take a moment to talk about the data document model used by OPA.

OPA maintains two data document types: base and virtual. The base document is the static data loaded into OPA from external sources, for instance our `taco_truck.json` file is part of the base document. The virtual document is the result of the rules defined in the Rego you write, which may use information from the base document as part of the evaluation. The two documents are combined together into a single `data` document we can access in the REPL session.

When we added the statement `first_drink := drinks[0]` to our REPL session, it added a rule to our current package (`repl`) and evaluated the results and stored them in the virtual data document. We can see the current rules by running the `show` command:

```bash
> show

package repl

import data.menu.drinks
import data.menu.entrees as meals

first_drink := drinks[0]
```

Well, would you look at that? It's not just the rule we created, but also the package we're working in `repl` and the import statements we added as well.

You can view the contents of both the base and virtual documents by simply entering `data`:

```bash
> data

{
  "menu": {
    "drinks": [
      "soda",
      "milk",
      "water"
    ],
    "entrees": [
      {
        "cheese": "jack",
        "filling": "chicken",
        "type": "taco"
      },
      {
        "cheese": "cheddar",
        "filling": "beef",
        "type": "taco"
      }...
      # Output truncated
  },
  "repl": {
    "first_drink": "soda"
  }
}
```

The combined document has both our base document and the virtual document, with a key for our package name (`repl`). Inside the package name is the evaluation of our `first_drink` rule.

There is another document called the `input` document that we aren't quite ready to deal with, so let's stick with the data document and the rules we can write.

Our first rule wasn't very useful, so let's construct something a little more sophisticated. What if we want a list of all entrees that have chicken in them?

```bash
chicken_dishes[dishes] {

        dishes := meals[_]

        dishes.filling == "chicken"
}
```

Allow me to break this down. The first line `chicken[dishes] {` defines a rule that we want to evaluate called `chicken_dishes` with an argument called `dishes`. Inside the rule we set our argument to be the list of all meals- remember we set meals to `data.menu.entrees`- and then we filter dishes to only include those with `filling` equal to chicken. You can test the logic directly in the REPL session by running the following:

```bash
> meals[_].filling == "chicken"
+-------------------------------+
| meals[_].filling == "chicken" |
+-------------------------------+
| true                          |
| true                          |
+-------------------------------+
```

## Rules

## Packages

## Input

