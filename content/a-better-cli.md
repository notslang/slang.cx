# Toward a Better CLI

This paper attempts to take a critical look at the state of command-line tools and how we might improve them.

## About Me

I suspect that I have a slightly different view on the role that CLIs should play, so I'll start by explaining how I do my computing.

Over the last half-decade I've moved from graphical interfaces to using the terminal for the majority of my work. I see the command line as a much more powerful interface for anything that involves ad-hoc manipulation of data. This includes everything from searching & moving files to managing processes to statistical analysis.

However, I do not use it for general-purpose programming or web-browsing. In both of these cases I find fully graphical applications to be better suited to the task. Firefox tends to be better at rendering articles than a line-mode browser like w3m, Atom offers a more flexible interface than vim, and the functionality of VLC is something that simply doesn't belong in a terminal. These choices necessitate that I use a window manger, and for that I chose i3 simply because I can control everything with the keyboard.

## The Good Parts

Next, I'll elaborate on why I think that the CLI is more powerful (and more useful) than a GUI.

### Pipes

Composability is the ability to combine small tools to accomplish a larger task. This principle is at the heart of the UNIX philosophy and is probably the thing that is most lacking from graphical tools. For example, if I wanted to count how many headers I have in this document, I could combine 3 commands: `cat content/a-better-cli.md | grep "^#" | wc -l`. The first command, `cat`, outputs the file. The `grep` command prints only the lines that begin with `#` (a header in Markdown). And the final command `wc -l` counts how many lines `grep` printed. With composability, and the pipe (`|`) syntax that enables it, there's no need for a dedicated Markdown header-counting tool because one can be assembled on the fly.

### Streams

Streaming data is an extremely elegant solution to asynchronous data access. Long-running tasks can output their results in pieces as they run. Programs can operate on small chunks of data at a time, meaning the total amount of data can far exceed the available memory on the system. And whether a task is synchronous or not doesn't matter because it is still handled as a stream.

## The Bad Parts

The following are the flaws I see in using a CLI.

### Unstructured Data / Newline duality

While plain-text streams are fantastic as an underlying data structure, they leave a lot to be desired when you're working with data that is fundamentally structured in nature. For example, a directory listing is made up of tabular data:

```bash
$ ls -l
total 48
-rw-r--r-- 1 slang users   228 Apr 24 05:34 app.coffee
drwxr-xr-x 1 slang users    76 Apr 24 05:34 assets
-rw-r--r-- 1 slang users 35122 Apr 24 05:34 LICENSE
-rw-r--r-- 1 slang users   199 Apr 24 05:34 README.md
```

In a more structured notation like JSON, the above listing could be expressed as:

```json
[
  {
    "file": "app.coffee",
    "modifyTime": "Apr 24 05:34",
    "size": 228,
    "groupId": "users",
    "userId": "slang",
    "links": 1,
    "permissions": "-rw-r--r--"
  },
  {
    "file": "assets",
    "modifyTime": "Apr 24 05:34",
    "size": 76,
    "groupId": "users",
    "userId": "slang",
    "links": 1,
    "permissions": "drwxr-xr-x"
  },
  {
    "file": "LICENSE",
    "modifyTime": "Apr 24 05:34",
    "size": 35122,
    "groupId": "users",
    "userId": "slang",
    "links": 1,
    "permissions": "-rw-r--r--"
  },
  {
    "file": "README.md",
    "modifyTime": "Apr 24 05:34",
    "size": 199,
    "groupId": "users",
    "userId": "slang",
    "links": 1,
    "permissions": "-rw-r--r--"
  }
]
```

### User Input

### Rigid Row/Column Output

### Separation of Style & Content

but I also see some rather large flaws.
