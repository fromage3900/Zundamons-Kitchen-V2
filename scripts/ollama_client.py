#!/usr/bin/env python3
"""
Ollama API Client — Zundamon's Kitchen V2 Content Generation Workers

Provides a reusable client for sending structured prompts to Ollama's REST API.
Used by the recipe, quest, and dialogue workers to generate Lua-formatted content
in the style of the existing project, using Zundamon as a persona template.

Usage:
    from ollama_client import OllamaClient
    client = OllamaClient(model="deepseek-coder:6.7b")
    response = client.generate(prompt, system_prompt)
"""

import json
import os
import re
import time
from typing import Optional, Dict, Any, List, Tuple

# ─── Configuration ───────────────────────────────────────────────────────────

OLLAMA_HOST = os.environ.get("OLLAMA_HOST", "http://localhost:11434")
DEFAULT_TIMEOUT = 120  # seconds

# Model recommendations per task type
MODEL_PRESETS = {
    "code": "deepseek-coder:6.7b",        # Structured Lua output
    "creative": "llama3.1:8b",            # Dialogue, narrative
    "dialogue": "gemma4:12b",             # Character-consistent speech
    "fast": "qwen2.5-coder:1.5b-base",    # Quick generation, lower quality
    "quality": "deepseek-r1:14b",         # Highest quality, slower
}

# ─── Zundamon Persona Template ───────────────────────────────────────────────
# Used as a style reference for all generated content.
# Zundamon is an enthusiastic, all-caps, pea-themed companion spirit.

ZUNDAMON_PERSONA = """
Zundamon is a pea-spirit companion from the Zundamon downloads.
Personality traits:
- Extremely enthusiastic, speaks in ALL CAPS with exclamation marks!!!
- Pea-themed metaphors and food-related wordplay
- Supportive and encouraging to the player
- Uses emojis frequently (🫛🍡✨🔥🌸)
- Speaks directly to the player by name with ~ and -san
- References cooking, ingredients, and kitchen life constantly
- Gets excited about everything, especially Zunda-themed things
- Sometimes breaks the fourth wall with playful asides

Dialogue style examples:
- "YOU'RE SO CLOSE I CAN TASTE IT!!! 🫛✨"
- "THE KITCHEN ITSELF WILL RECOGNIZE YOU!!! 🔥🔥🔥"
- "10 PERFECT COOKS!!! DO YOU HAVE ANY IDEA WHAT THAT MEANS?!?!"
- "GO GO GO!!! 🍡🔥"
- "Literally. I ate a pea. But STILL. COOK ALL THE THINGS 🍡🔥"

Recipe naming style:
- Thematic, often companion-specific ("Ankomon's Protein Punch")
- Zunda-themed with dramatic flair ("Zunda Paradise", "Zundamon's Banquet")
- Seasonal references ("Seasonal Salad", "Warm Winter Stew")
- Descriptive and evocative ("Golden Harvest Platter", "Blossom Bites")

Quest naming style:
- Dramatic and over-the-top ("The Great Zunda Hunt", "Culinary Ascension")
- Thematic chains ("Seasons of Flavor", "Friend of All")
- Companion-specific challenges ("Ankomon's Trial of Protein")
- Uses emojis as icons (🫛🍡✨🌸💪)
"""


