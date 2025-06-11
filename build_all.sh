#!/bin/bash

# build_all.sh - Build all vulnerabilities in the benchmark
# This script finds and executes config.sh && build.sh and setup_func.sh && build_func.sh files in the project structure

# We don't use 'set -e' here because we want to continue processing
# other vulnerabilities even if individual build scripts fail

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

# Function to execute build scripts in a given directory
execute_build() {
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
    
    local build_success=0
    local build_func_success=0
    
    # Execute config.sh && build.sh if they exist
    if [ -f "config.sh" ] && [ -f "build.sh" ]; then
        chmod +x config.sh build.sh
        print_step "Executing config.sh && build.sh for $project_name/$vuln_id (timeout: 20 minutes)"
        if timeout 1200 bash -c "bash config.sh && bash build.sh"; then
            print_info "✓ Successfully completed config.sh && build.sh for $project_name/$vuln_id"
            build_success=1
        else
            local exit_code=$?
            if [ $exit_code -eq 124 ]; then
                print_error "✗ Timeout (20 minutes) while executing config.sh && build.sh for $project_name/$vuln_id"
            else
                print_error "✗ Failed to execute config.sh && build.sh for $project_name/$vuln_id"
            fi
            echo "REGULAR_BUILD"
            return 1
        fi
    else
        if [ ! -f "config.sh" ]; then
            print_error "config.sh not found in $vuln_dir"
        fi
        if [ ! -f "build.sh" ]; then
            print_error "build.sh not found in $vuln_dir"
        fi
        echo "REGULAR_BUILD"
        return 1
    fi
    
    # Execute config_func.sh && build_func.sh if they exist
    if [ -f "config_func.sh" ] && [ -f "build_func.sh" ]; then
        chmod +x config_func.sh build_func.sh
        print_step "Executing config_func.sh && build_func.sh for $project_name/$vuln_id (timeout: 20 minutes)"
        if timeout 1200 bash -c "bash config_func.sh && bash build_func.sh"; then
            print_info "✓ Successfully completed config_func.sh && build_func.sh for $project_name/$vuln_id"
            build_func_success=1
        else
            local exit_code=$?
            if [ $exit_code -eq 124 ]; then
                print_error "✗ Timeout (20 minutes) while executing config_func.sh && build_func.sh for $project_name/$vuln_id"
            else
                print_error "✗ Failed to execute config_func.sh && build_func.sh for $project_name/$vuln_id"
            fi
            echo "FUNCTIONAL_BUILD"
            return 1
        fi
    else
        if [ ! -f "config_func.sh" ]; then
            print_warning "config_func.sh not found in $vuln_dir"
        fi
        if [ ! -f "build_func.sh" ]; then
            print_warning "build_func.sh not found in $vuln_dir"
        fi
        print_info "Skipping functional build for $project_name/$vuln_id"
    fi
    
    # Check if at least one build was executed successfully
    if [ $build_success -eq 0 ] && [ $build_func_success -eq 0 ]; then
        print_error "No build scripts found or executed successfully in $vuln_dir"
        echo "NO_BUILD_SCRIPTS"
        return 1
    fi
    
    # Determine success type
    if [ $build_success -eq 1 ] && [ $build_func_success -eq 1 ]; then
        echo "BOTH"
    elif [ $build_success -eq 1 ]; then
        echo "REGULAR_ONLY"
    else
        echo "FUNCTIONAL_ONLY"
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
    
    # Execute build scripts
    local result=$(execute_build "$vuln_dir" "$original_dir")
    local exit_code=$?
    
    if [ $exit_code -eq 0 ]; then
        print_info "✅ All build scripts completed successfully for $display_project/$display_vuln"
        echo "SUCCESS:$result:$vuln_dir"
        return 0
    else
        print_error "❌ Build failed for $display_project/$display_vuln"
        echo "FAILED:$result:$vuln_dir"
        return 1
    fi
}

