package main

import (
	"fmt"
	"io"
	"net/http"
	"os"
	"os/exec"
	"strconv"
	// "strings" // Removed unused import
	// "syscall" // syscall not used currently
)

// Path to the Bash handler script
const bashHandlerPath = "/app/handler_bhg.bash" // Adjusted path for the modified handler

func main() {
	port := "8081" // Default port
	// setLimits() // setLimits is not implemented/used

	// Simple command-line argument parsing for port
	args := os.Args[1:]
	// Override port if first argument is provided
	 if len(args) > 0 {
	 	// Basic check if it looks like a port number
	 	_, err := strconv.Atoi(args[0])
	 	// If it's a number, use it as port. Ignore error checking for simplicity here.
	 	// A more robust solution would use the flag package.
	 	 if err == nil { // Check if conversion was successful
	 	 	port = args[0]
	 	 }
	 }

	listenAddr := ":" + port
	fmt.Printf("INFO: BHG (Go) listening on %s\n", listenAddr)

	// Use a handler that explicitly passes the bash path
	server := &http.Server{
		Addr: listenAddr,
		Handler: http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			 handleRequestWithScript(w, r, bashHandlerPath)
		}),
	}

	// Start the server
	 err := server.ListenAndServe()
	 if err != nil {
		fmt.Fprintf(os.Stderr, "ERROR: Failed to start server: %v\n", err)
		 os.Exit(1)
	 }
}

// handleRequestWithScript handles the HTTP request by executing a bash script
func handleRequestWithScript(w http.ResponseWriter, r *http.Request, scriptPath string) {
	// Prepare environment variables for the Bash script
	cmdEnv := os.Environ() // Inherit current environment
	cmdEnv = append(cmdEnv, fmt.Sprintf("REQUEST_METHOD=%s", r.Method))
	cmdEnv = append(cmdEnv, fmt.Sprintf("REQUEST_URI=%s", r.RequestURI))
	cmdEnv = append(cmdEnv, fmt.Sprintf("QUERY_STRING=%s", r.URL.RawQuery))
	cmdEnv = append(cmdEnv, fmt.Sprintf("REMOTE_ADDR=%s", r.RemoteAddr))
	cmdEnv = append(cmdEnv, fmt.Sprintf("HTTP_HOST=%s", r.Host))
	cmdEnv = append(cmdEnv, fmt.Sprintf("HTTP_USER_AGENT=%s", r.UserAgent()))
	cmdEnv = append(cmdEnv, fmt.Sprintf("HTTP_CONTENT_TYPE=%s", r.Header.Get("Content-Type")))
	cmdEnv = append(cmdEnv, fmt.Sprintf("HTTP_CONTENT_LENGTH=%d", r.ContentLength))

	// Add other relevant headers as HTTP_HEADER_NAME (simplified)
	// Example: Add Accept header if needed by Bash script
	// cmdEnv = append(cmdEnv, fmt.Sprintf("HTTP_ACCEPT=%s", r.Header.Get("Accept")))

	// Prepare the command to execute the Bash script
	cmd := exec.Command("bash", scriptPath)
	cmd.Env = cmdEnv

	// Pipe the request body to the script's stdin
	stdin, errPipe := cmd.StdinPipe()
	 if errPipe != nil {
		fmt.Fprintf(os.Stderr, "ERROR: Failed to get stdin pipe: %v\n", errPipe)
		 http.Error(w, "Internal Server Error", http.StatusInternalServerError)
		 return
	 }
	 go func() {
		defer stdin.Close()
		_, errCopy := io.Copy(stdin, r.Body)
		 if errCopy != nil {
			// Log error, but don't crash the server
			fmt.Fprintf(os.Stderr, "ERROR: Failed to copy request body to stdin: %v\n", errCopy)
		 }
	 }()

	// Capture the script's stdout (which should be the full HTTP response)
	outputBytes, errExec := cmd.Output()

	// Check for execution errors
	 if errExec != nil {
		fmt.Fprintf(os.Stderr, "ERROR: Failed to execute bash script ", scriptPath, ": %v\n", errExec)
		// If using CombinedOutput, log stderr:
		// if exitErr, ok := errExec.(*exec.ExitError); ok {
		// 	 fmt.Fprintf(os.Stderr, "ERROR: Bash script stderr: %s\n", string(exitErr.Stderr))
		// }
		 http.Error(w, "Internal Server Error", http.StatusInternalServerError)
		 return
	 }

	// --- Write raw output using Hijack --- 
	// This is necessary because the Bash script is expected to output the *entire* HTTP response,
	// including status line and headers, which Go's standard ResponseWriter interferes with.

hijacker, ok := w.(http.Hijacker)
if !ok {
	fmt.Fprintf(os.Stderr, "ERROR: Hijacking not supported\n")
	 http.Error(w, "Internal Server Error", http.StatusInternalServerError)
	 return
}
conn, bufrw, errHijack := hijacker.Hijack()
if errHijack != nil {
	fmt.Fprintf(os.Stderr, "ERROR: Cannot hijack connection: %v\n", errHijack)
	 http.Error(w, "Internal Server Error", http.StatusInternalServerError)
	 return
}
defer conn.Close()

// Write the raw output from Bash directly to the connection
_, errWrite := bufrw.Write(outputBytes)
if errWrite != nil {
	fmt.Fprintf(os.Stderr, "ERROR: Failed to write raw response: %v\n", errWrite)
	 return // Connection will be closed by defer
}
errFlush := bufrw.Flush()
if errFlush != nil {
	fmt.Fprintf(os.Stderr, "ERROR: Failed to flush raw response: %v\n", errFlush)
	 return // Connection will be closed by defer
}

}

// // Helper function to set resource limits (commented out as unused)
// func setLimits() {
// 	 // var rLimit syscall.Rlimit // Removed to avoid unused warning
// 	 // Example: Set max open files (adjust value as needed)
// 	 // err := syscall.Getrlimit(syscall.RLIMIT_NOFILE, &rLimit)
// 	 // if err == nil {
// 	 // 	 rLimit.Cur = 65535 // Set current limit
// 	 // 	 rLimit.Max = 65535 // Set max limit
// 	 // 	 syscall.Setrlimit(syscall.RLIMIT_NOFILE, &rLimit)
// 	 // }
// }

