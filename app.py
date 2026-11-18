import os

from flask import Flask, jsonify

app = Flask(__name__)
app.json.ensure_ascii = False
app.json.sort_keys = False

APP_TITLE = os.getenv("APP_TITLE", "Планувальник подій")
APP_VERSION = "1.0"

EVENTS = [
    {"id": 1, "title": "Лекція «Розгортання застосунків у хмарі»",
     "date": "2026-11-20", "place": "Ауд. 214"},
    {"id": 2, "title": "Лабораторна робота з Docker",
     "date": "2026-11-22", "place": "Комп'ютерний клас"},
    {"id": 3, "title": "Захист лабораторних робіт",
     "date": "2026-11-27", "place": "Ауд. 105"},
]


@app.route("/")
def require_token():
    expected = os.environ.get("ADMIN_TOKEN")
    token = request.headers.get("Authorization", "")
    if not expected or token != f"Bearer {expected}":
        return jsonify({"error": "unauthorized"}), 401
    return None

def index():
    return f"""
<h1>CI/CD Cloud App</h1>
<p>{APP_TITLE}</p>
<p>Версія застосунку розгортається автоматично.</p>
<p>CI/CD deployment version {APP_VERSION}</p>
"""


@app.route("/health")
def health():
    return jsonify({"status": "ok"}), 200


@app.route("/api/events")
def events():
    return jsonify(EVENTS)


if __name__ == "__main__":
    port = int(os.getenv("PORT", "5000"))
    app.run(host="0.0.0.0", port=port, debug=True)