# Export functions so they can be used by parallel processes
export -f execute_build
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
    local log_file="build_results_${timestamp}.log"
    
    print_info "Starting build for all vulnerabilities in the benchmark..."
    print_info "Using $jobs parallel processes"
    print_info "Results will be saved to: $log_file"
    
    # Store the original directory
    ORIGINAL_DIR=$(pwd)
    
    # Find all directories that contain both config.sh and build.sh files
    mapfile -t vuln_dirs < <(find . -name "config.sh" -type f -exec dirname {} \; | while read dir; do
        if [ -f "$dir/build.sh" ]; then
            echo "$dir"
        fi
    done | sort)
    
    if [ ${#vuln_dirs[@]} -eq 0 ]; then
        print_error "No directories with both config.sh and build.sh files found in the current directory tree."
        exit 1
    fi
    
    print_info "Found ${#vuln_dirs[@]} vulnerability directories with config.sh and build.sh files"
    
    # Show some statistics
    local total_build_func=$(find . -name "config_func.sh" -type f -exec test -f {%/*}/build_func.sh \; -exec dirname {} \; | wc -l)
    print_info "Found $total_build_func directories with both config_func.sh and build_func.sh files"
    
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
    local success_both=0
    local success_regular_only=0
    local success_functional_only=0
    local failed_regular=0
    local failed_functional=0
    local failed_no_scripts=0
    
    while IFS= read -r line; do
        if [[ "$line" == SUCCESS:* ]]; then
            ((success_count++))
            local success_type=$(echo "$line" | cut -d':' -f2)
            case "$success_type" in
                "BOTH") ((success_both++)) ;;
                "REGULAR_ONLY") ((success_regular_only++)) ;;
                "FUNCTIONAL_ONLY") ((success_functional_only++)) ;;
            esac
        elif [[ "$line" == FAILED:* ]]; then
            ((failed_count++))
            local fail_type=$(echo "$line" | cut -d':' -f2)
            local failed_dir=$(echo "$line" | cut -d':' -f3)
            failed_dirs+=("$failed_dir")
            case "$fail_type" in
                "REGULAR_BUILD") ((failed_regular++)) ;;
                "FUNCTIONAL_BUILD") ((failed_functional++)) ;;
                "NO_BUILD_SCRIPTS") ((failed_no_scripts++)) ;;
            esac
        fi
    done < "$temp_results"
    
    # Clean up temporary file
    rm -f "$temp_results"
    
    # Print final summary and save to log file
    echo
    echo "========================================"
    print_info "BUILD SUMMARY"
    echo "========================================"
    print_info "Total vulnerabilities processed: $total_count"
    print_info "Successfully processed: $success_count"
    if [ $success_both -gt 0 ]; then
        print_info "  - Both builds successful: $success_both"
    fi
    if [ $success_regular_only -gt 0 ]; then
        print_info "  - Regular build only: $success_regular_only"
    fi
    if [ $success_functional_only -gt 0 ]; then
        print_info "  - Functional build only: $success_functional_only"
    fi
    
    # Create log file content
    {
        echo "Build Results - $(date)"
        echo "========================================"
        echo "Total vulnerabilities processed: $total_count"
        echo "Successfully processed: $success_count"
        echo "  - Both builds successful: $success_both"
        echo "  - Regular build only: $success_regular_only"
        echo "  - Functional build only: $success_functional_only"
        echo
        echo "Failed to process: $failed_count"
        if [ $failed_regular -gt 0 ]; then
            echo "  - Failed at regular build: $failed_regular"
        fi
        if [ $failed_functional -gt 0 ]; then
            echo "  - Failed at functional build: $failed_functional"
        fi
        if [ $failed_no_scripts -gt 0 ]; then
            echo "  - No build scripts found: $failed_no_scripts"
        fi
        echo
        if [ $failed_count -gt 0 ]; then
            echo "Failed directories:"
            for failed_dir in "${failed_dirs[@]}"; do
                local failed_project=$(echo "$failed_dir" | cut -d'/' -f2)
                local failed_vuln=$(echo "$failed_dir" | cut -d'/' -f3)
                echo "  - $failed_project/$failed_vuln ($failed_dir)"
            done
        else
            echo "All vulnerabilities built successfully!"
        fi
        echo
        echo "Build completed at: $(date)"
    } > "$log_file"
    
    if [ $failed_count -gt 0 ]; then
        print_error "Failed to process: $failed_count"
        if [ $failed_regular -gt 0 ]; then
            print_error "  - Failed at regular build: $failed_regular"
        fi
        if [ $failed_functional -gt 0 ]; then
            print_error "  - Failed at functional build: $failed_functional"
        fi
        if [ $failed_no_scripts -gt 0 ]; then
            print_error "  - No build scripts found: $failed_no_scripts"
        fi
        echo
        print_error "Failed directories:"
        for failed_dir in "${failed_dirs[@]}"; do
            local failed_project=$(echo "$failed_dir" | cut -d'/' -f2)
            local failed_vuln=$(echo "$failed_dir" | cut -d'/' -f3)
            echo "  - $failed_project/$failed_vuln ($failed_dir)"
        done
        echo
        print_warning "Some vulnerabilities may not be built correctly."
        print_info "Build results saved to: $log_file"
        exit 1
    else
        echo
        print_info "🎉 All vulnerabilities built successfully!"
        print_info "You can now proceed with testing the vulnerabilities."
        print_info "Build results saved to: $log_file"
    fi
}

# Show usage if help is requested
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    echo "Usage: $0 [jobs]"
    echo
    echo "This script builds all vulnerabilities in the benchmark by executing:"
    echo "  - config.sh && build.sh (regular build)"
    echo "  - config_func.sh && build_func.sh (functional build)"
    echo
    echo "The script will process each vulnerability directory in parallel and run both build sequences if the required files exist."
    echo "Some vulnerabilities may only have regular build scripts but not functional build scripts - this is normal."
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
