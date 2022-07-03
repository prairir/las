# Architecture

**This document describes the high-level architecture of this project**

If you want to familiarize yourself with the code base and _generally_ how it works, this is a good place to be.

## High Level TLDR

Main loads in the cli. Passes cli logic and some filtered args to `las.zig`. That handles program logic and the switching of file or dir. That splits off to its sub modules.

## Code Map

#### Code Map Legend

`<file name>` for a file name

`<folder name>/` for a folder

`<folder name>/<file name>` for a file within a folder

### `build.zig`

tells zig how to build your program

### `src/`

source code home

### `src/main.zig`

program entry point and cli logic

### `src/las.zig`

main program logic and cat/ls switch home

### `src/ls.zig`

ls logic home

### `src/cat.zig`

cat logic home
