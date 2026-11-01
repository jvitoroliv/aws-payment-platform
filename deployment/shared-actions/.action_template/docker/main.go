package main

import (
	"log"
	"os"
)

func main() {
	inputVariable := os.Getenv("APP_INPUT_VARIABLE")
	if inputVariable == "" {
		log.Fatal("INPUT_SECRETS environment variable is not set.")
	}
}