class OllamaClient:
    """Client for communicating with Ollama's REST API."""

    def __init__(self, model: str = "deepseek-coder:6.7b", host: str = OLLAMA_HOST):
        self.model = model
        self.host = host
        self.api_url = f"{host}/api/generate"
        self._session = None

    def _ensure_session(self):
        """Lazy-import requests to avoid hard dependency at import time."""
        if self._session is None:
            import requests
            self._session = requests.Session()
        return self._session

    def is_available(self) -> bool:
        """Check if Ollama server is reachable."""
        try:
            session = self._ensure_session()
            resp = session.get(f"{self.host}/api/tags", timeout=5)
            return resp.status_code == 200
        except Exception:
            return False

    def list_models(self) -> List[str]:
        """List available models on the Ollama server."""
        try:
            session = self._ensure_session()
            resp = session.get(f"{self.host}/api/tags", timeout=10)
            data = resp.json()
            return [m["name"] for m in data.get("models", [])]
        except Exception:
            return []

    def generate(
        self,
        prompt: str,
        system_prompt: str = "",
        temperature: float = 0.7,
        max_tokens: int = 4000,
        retries: int = 3,
    ) -> str:
        """
        Send a generation request to Ollama.

        Args:
            prompt: The user prompt
            system_prompt: System instructions
            temperature: Creativity (0.0-1.0)
            max_tokens: Maximum output tokens
            retries: Number of retry attempts on failure

        Returns:
            The generated text response
        """
        full_prompt = system_prompt
        if system_prompt:
            full_prompt += "\n\n"
        full_prompt += prompt

        payload = {
            "model": self.model,
            "prompt": full_prompt,
            "stream": False,
            "options": {
                "temperature": temperature,
                "num_predict": max_tokens,
            },
        }

        for attempt in range(retries):
            try:
                session = self._ensure_session()
                resp = session.post(self.api_url, json=payload, timeout=DEFAULT_TIMEOUT)
                resp.raise_for_status()
                data = resp.json()
                return data.get("response", "")
            except Exception as e:
                if attempt < retries - 1:
                    time.sleep(2 ** attempt)  # Exponential backoff
                    continue
                raise RuntimeError(f"Ollama generation failed after {retries} attempts: {e}")

        return ""

    def generate_json(
        self,
        prompt: str,
        system_prompt: str = "",
        temperature: float = 0.5,
        max_tokens: int = 4000,
    ) -> Dict[str, Any]:
        """
        Generate and parse a JSON response from Ollama.
        Extracts JSON from markdown code blocks if present.
        """
        response = self.generate(prompt, system_prompt, temperature, max_tokens)
        return self._extract_json(response)

    @staticmethod
    def _extract_json(text: str) -> Dict[str, Any]:
        """Extract JSON from a response that may contain markdown formatting."""
        # Try to find JSON in code blocks
        json_match = re.search(r'```(?:json|lua)?\n(.*?)```', text, re.DOTALL)
        if json_match:
            json_str = json_match.group(1).strip()
        else:
            json_str = text.strip()

        try:
            return json.loads(json_str)
        except json.JSONDecodeError:
            # Try to find any JSON object in the text
            brace_start = text.find('{')
            brace_end = text.rfind('}')
            if brace_start >= 0 and brace_end > brace_start:
                try:
                    return json.loads(text[brace_start:brace_end + 1])
                except json.JSONDecodeError:
                    pass
            return {}


class LuaFormatter:
    """Utilities for formatting Lua code output from Ollama."""

    @staticmethod
    def clean_lua_response(text: str) -> str:
        """Clean up LLM output to produce valid Lua code."""
        # Remove markdown code fences
        text = re.sub(r'```(?:lua)?\n', '', text)
        text = re.sub(r'```\n?', '', text)

        # Remove leading/trailing whitespace
        text = text.strip()

        # Remove any "Here is the Lua code:" type prefixes
        text = re.sub(r'^(?:Here is|Here\'s|The following|Output:)\s*(?:the\s+)?(?:Lua\s+)?(?:code)?\s*[:\-]?\s*\n', '', text, flags=re.IGNORECASE)

        return text

    @staticmethod
    def extract_lua_table(text: str, table_name: str) -> str:
        """Extract a specific Lua table from LLM output."""
        # Look for the table definition
        pattern = rf'(local\s+{table_name}\s*=|return\s*)\s*\(\s*\)?\s*\{{'
        match = re.search(pattern, text)
        if match:
            start = match.start()
            # Find the matching closing brace
            depth = 0
            end = start
            for i, char in enumerate(text[start:], start):
                if char == '{':
                    depth += 1
                elif char == '}':
                    depth -= 1
                    if depth == 0:
                        end = i + 1
                        break
            return text[start:end]
        return text

    @staticmethod
    def validate_lua_syntax(lua_code: str) -> Tuple[bool, str]:
        """Basic Lua syntax validation (checks brace/bracket matching)."""
        # Check brace matching
        depth = 0
        in_string = False
        string_char = None
        in_comment = False

        for i, char in enumerate(lua_code):
            if in_comment:
                if char == '\n':
                    in_comment = False
                continue

            if in_string:
                if char == string_char and (i == 0 or lua_code[i-1] != '\\'):
                    in_string = False
                continue

            if char == '-' and i + 1 < len(lua_code) and lua_code[i + 1] == '-':
                in_comment = True
                continue

            if char in ('"', "'"):
                in_string = True
                string_char = char
                continue

            if char == '{':
                depth += 1
            elif char == '}':
                depth -= 1
                if depth < 0:
                    return False, "Unmatched closing brace"

        if depth != 0:
            return False, f"Unmatched braces (depth: {depth})"

        return True, "OK"


def create_worker(worker_type: str, model: str = None) -> OllamaClient:
    """
    Factory function to create a client with the recommended model for a task type.

    Args:
        worker_type: One of 'code', 'creative', 'dialogue', 'fast', 'quality'
        model: Override model name

    Returns:
        Configured OllamaClient instance
    """
    if model:
        return OllamaClient(model=model)
    return OllamaClient(model=MODEL_PRESETS.get(worker_type, "deepseek-coder:6.7b"))


if __name__ == "__main__":
    # Quick self-test
    client = OllamaClient()
    print(f"Ollama host: {client.host}")
    print(f"Model: {client.model}")

    if client.is_available():
        models = client.list_models()
        print(f"Available models: {models}")
        print("✓ Ollama is reachable!")
    else:
        print("✗ Ollama is not reachable. Start it with: ollama serve")
