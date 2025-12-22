package main

import "fmt"

func main() {
    fmt.Println("Kitchen gRPC server starting on :50051...")
    // TODO: gRPC server setup
    select {} // Keep alive forever (No idea how this works right now)
}
