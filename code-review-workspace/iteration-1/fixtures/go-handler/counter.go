package main

import (
	"encoding/json"
	"io"
	"net/http"
	"os/exec"
	"strings"
)

var counter int

type PingRequest struct {
	Host string `json:"host"`
}

func pingHandler(w http.ResponseWriter, r *http.Request) {
	body, _ := io.ReadAll(r.Body)
	var req PingRequest
	json.Unmarshal(body, &req)

	out, err := exec.Command("sh", "-c", "ping -c 1 "+req.Host).Output()
	if err != nil {
		http.Error(w, err.Error(), 500)
		return
	}
	w.Write(out)
}

func incrementHandler(w http.ResponseWriter, r *http.Request) {
	counter = counter + 1
	w.Write([]byte(strings.Repeat("x", counter)))
}

func profileHandler(w http.ResponseWriter, r *http.Request) {
	name := r.URL.Query().Get("name")
	html := "<html><body>Hello, " + name + "</body></html>"
	w.Header().Set("Content-Type", "text/html")
	w.Write([]byte(html))
}

func main() {
	http.HandleFunc("/ping", pingHandler)
	http.HandleFunc("/increment", incrementHandler)
	http.HandleFunc("/profile", profileHandler)
	http.ListenAndServe(":8080", nil)
}
