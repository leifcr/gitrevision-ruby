# Gitrevision-ruby

Helps you set the version number in source files, e.g. a header file or similar

## Usage

```
$ ruby gitrevision.rb --input version.hx --output version.h --folder /path/to/git/repo

$ ruby gitrevision.rb --input version.hx
```

### Options

*input*: Required filename/path to file
*output*: Optional filename/path to file. If omitted, the input extension must have a appended x. e.g. _version.h_ becoms _version.hx_
*folder*: Optional path to the git folder, if it's not provided, the current folder is used

## Example

Given this header file and tag v1.5.3, and 12 commits after the last tag

```c
//version.hx
#ifndef _VERSION_H_
#define _VERSION_H_

#define GIT_MAJOR_VERSION $GIT_MAJOR_VERSION$
#define GIT_MINOR_VERSION $GIT_MINOR_VERSION$
#define GIT_REVISION $GIT_REVISION$
#define GIT_SHORT_HASH "$GIT_SHORT_HASH$"
#define GIT_LONG_HASH "$GIT_LONG_HASH$"
#define GIT_COMMITS_SINCE_TAG $GIT_COMMITS_SINCE_TAG$

#endif // _VERSION_H_
```

The result will be

```c
//version.h

#ifndef _VERSION_H_
#define _VERSION_H_

#define GIT_MAJOR_VERSION 1
#define GIT_MINOR_VERSION 5
#define GIT_REVISION 3
#define GIT_SHORT_HASH ecb1148b8b
#define GIT_LONG_HASH ecb1148b8bae8ed2ca57aed9088f26f0348cf2cd
#define GIT_COMMITS_SINCE_TAG 12

#endif // _VERSION_H_
```

## License

Licensed under the MIT license
