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

## TODO - v1

- ~Fix `xper new` and make options work.~
- ~Remove `lock` and `unlock`; use `finish` and `modify` properly instead~
- Add intuitive `git` command execution wrapper.
- ~Bug fix: need to `git add` and `git commit` before sensitive `xper ...` operations.~
- ~Add `xper sort [--by <log-field>]` command.~
- Write tests.
- ~[no need; they are different functionality] Add `--acquire|--release` semantics to `update|backup` functions.~
    - ~[no need] `xper backup --acquire` can be done only on a newly created branch (ie, no diff with its parent), and it must be done by the owner initially. This makes the owner to acquire the key automatically upon the creation of the new branch.~
        - ~Make `xper new --acquire` run `xper backup --acquire` semantics behind the scenes. Maybe get rid of `--acquire` semantics for `xper backup`.~
            - ~`xper new --sequential` creates a new sequential version. Optional `--acquire` option immediately runs `xper acquire` after `xper new --sequential`. `--acquire` option in `xper new` (sub)command won't do anything without the `--sequential` flag present.~
    - ~`xper backup` can be done by person holding the key, and this operation will not release they key from the key holder. `xper backup --release` can be done by person holding they key, and this operation will take the write access away from the current key holder/user.~
        - ~`xper release` works only in "sequential" mode; it releases the key and locks the version. get rid of `xper backup --release`.~
    - ~`xper update --acquire` runs `xper update` but unlocks the branch (ie, gives write access) if the key can be acquired. A key can be acquired only when the person with the key does `xper backup --release` on it before this update operation.~
        - ~`xper acquire` runs only in "sequential" mode; it attempts to acquire the key, and if it gets the key (status of ctx:locked and git push with new ctx:locked=1) then the version is unlocked. get rid of `exper update --acquire` option.~
- ~`xper update` should lock the branch (ie, removes write access) whose owner doesn't match the local user, unless the branch is in sequential mode (ie, original owner has run `xper backup --release` on it).~
- ~`xper new` must create `LOCALUSER_vXY` when performed on `OWNER_vXX` by branching from owner's version and giving write accesses back. `dist(XX, XY)` must be as minimum as possible. `reference(LOCALUSER_vXY)=OWNER_vXX`.~
- ~`xper delete` shouldn't do anything on branches not owned by the local user.~
- ~Test and fix `--global` and `--user` options for all (sub)commands.~
- ~Implement `xper sort --only-leaf` that keeps only leaf nodes in the index file after sorting. A node `vXY` is leaf iff there doesn't exist a node `vXYZ` for any `Z`.~
    - ~Implement `xper index [-c|--clear]` to clear index file completely.~
    - ~Implement `xper index [-a|--add] [<version>]]` to add the version (current version by default) to the index file.~
    - ~Implement `xper index [-rm|--remove] [<version>]]` to remove the version from the index file.~
    - ~Implement `xper index <vXX> [--after|--before|--swap <vXY>] to reorder the index file entries `vXX` and `vXY` accordingly.~

## TODO - v2
- Add `xper gitify` and `xperify` commands to convett an xper repo to git repo and an already existing git repo to an xper repo.
- Webify xper repo by
    - Showing reference counts
    - Searching for similar experiments based on references.
    - Counting linear version increments based on the time of version creation (as opposed to version ancestry).
        - `xper sort [-ct|-mt] [sort-options]` for sorting based on the creation/modification timestamps.
        - `xper jump [-ct|-mt] [jump-options]` executes `xper sort [-ct|-mt]` first, then `xper jump [jump-options]`.
            - In fact, `xper jump [-s|sort-options] [jump-options]` always run `xper sort [sort-options]` first (if index file doesn't exist of `-s` flag is present), and then `xper jump [jump-options]`.
        - [no need; `sort -ct` kinda does this] `xper sort -ref` to sort based on true references.
- Add `xper broadcast <file> --to <vXX**>` to broadcast a file to (1) vXX only -- `<vXX>`, or (2) vXXY for all Y -- `<vXX*>`, or (3) vXXY...Z for all Y...Z -- `<vXX**>`.
- Add `xper run <script> --version <vXX**> --workers <n>` to run script in implied versions accordingly (similar to `xper broadcast <file> --to <vXX**>`) with up to `n` workers at a time.

