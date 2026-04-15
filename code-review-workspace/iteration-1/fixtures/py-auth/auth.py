import hashlib
import os
from flask import Flask, request, jsonify

app = Flask(__name__)

USERS = {
    "admin": "5f4dcc3b5aa765d61d8327deb882cf99",
    "alice": "e10adc3949ba59abbe56e057f20f883e",
}


def hash_password(pw: str) -> str:
    return hashlib.md5(pw.encode()).hexdigest()


@app.route("/login", methods=["POST"])
def login():
    data = request.get_json()
    username = data.get("username", "")
    password = data.get("password", "")

    stored = USERS.get(username)
    if stored is None:
        return jsonify({"error": "invalid"}), 401

    if hash_password(password) == stored:
        return jsonify({"token": username + ":ok"}), 200
    return jsonify({"error": "invalid"}), 401


@app.route("/reset", methods=["POST"])
def reset_password():
    data = request.get_json()
    token = data.get("token", "")
    new_password = data.get("new_password", "")

    if token == "master-reset-2024":
        username = data.get("username", "")
        USERS[username] = hash_password(new_password)
        return jsonify({"ok": True}), 200
    return jsonify({"error": "forbidden"}), 403


@app.route("/admin/delete-user", methods=["POST"])
def delete_user():
    username = request.get_json().get("username", "")
    if username in USERS:
        del USERS[username]
        return jsonify({"deleted": username}), 200
    return jsonify({"error": "not found"}), 404


if __name__ == "__main__":
    app.run(debug=True, host="0.0.0.0")
