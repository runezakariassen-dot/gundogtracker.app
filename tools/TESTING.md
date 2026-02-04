# Testing notes

## Recommended commands (run without `sudo`)

- Fast smoke run: `./tool/test_fast.sh`
- Full suite: `./tool/test_all.sh`
- Slow-only suites: `flutter test --tags slow`

The scripts call `flutter test` with the same flags as the previously documented commands so they do not trigger `flutter precache` or other SDK downloads, and they all run from the repo root.

## Diagnosing the Flutter SDK permissions problem

If you hit an error like:

```
/Users/<user>/development/flutter/bin/internal/update_engine_version.sh: line 64: /Users/<user>/development/flutter/bin/cache/engine.stamp: Operation not permitted
```

then Flutter is unable to update `engine.stamp` because the SDK directory is not writable by the current user. The following commands help diagnose the situation:

```bash
flutter --version
which flutter
ls -ld "$(dirname "$(which flutter)")/.."    # the Flutter SDK root
```

For example, on this machine:

```
flutter --version
Flutter 3.38.5 • channel stable • https://github.com/flutter/flutter.git
Framework • revision f6ff1529fd (12 days ago) • 2025-12-11 11:50:07 -0500
Engine • hash c108a94d7a8273e112339e6c6833daa06e723a54 (revision 1527ae0ec5) (12 days ago) • 2025-12-11 15:04:31.000Z
Tools • Dart 3.10.4 • DevTools 2.51.1

which flutter
/Users/runezakariassen/development/flutter/bin/flutter

ls -ld /Users/runezakariassen/development/flutter
drwxr-xr-x@ 36 runezakariassen  staff  1152 Dec 19 20:42 /Users/runezakariassen/development/flutter
```

If the SDK root is owned by `root` or another user, the commands above will reveal that. Even if the owner matches your user, extended attributes (such as `com.apple.provenance`) or immutable flags can keep `flutter` from writing to `engine.stamp`.

## Fix strategy

1. **Install/relocate Flutter to a user-writable path.**  
   Download or move the SDK to something like `~/dev/flutter` and ensure `ls -ld` shows your user owns the directory.

2. **Update your shell PATH.**  
   Add the new SDK’s `bin/` directory to `PATH` (e.g. via `~/.zshrc` or `~/.bash_profile`) so `which flutter` points to the writable copy.

3. **If necessary, fix ownership.**  
   Run `chown -R "$(whoami)" /path/to/flutter` if the directory is already on a writable volume but still owned by another user. Avoid `sudo flutter test`; instead fix the filesystem state.

4. **Clear problematic extended attributes (macOS).**  
   If `xattr /path/to/flutter/bin/cache/engine.stamp` lists `com.apple.provenance` or similar, remove it with `xattr -d <attribute> <file>` so the file can be updated.

Once the SDK root is both writable and owned by you, the `./tool/test_fast.sh` run should succeed without requiring elevated permissions.

## macOS: engine.stamp – read-only cache + provenance

If the SDK root is already owned by you but `flutter test` still prints:

```
/Users/.../engine.stamp: Operation not permitted
```

then the Flutter cache files themselves are read-only (typically `444`) and keep macOS from updating `bin/cache/engine.stamp`. A sample `ls -lO` output looks like:

```
-rw-r--r--@ 1 runezakariassen staff - 41 Dec 23 18:19 /Users/.../flutter/bin/cache/engine.stamp
```

The `@` shows an extended attribute such as `com.apple.provenance` that macOS stamped during download. Because the file is read-only, you must first give yourself write permission on the cache directory before you can remove the attribute.

### Fix steps

1. Grant the current user write access to the cache area:
   ```bash
   chmod -R u+w /Users/<you>/development/flutter/bin/cache
   ```

2. Remove the quarantine/provenance attributes from the same directory:
   ```bash
   xattr -dr com.apple.provenance /Users/<you>/development/flutter/bin/cache
   xattr -dr com.apple.quarantine /Users/<you>/development/flutter/bin/cache
   ```

3. Retry the fast smoke test:
   ```bash
   ./tool/test_fast.sh
   ```

After these commands, Flutter can rewrite `engine.stamp` and the preflight check in `tool/test_fast.sh` should pass without elevated permissions. The script itself does not attempt to fix permissions so you only run the commands once.
