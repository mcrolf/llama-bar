"""Write an OpenCode config listing every model installed in Ollama.

Usage: generate_config.py <ollama_url> <output_path> [default_model]
The default model is OLLAMA_MODEL from .env; when it is not installed the
template's model, then the first installed model, is used instead. Falls back to the static opencode.json template when Ollama is unreachable.
"""
import json
import sys
import urllib.request
from pathlib import Path

TEMPLATE = Path(__file__).with_name("opencode.json")


def installed_models(ollama_url):
    with urllib.request.urlopen(f"{ollama_url}/api/tags", timeout=3) as response:
        return sorted(model["name"] for model in json.load(response)["models"])


def build_config(template, ollama_url, models, default_model=""):
    provider = template["provider"]["ollama"]
    provider["options"]["baseURL"] = f"{ollama_url}/v1"
    provider["models"] = {name: {"name": name} for name in models}
    template["model"] = f"ollama/{choose_default_model(template, models, default_model)}"
    return template


def choose_default_model(template, models, default_model):
    candidates = [default_model, template["model"].removeprefix("ollama/")]
    return next((name for name in candidates if name in models), models[0])


def main(ollama_url, output_path, default_model=""):
    template = json.loads(TEMPLATE.read_text())
    try:
        models = installed_models(ollama_url)
    except OSError:
        models = []
    config = build_config(template, ollama_url, models, default_model) if models else template
    Path(output_path).write_text(json.dumps(config, indent=2) + "\n")


if __name__ == "__main__":
    main(*sys.argv[1:4])
