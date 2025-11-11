package main

import (
	"log"
	"net/http"
	"os"
)

func main() {
	notesPath := os.Getenv("NOTES_PATH")
	if notesPath == "" {
		notesPath = "./notatki.txt"
	}

	logoPath := "./logo.txt"

	mux := http.NewServeMux()
	mux.HandleFunc("/notes", func(w http.ResponseWriter, r *http.Request) {
		logo, _ := os.ReadFile(logoPath)
		notes, err := os.ReadFile(notesPath)
		if err != nil {
			http.Error(w, "cannot read notatki.txt", http.StatusInternalServerError)
			return
		}

		w.Header().Set("Content-Type", "text/plain; charset=utf-8")
		w.WriteHeader(http.StatusOK)
		w.Write(logo)
		w.Write([]byte("\n--------------------\n"))
		w.Write(notes)
	})

	log.Println("listening on :8040")
	log.Fatal(http.ListenAndServe(":8040", mux))
}
