import os
import json
import asyncio
from dotenv import load_dotenv
from google import genai
from google.genai import types

load_dotenv()

client = genai.Client(api_key=os.getenv("GOOGLE_API_KEY"))
MODEL = "gemini-2.5-flash-lite"

# Precomputed once at import time — no overhead per request
CATEGORY_ICONS = {
    "music": "🎵", "film": "🎬", "fashion": "👗",
    "dining": "🍽️", "hidden_gem": "💎"
}
DEFAULT_TIMES = ["09:00", "11:30", "13:00", "14:30", "16:30", "19:00"]

def generate_maps_link(location: str, city: str) -> str:
    return f"https://www.google.com/maps/search/{location.replace(' ', '+')}+{city.replace(' ', '+')}"

def build_activity(act: dict, i: int, city: str) -> dict:
    """Pure CPU — build enriched activity dict from parsed LLM output."""
    location = act.get("location") or "Unknown"
    return {
        "time": act.get("time") or (DEFAULT_TIMES[i] if i < len(DEFAULT_TIMES) else "09:00"),
        "location": {
            "name": location,
            "maps_link": generate_maps_link(location, city),
            "address": f"{location}, {city}",
        },
        "category": act.get("category", "general"),
        "description": act.get("description", ""),
        "cultural_connection": act.get("cultural_connection", ""),
        "category_icon": CATEGORY_ICONS.get(act.get("category", ""), "📍"),
    }

PROMPT_TEMPLATE = """\
Analyze: "{user_input}"

1. Extract: destination, days, music, film, fashion taste.
   Defaults if missing: Tokyo, 2 days, BTS, Spirited Away, Uniqlo.
2. Plan exactly 6 activities per day at: 09:00 11:30 13:00 14:30 16:30 19:00.

Return ONLY valid JSON — no markdown, no explanation:
{{
  "destination": "City",
  "duration": 2,
  "days": [
    {{
      "day": 1,
      "theme": "Creative theme",
      "activities": [
        {{
          "time": "09:00",
          "location": "Venue name",
          "category": "hidden_gem",
          "description": "What to do",
          "cultural_connection": "Why it fits the taste"
        }}
      ]
    }}
  ]
}}"""

async def generate_itinerary_response(user_input: str) -> dict:
    prompt = PROMPT_TEMPLATE.format(user_input=user_input)

    try:
        response = await client.aio.models.generate_content(
            model=MODEL,
            contents=prompt,
            config=types.GenerateContentConfig(
                response_mime_type="application/json",
                temperature=0.0,  # deterministic = fastest sampling
                # Disable thinking budget — Flash-Lite doesn't need it for JSON
                thinking_config=types.ThinkingConfig(thinking_budget=0),
            ),
        )

        raw = response.text
        # Strip accidental markdown fences defensively
        if raw.startswith("```"):
            raw = raw.split("\n", 1)[1].rsplit("```", 1)[0]

        itinerary = json.loads(raw)
        return _build_response(itinerary)

    except json.JSONDecodeError as e:
        return {"error": f"JSON parse failed: {e}", "raw": response.text if "response" in dir() else ""}
    except Exception as e:
        return {"error": str(e)}


def _build_response(itinerary: dict) -> dict:
    """Synchronous CPU work — runs immediately after parse, no await needed."""
    city = itinerary.get("destination", "Tokyo")
    duration = itinerary.get("duration", 1)

    days = [
        {
            "day_number": day.get("day", i + 1),
            "theme": day.get("theme", "Cultural Day"),
            "activities": [
                build_activity(act, j, city)
                for j, act in enumerate(day.get("activities", []))
            ],
        }
        for i, day in enumerate(itinerary.get("days", []))
    ]

    return {
        "status": "success",
        "travel_plan": {
            "destination": city,
            "duration_days": duration,
            "summary": f"{duration}-day cultural itinerary for {city}",
            "travel_image": f"https://picsum.photos/seed/{city}/1200/800",
            "days": days,
        },
    }