import os
import json
import re
from dotenv import load_dotenv
from google import genai

load_dotenv()

GOOGLE_API_KEY = os.getenv("GOOGLE_API_KEY")

client = genai.Client(api_key=GOOGLE_API_KEY)

MODEL = "gemini-2.5-flash-lite"


async def gather_preferences(music, movie, fashion):
    """Return user preferences safely"""

    return {
        "music": [str(music or "BTS")],
        "movie": [str(movie or "Spirited Away")],
        "fashion": [str(fashion or "Uniqlo")]
    }


async def parse_user_input(user_input):
    """Extract travel parameters from user input using Gemini"""

    prompt = f"""
Analyze this user input and extract travel parameters in JSON.

User input: "{user_input}"

Return JSON only:

{{
  "music": "...",
  "movie": "...",
  "fashion": "...",
  "destination": "...",
  "days": 2
}}
"""

    try:

        response = await client.aio.models.generate_content(
            model=MODEL,
            contents=prompt,
            config={
                "temperature": 0.3,
                "max_output_tokens": 200
            }
        )

        text = response.text.strip()

        if "```json" in text:
            text = text.split("```json")[1].split("```")[0].strip()
        elif "```" in text:
            text = text.split("```")[1].strip()

        data = json.loads(text)

        music = data.get("music") or "BTS"
        movie = data.get("movie") or "Spirited Away"
        fashion = data.get("fashion") or "Uniqlo"
        destination = data.get("destination") or "Tokyo"
        days = data.get("days") or 2

        return (
            str(music),
            str(movie),
            str(fashion),
            str(destination),
            int(days)
        )

    except Exception as e:

        print("Parsing failed:", e)

        return "BTS", "Spirited Away", "Uniqlo", "Tokyo", 2


def build_prompt(user_input, recs, city="Tokyo", days=2):

    music = ", ".join(filter(None, recs["music"]))
    movie = ", ".join(filter(None, recs["movie"]))
    fashion = ", ".join(filter(None, recs["fashion"]))

    return f"""
User said: "{user_input}"

Plan a {days}-day cultural itinerary in {city}.

User tastes:
Music: {music}
Film: {movie}
Fashion: {fashion}

Create exactly 6 activities per day.

Times:
09:00
11:30
13:00
14:30
16:30
19:00

Return ONLY valid JSON:

{{
  "itinerary": {{
    "destination": "{city}",
    "duration": {days},
    "days": [
      {{
        "day": 1,
        "theme": "Creative theme",
        "activities": [
          {{
            "time": "09:00",
            "location": "Specific venue name",
            "category": "hidden_gem",
            "description": "Description",
            "cultural_connection": "Connection to taste"
          }}
        ]
      }}
    ]
  }}
}}
"""


def generate_maps_link(location, city):
    """Create Google Maps link"""

    query = f"{location}, {city}".replace(" ", "+")
    return f"https://www.google.com/maps/search/{query}"


async def generate_itinerary_response(user_input):

    music, movie, fashion, city, days = await parse_user_input(user_input)

    recs = await gather_preferences(music, movie, fashion)

    prompt = build_prompt(user_input, recs, city, days)

    response = await client.aio.models.generate_content(
        model=MODEL,
        contents=prompt
    )

    streamed = response.text

    json_match = re.search(r"\{[\s\S]*\}", streamed)

    if json_match:

        try:

            raw_json = json_match.group(0)

            parsed = json.loads(raw_json)

            final_response = await enrich_with_maps(parsed)

            return final_response

        except Exception as e:

            return {
                "error": f"JSON parse failed: {str(e)}",
                "raw_response": raw_json
            }

    else:

        return {
            "error": "No valid JSON detected",
            "raw_response": streamed[:300]
        }


async def enrich_with_maps(parsed_data):

    itinerary = parsed_data.get("itinerary", {})

    city = itinerary.get("destination", "Tokyo")

    duration = itinerary.get("duration", 1)

    image_url = f"https://picsum.photos/seed/{city}/1200/800"

    response = {
        "status": "success",
        "travel_plan": {
            "destination": city,
            "duration_days": duration,
            "summary": f"{duration}-day cultural itinerary for {city}",
            "travel_image": image_url,
            "days": []
        }
    }

    default_times = ["09:00", "11:30", "13:00", "14:30", "16:30", "19:00"]

    for day in itinerary.get("days", []):

        activities = []

        for i, act in enumerate(day.get("activities", [])):

            location = act.get("location") or "Unknown"

            time = act.get("time")

            if not time:
                time = default_times[i] if i < len(default_times) else "09:00"

            maps_link = generate_maps_link(location, city)

            activities.append({
                "time": time,
                "location": {
                    "name": location,
                    "maps_link": maps_link,
                    "address": f"{location}, {city}"
                },
                "category": act.get("category", "general"),
                "description": act.get("description", ""),
                "cultural_connection": act.get("cultural_connection", ""),
                "category_icon": {
                    "music": "🎵",
                    "film": "🎬",
                    "fashion": "👗",
                    "dining": "🍽️",
                    "hidden_gem": "💎"
                }.get(act.get("category", ""), "📍")
            })

        response["travel_plan"]["days"].append({
            "day_number": day.get("day", 1),
            "theme": day.get("theme", "Cultural Day"),
            "activities": activities
        })

    return response