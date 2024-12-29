package main

import (
	"fmt"
	"net/http"

	"github.com/hbollon/go-edlib"
)

func helloHandler(w http.ResponseWriter, r *http.Request) {
	fmt.Fprintln(w, "hello world")
}

func main() {
	res, err := edlib.StringsSimilarity("string1", "string2", edlib.Levenshtein)
	if err != nil {
		fmt.Println(err)
	} else {
		fmt.Printf("Similarity: %f", res)
	}

	http.HandleFunc("/hello", helloHandler)
	http.ListenAndServe(":9001", nil)
}
