# Task 2 Report — Add and lock the repository-local Graphify tool

Date: August 7, 2026

Status: DONE_WITH_CONCERNS

Commit: `eb02a538d44fa245c31bb467ac75e16a0142a0b4` (`build: add locked graphify tool`)

## Scope completed

Implemented the Task 2 repository-local Graphify setup and shared scope policy without starting Task 3 or generating graph output.

Committed files:

- `.graphifyignore`
- `tools/graphify/pyproject.toml`
- `tools/graphify/uv.lock`
- `tools/graphify/Test-GraphifyConfig.ps1`

## RED: failing configuration test

Test file created first:

- `tools/graphify/Test-GraphifyConfig.ps1`

Command:

```powershell
& 'C:\Users\ayrto\projects\akaunting\tools\graphify\Test-GraphifyConfig.ps1'
```

Exit code: `1`

Output:

```text
Exception: C:\Users\ayrto\projects\akaunting\tools\graphify\Test-GraphifyConfig.ps1:8
Line |
   8 |      throw "Missing Graphify project file: $projectPath"
     |      ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     | Missing Graphify project file: C:\Users\ayrto\projects\akaunting\tools\graphify\pyproject.toml
```

This was the expected failure before the configuration existed.

## GREEN: implementation and verification

### 1) Lock the project

Because this shell had a stale PATH, I used the installed `uv.exe` directly.

Command:

```powershell
& 'C:\Users\ayrto\AppData\Local\Microsoft\WinGet\Packages\astral-sh.uv_Microsoft.Winget.Source_8wekyb3d8bbwe\uv.exe' lock --project 'C:\Users\ayrto\projects\akaunting\tools\graphify'
```

Exit code: `0`

Output:

```text
Using CPython 3.12.10 interpreter at: C:\Users\ayrto\AppData\Local\Programs\Python\Python312\python.exe
Resolved 34 packages in 673ms
```

### 2) Verify the locked Graphify version

Initial run:

```powershell
& 'C:\Users\ayrto\AppData\Local\Microsoft\WinGet\Packages\astral-sh.uv_Microsoft.Winget.Source_8wekyb3d8bbwe\uv.exe' run --project 'C:\Users\ayrto\projects\akaunting\tools\graphify' --locked graphify --version
```

Exit code: `0`

Output:

```text
Using CPython 3.12.10 interpreter at: C:\Users\ayrto\AppData\Local\Programs\Python\Python312\python.exe
Creating virtual environment at: tools\graphify\.venv
Downloading networkx (2.0MiB)
Downloading graphifyy (1.2MiB)
Downloading rapidfuzz (1.5MiB)
Downloading numpy (11.9MiB)
 Downloaded rapidfuzz
 Downloaded graphifyy
 Downloaded networkx
 Downloaded numpy
Installed 30 packages in 3.90s
graphify 0.9.34
```

### 3) First configuration test after implementation

Command:

```powershell
& 'C:\Users\ayrto\projects\akaunting\tools\graphify\Test-GraphifyConfig.ps1'
```

Exit code: `1`

Output:

```text
Exception: C:\Users\ayrto\projects\akaunting\tools\graphify\Test-GraphifyConfig.ps1:27
Line |
  27 |          throw "Graphify project config is missing required content ma …
     |          ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     | Graphify project config is missing required content matching: (?m)^\s*"graphifyy==0\.9\.34"\s*$
```

Resolution:

- Updated `tools/graphify/pyproject.toml` to keep the dependency as the minimal single-entry array form required by the test:
  - `"graphifyy==0.9.34"`

### 4) Final fresh verification

Command:

```powershell
& 'C:\Users\ayrto\AppData\Local\Microsoft\WinGet\Packages\astral-sh.uv_Microsoft.Winget.Source_8wekyb3d8bbwe\uv.exe' run --project 'C:\Users\ayrto\projects\akaunting\tools\graphify' --locked graphify --version
```

Exit code: `0`

Output:

```text
graphify 0.9.34
```

Command:

```powershell
& 'C:\Users\ayrto\projects\akaunting\tools\graphify\Test-GraphifyConfig.ps1'
```

Exit code: `0`

Output:

```text
Graphify configuration is valid.
```

Additional pre-commit verification:

Command:

```powershell
git diff --check -- .graphifyignore tools/graphify/pyproject.toml tools/graphify/uv.lock tools/graphify/Test-GraphifyConfig.ps1
```

Exit code: `0`

Output: no diff-check errors

Fresh pre-commit verification:

