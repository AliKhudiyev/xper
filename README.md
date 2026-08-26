# xper -- eXPERiment tracking and management tool for terminal

```bash
$ xper init
$ xper new --scratch --tag hello
 # v1_bob node has been created
$ echo "print('hello')" >> hello.py
$ xper backup
 # pushed everything to the v1_bob remote node

$ xper update
 # pulled everything from remote node
$ xper goto v1_bob
 # v1_bob is the active node
$ xper new --tag hello_bye
 # v1_bob.1_bob node has been created with the copy of v1_bob data
$ echo "print('bye')" >> hello.py
$ xper backup
```

## TODO

- ~Fix `xper new` and make options work~
- Remove `lock` and `unlock`; use `finish` and `modify` properly instead
- Add intuitive `git` command execution wrapper
- ~Bug fix: need to `git add` and `git commit` before sensitive `xper ...` operations~
- Write tests
