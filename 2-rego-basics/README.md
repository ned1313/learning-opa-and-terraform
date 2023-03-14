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

If you've worked with `jq` in the past or any other data structure that uses dot-notation, this should feel familiar. But there is some new syntax to learn as well.

Let's start by introducing the `import` keyword. Referring to an established path in the data document is going to get old fast, instead we can create a shorthand by importing a specific path with a shorter name:

```bash
> import data.menu.drinks

> drinks

[
  "soda",
  "milk",
  "water"
]
```

> Quick note about packages: When we launched REPL, we implicitly started a Rego module. Modules define a package they're part of. This give you the ability to define and import packages for other Rego modules to use. When we started REPL we didn't declare a package name, so once we added a statement to our module (using the `import` keyword), REPL created a package called `repl`, which we can see by running the `show` command.

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

We can see the `import` statement and any other statements in the module by running the `show` command:

```bash
> show

package repl

import data.menu.drinks
import data.menu.entrees as meals
```

Next let's do a little data transformation by adding more statements to our package. First we'll do a simple variable assignment:

```bash
> first_drink := drinks[0]
Rule 'first_drink' defined in package repl. Type 'show' to see rules.

> first_drink
"soda"
```

Wait, what? We just created a rule? In the parlance of Rego, yes we did. Within our package, there is now a statement that says `first_drink := drinks[0]`.

What does it mean to be a rule? And where is the result stored? This is an excellent moment to differentiate between the various data document types in OPA.

OPA maintains two data document types: base and virtual. The base document is the static data loaded into OPA from external sources, for instance our `taco_truck.json` file is part of the base document. The virtual document is the result of the rules defined in the Rego you write, which may use information from the base document as part of the evaluation. The two documents are combined together into a single `data` document we can access in the REPL session.

When we added the statement `first_drink := drinks[0]` to our module, it added a rule to our current package (`repl`) and evaluated the results and stored them in the virtual data document. We can see the current rules by running the `show` command:

```bash
> show

package repl

import data.menu.drinks
import data.menu.entrees as meals

first_drink := drinks[0]
```

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

Allow me to break this down. We are defining a variable called `chicken_dishes` that contains `dishes` only where `dishes` is the list of meals and the `filling` value of `dishes` is equal to `"chicken"`.

Rego has introduced some new keywords that help us better understand what is going on. If you import the package `future.keywords`, you can construct the equivalent of the above rule like this:

```rego
chicken_dishes contains dishes {
        some dishes in meals
        dishes.filling == "chicken"
}
```

At least I think it makes things a bit clearer, YMMV. Our variable `chicken_dishes` contains the values in `dishes` where `dishes` is a value in `meals` and the `filling` value of `dishes` is equal to `"chicken"`.

In the parlance of Rego, the `chicken_dishes contains dishes if` portion is the rule *head* and the rest is the rule *body*. This is actually a partial rule as it does not evaluate to true or false. We can construct a complete rule like this:

```rego
have_chicken_dishes := count(chicken_dishes) > 0
```

Checking on the value of `have_chicken_dishes`:

```bash
> have_chicken_dishes
true
```

The value stored is `true`. Now we have a basic understanding of some of the syntax of Rego, how to construct expressions and rules, and how to do so in an interactive environment. If you're looking for a complete reference on the syntax, keywords, and built-in functions of Rego, check out the [Rego Reference](https://www.openpolicyagent.org/docs/latest/policy-language/).

In the next lesson, we are going to construct a Rego package in a file and load it into OPA, and we'll start working with an actual Terraform JSON-formatted execution plan instead of our lil' taco truck.
