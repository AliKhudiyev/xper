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

- ~Fix `xper new` and make options work.~
- ~Remove `lock` and `unlock`; use `finish` and `modify` properly instead~
- Add intuitive `git` command execution wrapper.
- ~Bug fix: need to `git add` and `git commit` before sensitive `xper ...` operations.~
- ~Add `xper sort [--by <log-field>]` command.~
- Write tests.
- Add `--acquire|--release` semantics to `update|backup` functions.
    - `xper backup --acquire` can b edone only on a newly created branch (ie, no diff with its parent), and it must be done by the owner initially. This makes the owner to acquire the key automatically upon the creation of the new branch.
        - Make `xper new --acquire` run `xper backup --acquire` semantics behind the scenes. Maybe get rid of `--acquire` semantics for `xper backup`.
    - `xper backup` can be done by person holding the key, and this operation will not release they key from the key holder.
    `xper backup --release` can be done by person holding they key, and this operation will take the write access away from the current key holder/user.
    - `xper update --acquire` runs `xper update` but unlocks the branch (ie, gives write access) if the key can be acquired. A key can be acquired only when the person with the key does `xper backup --release` on it before this update operation.
- `xper update` should lock the branch (ie, removes write access) whose owner doesn't match the local user, unless the branch is in sequential mode (ie, original owner has run `xper backup --release` on it).
- ~`xper new` must create `LOCALUSER_vXY` when performed on `OWNER_vXX` by branching from owner's version and giving write accesses back. `dist(XX, XY)` must be as minimum as possible. `reference(LOCALUSER_vXY)=OWNER_vXX`.~
- `xper delete` shouldn't do anything on branches not owned by the local user.
- Test and fix `--global` and `--user` options for all (sub)commands.
- ~Implement `xper sort --only-leaf` that keeps only leaf nodes in the index file after sorting. A node `vXY` is leaf iff there doesn't exist a node `vXYZ` for any `Z`.~
    - ~Implement `xper index [-c|--clear]` to clear index file completely.~
    - ~Implement `xper index [-a|--add] [<version>]]` to add the version (current version by default) to the index file.~
    - ~Implement `xper index [-rm|--remove] [<version>]]` to remove the version from the index file.~
    - ~Implement `xper index <vXX> [--after|--before|--swap <vXY>] to reorder the index file entries `vXX` and `vXY` accordingly.~

