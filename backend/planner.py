import os
import json
import asyncio
import re
from dotenv import load_dotenv
from functools import lru_cache
import google.generativeai as genai

load_dotenv()

GOOGLE_API_KEY = os.getenv("GOOGLE_API_KEY")

genai.configure(api_key=GOOGLE_API_KEY)
model = genai.GenerativeModel("gemini-2.5-flash-lite")



async def gather_preferences(music, movie, fashion):
    """Return user preferences directly without external API calls"""
    return {
        "music": [music],
        "movie": [movie],
        "fashion": [fashion]
    }

def parse_user_input(user_input):
    """Extract preferences and destination from user input using AI"""
    prompt = f"""
Analyze this user input and extract travel parameters in JSON format.

User input: "{user_input}"

Extract:
1. Music preference (artist, band, or genre) - be specific about artist names
2. Movie/film preference (movie, director, genre, or franchise) - be specific about movie titles  
3. Fashion/style preference (brand, style, or fashion category) - be specific about brand names
4. Destination city
5. Number of days for the trip

Rules:
- For K-pop, extract specific artist names like "BTS", "BLACKPINK", "TWICE" etc.
- For Studio Ghibli, extract specific movie titles like "Spirited Away", "My Neighbor Totoro" etc.
- For minimalist fashion, extract specific brands like "COS", "Uniqlo", "Muji" etc.
- If destination isn't mentioned, use: "Tokyo"
- If days aren't mentioned, use: 2
- Return ONLY valid JSON in this exact format:
{{
  "music": "...",
  "movie": "...",
  "fashion": "...",
  "destination": "...",
  "days": 2
}}
"""
    try:
        response = model.generate_content(prompt, generation_config=genai.types.GenerationConfig(
            temperature=0.3,
            max_output_tokens=256
        ))
        text = response.text.strip()
        
        # Extract JSON from response
        if "```json" in text:
            text = text.split("```json")[1].split("```")[0].strip()
        elif "```" in text:
            text = text.split("```")[1].strip()
        
        data = json.loads(text)
        return (
            data.get('music', 'BTS'),
            data.get('movie', 'Spirited Away'), 
            data.get('fashion', 'Uniqlo'),
            data.get('destination', 'Tokyo'),
            int(data.get('days', 2))
        )
    except Exception as e:
        print(f"Input parsing failed: {e}")
        return "BTS", "Spirited Away", "Uniqlo", "Tokyo", 2

def build_prompt(user_input, recs, city="Tokyo", days=2):
    return f"""
User said: "{user_input}"
Plan a {days}-day cultural itinerary in {city}.

Tastes:
- Music: {', '.join(recs['music'])}
- Film: {', '.join(recs['movie'])}
- Fashion: {', '.join(recs['fashion'])}

Create exactly 6 activities per day with specific times: 09:00, 11:30, 13:00, 14:30, 16:30, 19:00

Output ONLY valid JSON in this exact format:
{{
  "itinerary": {{
    "destination": "{city}",
    "duration": {days},
    "days": [
      {{
        "day": 1,
        "theme": "Creative theme name",
        "activities": [
          {{
            "time": "09:00",
            "location": "Specific venue name",
            "category": "hidden_gem",
            "description": "Detailed description",
            "cultural_connection": "How this connects to user preferences"
          }},
          {{
            "time": "11:30",
            "location": "Another venue name",
            "category": "film",
            "description": "Another description",
            "cultural_connection": "Connection explanation"
          }},
          {{
            "time": "13:00",
            "location": "Restaurant name",
            "category": "dining",
            "description": "Dining description",
            "cultural_connection": "Cultural connection"
          }},
          {{
            "time": "14:30",
            "location": "Fashion venue",
            "category": "fashion",
            "description": "Fashion activity",
            "cultural_connection": "Fashion connection"
          }},
          {{
            "time": "16:30",
            "location": "Music venue",
            "category": "music",
            "description": "Music activity",
            "cultural_connection": "Music connection"
          }},
          {{
            "time": "19:00",
            "location": "Evening venue",
            "category": "dining",
            "description": "Evening activity",
            "cultural_connection": "Evening connection"
          }}
        ]
      }}
    ]
  }}
}}

CRITICAL: Every activity MUST have a time field with format "HH:MM". Use real venue names in {city}.
"""

def generate_maps_link(location, city):
    """Generate Google Maps search link"""
    query = f"{location}, {city}".replace(" ", "+")
    return f"https://www.google.com/maps/search/{query}"

async def generate_itinerary_response(user_input):
    music, movie, fashion, city, days = parse_user_input(user_input)
    recs = await gather_preferences(music, movie, fashion)
    prompt = build_prompt(user_input, recs, city, days)

    response = model.generate_content(prompt)
    streamed = "".join(part.text for part in response)

    json_match = re.search(r'\{[\s\S]*\}', streamed)
    if json_match:
        try:
            raw_json = json_match.group(0)
            parsed = json.loads(raw_json)
            final_response = await enrich_with_maps(parsed)
            
            print(f"\n=== FINAL RESPONSE CHECK ===")
            print(f"Cultural connections in first activity:")
            if final_response.get("travel_plan", {}).get("days"):
                first_day = final_response["travel_plan"]["days"][0]
                if first_day.get("activities"):
                    first_activity = first_day["activities"][0]
                    print(f"Connection: {first_activity.get('cultural_connection', 'None found')}")
            print("=============================\n")
            
            return final_response
        except Exception as e:
            return {"error": f"JSON parse failed: {str(e)}", "raw_response": raw_json}
    else:
        return {"error": "No valid JSON found", "raw_response": streamed[:300]}

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
        day_activities = day.get("activities", day.get("items", []))
        
        for i, act in enumerate(day_activities):
            location = act.get("location") or act.get("name", "Unknown")
            time = act.get("time")
            if not time or time == "TBD":
                time = default_times[i] if i < len(default_times) else f"{9 + i * 2}:00"
            
            # Generate simple maps link
            maps_link = generate_maps_link(location, city)
            
            activities.append({
                "time": time,
                "location": {
                    "name": location,
                    "maps_link": maps_link,
                    "address": f"{location}, {city}"
                },
                "category": act.get("category", "general"),
                "description": act.get("description", act.get("name", "")),
                "cultural_connection": act.get("cultural_connection", ""),
                "category_icon": {
                    "music": "🎵", "film": "🎬", "fashion": "👗",
                    "dining": "🍽️", "hidden_gem": "💎"
                }.get(act.get("category", ""), "📍")
            })
        response["travel_plan"]["days"].append({
            "day_number": day.get("day", 1),
            "theme": day.get("theme", "Cultural day"),
            "activities": activities
        })
    return response
