"""Run: python3 -m unittest discover -s opencode"""
import unittest

from generate_config import build_config


def a_template(model="ollama/devstral-small-2:24b"):
    return {"model": model, "provider": {"ollama": {"options": {}, "models": {}}}}


class ChooseDefaultModelTest(unittest.TestCase):
    def default_for(self, models, default_model="", template_model="ollama/devstral-small-2:24b"):
        config = build_config(a_template(template_model), "http://ollama", models, default_model)
        return config["model"]

    def test_installed_env_model_wins(self):
        self.assertEqual(self.default_for(["devstral-small-2:24b", "gpt-oss:20b"], "gpt-oss:20b"), "ollama/gpt-oss:20b")

    def test_missing_env_model_falls_back_to_template_model(self):
        self.assertEqual(self.default_for(["devstral-small-2:24b", "gpt-oss:20b"], "qwen3:8b"), "ollama/devstral-small-2:24b")

    def test_falls_back_to_first_installed_model(self):
        self.assertEqual(self.default_for(["gpt-oss:20b", "qwen3:8b"]), "ollama/gpt-oss:20b")

    def test_lists_every_installed_model(self):
        config = build_config(a_template(), "http://ollama", ["a", "b"])
        self.assertEqual(list(config["provider"]["ollama"]["models"]), ["a", "b"])
        self.assertEqual(config["provider"]["ollama"]["options"]["baseURL"], "http://ollama/v1")


if __name__ == "__main__":
    unittest.main()
