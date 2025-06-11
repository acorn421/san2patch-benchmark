#!/bin/bash

# setup_all.sh - Setup all vulnerabilities in the benchmark
# This script finds and executes all setup.sh and setup_func.sh files in the project structure

# We don't use 'set -e' here because we want to continue processing
# other vulnerabilities even if individual setup scripts fail

# Default number of parallel processes
DEFAULT_JOBS=8

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# Function to execute setup scripts in a given directory
execute_setup() {
    local vuln_dir="$1"
    local original_dir="$2"
    
    # Parse project name and vulnerability ID from the path
    # Expected format: ./project_name/vuln_id
    local project_name=$(echo "$vuln_dir" | cut -d'/' -f2)
    local vuln_id=$(echo "$vuln_dir" | cut -d'/' -f3)
    
    print_info "Processing vulnerability: $project_name/$vuln_id"
    print_info "Directory: $vuln_dir"
    
    # Change to the vulnerability directory
    cd "$original_dir/$vuln_dir"
    
    local setup_success=0
    local setup_func_success=0
    
    # Execute setup.sh if it exists
    if [ -f "setup.sh" ]; then
        chmod +x setup.sh
        print_step "Executing setup.sh for $project_name/$vuln_id (timeout: 30 minutes)"
        if timeout 1800 bash setup.sh; then
            print_info "✓ Successfully completed setup.sh for $project_name/$vuln_id"
            setup_success=1
        else
            local exit_code=$?
            if [ $exit_code -eq 124 ]; then
                print_error "✗ Timeout (20 minutes) while executing setup.sh for $project_name/$vuln_id"
            else
                print_error "✗ Failed to execute setup.sh for $project_name/$vuln_id"
            fi
            return 1
        fi
    else
        print_error "setup.sh not found in $vuln_dir"
    fi
    
    # Execute setup_func.sh if it exists
    if [ -f "setup_func.sh" ]; then
        chmod +x setup_func.sh
        print_step "Executing setup_func.sh for $project_name/$vuln_id (timeout: 30 minutes)"
        if timeout 1800 bash setup_func.sh; then
            print_info "✓ Successfully completed setup_func.sh for $project_name/$vuln_id"
            setup_func_success=1
        else
            local exit_code=$?
            if [ $exit_code -eq 124 ]; then
                print_error "✗ Timeout (10 minutes) while executing setup_func.sh for $project_name/$vuln_id"
            else
                print_error "✗ Failed to execute setup_func.sh for $project_name/$vuln_id"
            fi
            return 1
        fi
    else
        print_warning "setup_func.sh not found in $vuln_dir"
        print_info "Copying repository created by setup.sh to functional testing directory"
        repo_func_dir=/experiment_func/san2patch-benchmark/$project_name/$vuln_id
        mkdir -p $repo_func_dir
        cp -r /experiment/san2patch-benchmark/$project_name/$vuln_id/* $repo_func_dir
    fi
    
    # Check if at least one setup script was executed successfully
    if [ $setup_success -eq 0 ] && [ $setup_func_success -eq 0 ]; then
        print_error "No setup scripts found or executed successfully in $vuln_dir"
        return 1
    fi
    
    return 0
}

# Function to process a single vulnerability (used for parallel execution)
process_vulnerability() {
    local vuln_dir="$1"
    local original_dir="$2"
    
    # Parse project and vulnerability info for display
    local display_project=$(echo "$vuln_dir" | cut -d'/' -f2)
    local display_vuln=$(echo "$vuln_dir" | cut -d'/' -f3)
    
    echo "========================================"
    print_info "Processing: $display_project/$display_vuln"
    echo "========================================"
    
    # Execute setup scripts
    if execute_setup "$vuln_dir" "$original_dir"; then
        print_info "✅ All setup scripts completed successfully for $display_project/$display_vuln"
        echo "SUCCESS:$vuln_dir"
        return 0
    else
        print_error "❌ Setup failed for $display_project/$display_vuln"
        echo "FAILED:$vuln_dir"
        return 1
    fi
}

# Export functions so they can be used by parallel processes
export -f execute_setup
export -f process_vulnerability
export -f print_info
export -f print_warning
export -f print_error
export -f print_step

# Main function
main() {
    local jobs="${1:-$DEFAULT_JOBS}"
    
    # Create log file with timestamp
    local timestamp=$(date +"%Y%m%d_%H%M%S")
    local log_file="setup_results_${timestamp}.log"
    
    print_info "Starting setup for all vulnerabilities in the benchmark..."
    print_info "Using $jobs parallel processes"
    print_info "Results will be saved to: $log_file"
    
    # Store the original directory
    ORIGINAL_DIR=$(pwd)
    
    # Find all directories that contain setup.sh files
    mapfile -t vuln_dirs < <(find . -name "setup.sh" -type f -exec dirname {} \; | sort)
    
    if [ ${#vuln_dirs[@]} -eq 0 ]; then
        print_error "No setup.sh files found in the current directory tree."
        exit 1
    fi
    
    print_info "Found ${#vuln_dirs[@]} vulnerability directories with setup.sh files"
    
    # Show some statistics
    local total_setup_func=$(find . -name "setup_func.sh" -type f | wc -l)
    print_info "Found $total_setup_func directories with setup_func.sh files"
    
    # Counters for tracking progress
    total_count=${#vuln_dirs[@]}
    
    # Export necessary variables for parallel processes
    export RED GREEN YELLOW BLUE NC ORIGINAL_DIR
    
    # Create a temporary file to store results
    local temp_results=$(mktemp)
    
    # Process vulnerabilities in parallel
    print_info "Processing vulnerabilities in parallel with $jobs jobs..."
    printf '%s\n' "${vuln_dirs[@]}" | xargs -P "$jobs" -I {} bash -c 'process_vulnerability "{}" "$ORIGINAL_DIR"' 2>&1 | tee "$temp_results"
    
    # Parse results
    local success_count=0
    local failed_count=0
    local failed_dirs=()
    
    while IFS= read -r line; do
        if [[ "$line" == SUCCESS:* ]]; then
            ((success_count++))
        elif [[ "$line" == FAILED:* ]]; then
            ((failed_count++))
            failed_dir="${line#FAILED:}"
            failed_dirs+=("$failed_dir")
        fi
    done < "$temp_results"
    
    # Clean up temporary file
    rm -f "$temp_results"
    
    # Print final summary and save to log file
    echo
    echo "========================================"
    print_info "SETUP SUMMARY"
    echo "========================================"
    print_info "Total vulnerabilities processed: $total_count"
    print_info "Successfully processed: $success_count"
    
    # Create log file content
    {
        echo "Setup Results - $(date)"
        echo "========================================"
        echo "Total vulnerabilities processed: $total_count"
        echo "Successfully processed: $success_count"
        echo "Failed to process: $failed_count"
        echo
        if [ $failed_count -gt 0 ]; then
            echo "Failed directories:"
            for failed_dir in "${failed_dirs[@]}"; do
                local failed_project=$(echo "$failed_dir" | cut -d'/' -f2)
                local failed_vuln=$(echo "$failed_dir" | cut -d'/' -f3)
                echo "  - $failed_project/$failed_vuln ($failed_dir)"
            done
        else
            echo "All vulnerabilities set up successfully!"
        fi
        echo
        echo "Setup completed at: $(date)"
    } > "$log_file"
    
    if [ $failed_count -gt 0 ]; then
        print_error "Failed to process: $failed_count"
        echo
        print_error "Failed directories:"
        for failed_dir in "${failed_dirs[@]}"; do
            local failed_project=$(echo "$failed_dir" | cut -d'/' -f2)
            local failed_vuln=$(echo "$failed_dir" | cut -d'/' -f3)
            echo "  - $failed_project/$failed_vuln ($failed_dir)"
        done
        echo
        print_warning "Some vulnerabilities may not be set up correctly."
        print_info "Setup results saved to: $log_file"
        exit 1
    else
        echo
        print_info "🎉 All vulnerabilities set up successfully!"
        print_info "You can now proceed with building and testing the vulnerabilities."
        print_info "Setup results saved to: $log_file"
    fi
}

# Show usage if help is requested
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    echo "Usage: $0 [jobs]"
    echo
    echo "This script sets up all vulnerabilities in the benchmark by executing:"
    echo "  - setup.sh (found in $( find . -name "setup.sh" -type f | wc -l ) directories)"
    echo "  - setup_func.sh (found in $( find . -name "setup_func.sh" -type f | wc -l ) directories)"
    echo
    echo "The script will process each vulnerability directory in parallel and run both setup scripts if they exist."
    echo "Some vulnerabilities may only have setup.sh but not setup_func.sh - this is normal."
    echo
    echo "Arguments:"
    echo "  jobs          Number of parallel processes to use (default: $DEFAULT_JOBS)"
    echo
    echo "Options:"
    echo "  -h, --help    Show this help message"
    echo
    echo "Examples:"
    echo "  $0            # Use default $DEFAULT_JOBS parallel processes"
    echo "  $0 4          # Use 4 parallel processes"
    echo "  $0 16         # Use 16 parallel processes"
    exit 0
fi

# Run main function
main "$@"
