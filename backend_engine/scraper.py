# scraper.py – esegue le ricerche Google REALTIME usando Bing API (o successive API)
# Idiota-style: qui ci sarà il vero motore web-on

import requests

def run_query(input_name: str, language: str):
    # Placeholder: restituisce risultati finti
    # Quando passiamo allo STEP 3 qui mettiamo la ricerca vera
    return {
        "input": input_name,
        "language": language,
        "results": [
            {"title": "Fake result 1", "url": "https://example.com"},
            {"title": "Fake result 2", "url": "https://example.com"},
        ]
    }
