# engine.py – motore principale
# Idiota-style: questa funzione riceve un nome cognome o azienda
# costruisce le query, le passa allo scraper e ritorna i risultati

from scraper import run_query

def run_engine(input_name: str, language: str = "it"):
    return run_query(input_name, language)
