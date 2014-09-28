# Aligning Operators
If you've been coding for a sufficiently long time, you've surely come across the formatting debate between aligning operators, and surrounding them with a single space (unaligned).

Aligned looks like this:

```javascript
x      = 1;
y      = 2;
fooBar = 3;
```

While unaligned looks like this:

```javascript
x = 1;
y = 2;
fooBar = 3;
```

## Aligned
Aligned code tends to look nicer because columns of identifiers or values can be scanned without discerning where the operator is on each line. For example, if you have a list of 30-some assignments and you're looking for the places where you're assigning `null`, it's much easier if all of the values being assigned are aligned in a vertical column.

A similar practice exists in mathematics, where lists of equations are aligned by their equals sign so each half remains on one side of a vertical column:

```
x^2            = -6x - 8
x^2 + 6x       = -8
x^2 + 6x + 8   = 0
(x + 2)(x + 4) = 0
x              = -2, -4
```

Another example of where alignment is useful is multi-dimensional matrices. While these are fairly rare in practice (I couldn't even find an example of one, in a popular library, where the constants weren't already the same length), they should to be taken into account because they look bad when not aligned properly, and usually need to be edited as if they were tables:

```
# unaligned
a = [
  [0.06618, -0.49681, 311]
  [-0.4387, 0.06, 297]
  [-0.0007, -0.00073, 1]
]

# aligned
a = [
  [ 0.06618, -0.49681, 311]
  [-0.4387,   0.06,    297]
  [-0.0007,  -0.00073,   1]
]
```

## Unaligned
Sadly, alignment doesn't come without a few disadvantages.

### Complexity
Alignment requires a complex set of rules that introduce edge-cases into formatting. For example, should we apply alignment alignment unconditionally, even when it creates large gaps of whitespace?

```coffee
CoffeeScript         = require './coffee-script'
compile              = CoffeeScript.compile
CoffeeScript.require = require
```

Or should it only be applied to sections where it would require a few spaces to make it line up?

```coffee
CoffeeScript = require './coffee-script'
compile      = CoffeeScript.compile
CoffeeScript.require = require
```

Or should a line-break be introduced just to separate the aligned block and the unaligned block?

```coffee
CoffeeScript = require './coffee-script'
compile      = CoffeeScript.compile

CoffeeScript.require = require
```

And should comments be allowed in the middle of an aligned block?

```coffee
# Create the template that we will use to generate the Docco HTML page.
docco_template = template fs.readFileSync(__dirname + '/../resources/docco.jst').toString()

# The CSS styles we'd like to apply to the documentation.
docco_styles   = fs.readFileSync(__dirname + '/../resources/docco.css').toString()
```

Or should alignment only be applied to continuous blocks of code?

```coffee
# Create the template that we will use to generate the Docco HTML page.
docco_template = template fs.readFileSync(__dirname + '/../resources/docco.jst').toString()

# The CSS styles we'd like to apply to the documentation.
docco_styles = fs.readFileSync(__dirname + '/../resources/docco.css').toString()
```

And what about hash-maps, conditionals, or even class properties; should those get aligned too?

```coffee
exports.parser = new Parser
  tokens     : tokens.join ' '
  bnf        : grammar
  operators  : operators.reverse()
  startSymbol: 'Root'
```

```coffee
i = 0
while @chunk = code[i..]
  consumed = \
    @identifierToken() or
    @commentToken()    or
    @whitespaceToken() or
    @lineToken()       or
    @heredocToken()    or
    @stringToken()     or
    @numberToken()     or
    @regexToken()      or
    @jsToken()         or
    @literalToken()
```

```coffee
class Adapter
  ###*
   * The names of the npm modules that are supported to be used as engines by
     the adapter. Defaults to the name of the adapter.
   * @type {String[]}
  ###
  supportedEngines: undefined

  ###*
   * The name of the engine in-use.
   * @type {String}
  ###
  engineName      : ''

  ###*
   * The actual engine, no adapter wrapper. Defaults to the engine that we
     recommend for compiling that particular language (if it is installed).
  ###
  engine          : undefined
```

The point at which this kind of alignment stops improving readability and starts becoming a hindrance is difficult to define. To get it right, you would need a complex set of rules, capable of describing all cases where alignment should or should not be used. And even with a set of rules like that, the effects of those rules on readability cannot be quantified. Thus, attempting to create a standard for alignment in code will inevitably result in the proliferation of competing "alignment standards", based on personal preferences.

A programmer shouldn't need to spend time thinking about any of these rules, or their effects on code readability. Determining how to correctly format their code is an additional cognitive burden that distracts from more important things like ensuring that code works properly. In short: we have more important things to worry about.

### Maintenance
Editing a single line in a block of aligned statements can require all the other statements to be realigned. A programmer shouldn't need to spend time maintaining alignment as code is changed. This _can_ be automated with in-editor tools, but ensuring that those tools are used consistently, by all collaborators, is an unnecessary burden and a waste of time.

In addition, depending upon these alignment tools (especially ones that are integrated with a particular editor) can cause problems when doing mass-renames of identifiers or when using tools that a particular alignment tool isn't integrated with. This is because you would either need to manually run the tool on every file that was changed, or the tool would need to be advanced enough to watch for changed files, and run constantly in the background.

### Interaction with your VCS
Even with these tools, the fact that unrelated lines need to be changed is unintuitive - which is reflected in the diffs produced by version control systems.

For example, if we start with this block of code:

```coffee
File = require 'fobject'
W    = require 'when'
_    = require 'lodash'
```

...and for whatever reason `fobject` is removed as a dependency, we end up with:

```coffee
W    = require 'when'
_    = require 'lodash'
```

...but because of alignment, we also need to change the other 2 lines, resulting in this:

```coffee
W = require 'when'
_ = require 'lodash'
```

...now, through the removal of one line, we have caused all the lines to be changed, increasing the size of the diff, and breaking the ability to use `blame` to find where the other two lines were introduced or last modified. When these alignment changes are applied to entire projects (rather than small code snippets), it results in the history being cluttered with trivial formatting changes, making navigation and searching more difficult.

### Assumptions
Using alignment makes an assumption that many programmers may not think about. While monospace fonts are very common in programming, not everyone uses them. So, additional spaces to get operators to align vertically just shows up as useless whitespace for people who are using proportional fonts.

## A Proposal
While alignment can make code easier to read, standardizing its use, and preventing its side-effects on VCSes and code maintenance isn't possible if the alignment is hard-coded into the source.

Instead, I propose that we take an approach to alignment that is similar to the way we deal with syntax-highlighting. Rather than embed these stylistic properties into the code itself, we let the editor decide how the code should be displayed. This means that all alignment would be done programmatically, in the editor, while the source code itself would contain no alignment. The VCS would only see unaligned code, meaning that the diff for any given commit would only show lines that have functionally changed, and everyone could set their editor to use their own personal preferences for code-alignment.

Editors that aren't capable of displaying aligned code would just show the unaligned code. While this isn't ideal, it shouldn't prevent anyone from being able to edit code with editors that don't support automatic alignment because alignment is a purely stylistic enhancement.
