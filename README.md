# Llama Bar

A macOS menu bar app for running local [Ollama](https://ollama.com) models, with a
coding-agent setup built on [OpenCode](https://opencode.ai).

- **Spotlight launch:** Cmd+Space, "Llama Bar". Launching starts the Ollama server if it is down.
- **Menu bar status:** a cube that fills in and shows memory use while a model is loaded.
  Click it for server status, loaded models, and OpenCode token usage (today, 7 days, 30 days, all time).
- **Configuration Manager:** pull models from the Ollama library with progress, see installed
  models, choose the default model, load, unload, or delete models, and tune the server's
  context length and keep-alive.
- **OpenCode launcher:** `opencode-ollama` runs OpenCode with every installed Ollama model,
  in a terminal or as a provider for apps such as T3 Code.

Ollama runs natively as a LaunchAgent so it gets the Apple Silicon GPU (Docker on macOS cannot).

```
Llama Bar ──> Ollama :11434 (LaunchAgent, Metal GPU) <── opencode-ollama ──> OpenCode
```

Llama Bar is an independent project and is not affiliated with Ollama or OpenCode.

## Requirements

- macOS 15 or later, Apple Silicon recommended
- [Homebrew](https://brew.sh)
- Xcode or the Command Line Tools (`xcode-select --install`) to build the app
- No other Ollama server running: quit the Ollama desktop app, and `bin/setup` stops
  `brew services ollama`. Both would compete for port 11434.

## Install

```sh
git clone https://github.com/mcrolf/llama-bar.git
cd llama-bar
bin/setup       # installs ollama + opencode, starts the LaunchAgent, pulls the default model
bin/build-app   # builds ~/Applications/Llama Bar.app and launches it
```

The app remembers where the repo is when it is built, so keep the clone in place (or rerun
`bin/build-app` after moving it). The default model is `devstral-small-2:24b` (15 GB); to start
with a different one, copy `.env.example` to `.env` and edit it before running `bin/setup`.

## Using it

**Menu bar panel.** Shows whether Ollama is running, which models are loaded (with an eject
button to unload), and OpenCode usage from `opencode stats`: sessions, prompts, and tokens per
model. Actions: open OpenCode in iTerm or Terminal, open the Configuration Manager, restart the
Ollama server, show the server log.

**Configuration Manager.**

- *Installed Models*: size, parameters, and quantization. Right-click or use the buttons to set
  the default, load, unload, or delete.
- *Install Model*: enter any `name:tag` from [ollama.com/library](https://ollama.com/library).
- *Default Model*: the model OpenCode starts new sessions with, plus server context length and
  keep-alive. Settings are saved to `.env`; changing a server setting restarts Ollama, which
  unloads loaded models.

**OpenCode.** `bin/setup` links `opencode-ollama` into `~/.local/bin`. Run it for the OpenCode
TUI, or point an app that supports OpenCode at it as the binary path. For T3 Code: add a
provider with driver **OpenCode** and binary path `/path/to/llama-bar/bin/opencode-ollama`.
Each start lists every installed model; new models appear the next time OpenCode starts.

Models that handle tool calls well work best for agentic coding:

| Model | Size | SWE-bench Verified | Speed (M4 Max) |
|---|---|---|---|
| devstral-small-2:24b (default) | 15 GB | 68.0% (Mistral) | ~29 tok/s |
| gpt-oss:20b | 13 GB | ~60.7% (OpenAI) | ~90 tok/s |

## Configuration

`.env` (copied from `.env.example`) holds the settings the Configuration Manager edits:

| Variable | Default | Meaning |
|---|---|---|
| `OLLAMA_MODEL` | `devstral-small-2:24b` | Default model for new OpenCode sessions |
| `OLLAMA_CONTEXT_LENGTH` | `32768` | Context window; agent prompts need at least 32k |
| `OLLAMA_KEEP_ALIVE` | `30m` | How long an idle model stays in memory (`-1` keeps it loaded) |

After editing `.env` by hand, run `bin/configure-server` to apply server settings.
Server log: `~/Library/Logs/llama-bar/ollama.log`.

## Uninstall

```sh
bin/uninstall   # removes the app, the LaunchAgent, and the opencode-ollama link
```

Ollama, OpenCode, and downloaded models stay installed (`ollama rm <model>` frees disk space).

## Development

```sh
swift test --package-path app                 # app tests
python3 -m unittest discover -s opencode      # config generator tests
LLAMA_BAR_ROOT=$PWD swift run --package-path app   # run the app without bundling
```

| Path | Purpose |
|---|---|
| `app/` | SwiftUI menu bar app (Swift package) |
| `bin/setup` | Installs dependencies and pulls the default model |
| `bin/configure-server` | Renders the LaunchAgent from `.env` and restarts Ollama |
| `bin/build-app` | Builds, signs (ad hoc), and installs `Llama Bar.app` |
| `bin/opencode-ollama` | OpenCode launcher; generates its config from installed models |
| `opencode/` | OpenCode config template and generator |
| `launchd/` | LaunchAgent template for `ollama serve` |
| `compose.yaml` | Optional CPU-only Docker fallback; don't run it alongside the LaunchAgent |

## License

[MIT](LICENSE)