```powershell
& 'C:\Users\ayrto\AppData\Local\Microsoft\WinGet\Packages\astral-sh.uv_Microsoft.Winget.Source_8wekyb3d8bbwe\uv.exe' run --project 'C:\Users\ayrto\projects\akaunting\tools\graphify' --locked graphify --version
& 'C:\Users\ayrto\projects\akaunting\tools\graphify\Test-GraphifyConfig.ps1'
git diff --cached --check
```

Outputs:

```text
graphify 0.9.34
Graphify configuration is valid.
```

`git diff --cached --check` returned exit code `0` with no output.

## Self-review

- Verified the four committed files match the task brief exactly.
- Verified the ignore policy is an allow-list with `*` plus directory and descendant negations for:
  - `app/`
  - `modules/`
  - `config/`
  - `routes/`
  - `tests/`
- Verified the locked project resolves and runs Graphify `0.9.34`.
- Verified no Task 3 files were created and no graph output was generated.

## Commit

Command:

```powershell
git commit -m "build: add locked graphify tool"
```

Output:

```text
[chore/graphify-setup eb02a538d] build: add locked graphify tool
 4 files changed, 876 insertions(+)
 create mode 100644 .graphifyignore
 create mode 100644 tools/graphify/Test-GraphifyConfig.ps1
 create mode 100644 tools/graphify/pyproject.toml
 create mode 100644 tools/graphify/uv.lock
```

## Concerns

1. This Codex shell did not have fresh PATH entries for `python` or `uv`, so I had to use the installed absolute executable paths from Task 1’s host installation.
2. The first `uv run` created `tools/graphify/.venv` locally. It is ignored by Git and was not included in the commit, but the environment blocked deleting it from this session.

---

## Fix round — August 7, 2026

Changed file:

- `tools/graphify/Test-GraphifyConfig.ps1`

Fix commit SHA:

- `8f8900ba18492c0ad3f543faed8242c6dc970712` (`test: enforce exact graphify ignore policy sequence`)

### Regression coverage check

Test name:

- Exact normalized `.graphifyignore` sequence enforcement

Command:

```powershell
$ErrorActionPreference = 'Stop'
$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('graphify-review-repro-' + [guid]::NewGuid().ToString())
$null = New-Item -ItemType Directory -Path (Join-Path $tempRoot 'tools/graphify') -Force
Copy-Item 'C:/Users/ayrto/projects/akaunting/tools/graphify/Test-GraphifyConfig.ps1' (Join-Path $tempRoot 'tools/graphify/Test-GraphifyConfig.ps1')
Copy-Item 'C:/Users/ayrto/projects/akaunting/tools/graphify/pyproject.toml' (Join-Path $tempRoot 'tools/graphify/pyproject.toml')
Set-Content -LiteralPath (Join-Path $tempRoot '.graphifyignore') -NoNewline -Value @'
!app/
*
!app/**
!modules/
!modules/**
!config/
!config/**
!routes/
!routes/**
!tests/
!tests/**
!database/**
'@
& (Join-Path $tempRoot 'tools/graphify/Test-GraphifyConfig.ps1')
```

Exit code: `1`

Complete output:

```text
Exception: C:\Users\ayrto\AppData\Local\Temp\graphify-review-repro-c582c743-d161-47c5-a1b7-bbac146850b8\tools\graphify\Test-GraphifyConfig.ps1:49
Line |
  49 |      throw @"
     |      ~~~~~~~~
     | Graphify ignore policy must exactly match the normalized allow-list. Expected: * !app/ !app/** !modules/ !modules/** !config/ !config/** !routes/ !routes/** !tests/ !tests/** Actual: !app/ * !app/** !modules/ !modules/** !config/ !config/** !routes/ !routes/** !tests/ !tests/** !database/**
```

### Repository configuration test

Test name:

- Graphify configuration validation

Command:

```powershell
& 'C:/Users/ayrto/projects/akaunting/tools/graphify/Test-GraphifyConfig.ps1'
```

Exit code: `0`

Complete output:

```text
Graphify configuration is valid.
```

### Locked version check

Test name:

- Locked Graphify version

Command:

```powershell
& 'C:/Users/ayrto/AppData/Local/Microsoft/WinGet/Packages/astral-sh.uv_Microsoft.Winget.Source_8wekyb3d8bbwe/uv.exe' run --project 'C:/Users/ayrto/projects/akaunting/tools/graphify' --locked graphify --version
```

Exit code: `0`

Complete output:

```text
graphify 0.9.34
```

### Concerns

1. This Codex shell still required invoking `uv.exe` by absolute path because `uv` was not available on PATH.
2. The regression check uses a temporary repro tree under `%TEMP%`; it is diagnostic only and does not change repository files or generated output.
