#!/bin/bash

# Define color codes
COLOR_RESET='\033[0m'
COLOR_GREEN='\033[0;32m'
COLOR_YELLOW='\033[1;33m'
COLOR_CYAN='\033[0;36m'
COLOR_RED='\033[0;31m'
COLOR_BOLD='\033[1m'

echo -e "${COLOR_CYAN}
         _                               __
  ___ _ (_)__ __ ___  ___   ___ ___  ___/ /
 / _ \`// / \\ \\ // _ \\/ _ \\ (_-</ -_)/ _  /
 \\_, //_/ /_\\_\\/ .__/\\___//___/\\__/ \\_,_/
 /___/         /_/
                           @whxitte
${COLOR_RESET}"

# Function to display help
show_help() {
    echo -e "${COLOR_CYAN}Usage: $0 [OPTIONS]${COLOR_RESET}"
    echo -e "${COLOR_YELLOW}Options:${COLOR_RESET}"
    echo -e "  ${COLOR_BOLD}--s <search_string>${COLOR_RESET}   Search for a string (e.g., API key, access key, etc.)"
    echo -e "  ${COLOR_BOLD}--p <repo_path>${COLOR_RESET}       Specify the path to the Git repository"
    echo -e "  ${COLOR_BOLD}--h${COLOR_RESET}                  Display this help message"
}

# Parse command-line arguments
search_string=""
repo_path=""
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --s) search_string="$2"; shift ;;
        --p) repo_path="$2"; shift ;;
        --h) show_help; exit 0 ;;
        *) echo -e "${COLOR_RED}Unknown parameter passed: $1${COLOR_RESET}"; show_help; exit 1 ;;
    esac
    shift
done

# Display help if no search string is provided
if [[ -z "$search_string" ]]; then
    echo -e "Running in interactive mode..."
    # Prompt for the string to search
    echo -ne "${COLOR_YELLOW}Enter the string to search for (e.g., API key, access key, etc.): ${COLOR_RESET}"
    read search_string
fi

# Check if the repo_path is provided; if not, use the current directory
if [[ -z "$repo_path" ]]; then
    repo_path="$(pwd)"
fi

# Check if the specified path is a Git repository
check_git_repo() {
    if [ ! -d "$1/.git" ]; then
        return 1
    else
        return 0
    fi
}

# Function to extract repository owner and name from the Git remote URL
get_github_repo_details() {
    # Get the GitHub remote URL
    git_remote_url=$(git config --get remote.origin.url)

    # Extract owner and repository name using regex
    if [[ $git_remote_url =~ github.com[:/](.*)/(.*)\.git ]]; then
        repo_owner="${BASH_REMATCH[1]}"
        repo_name="${BASH_REMATCH[2]}"
    else
        echo -e "${COLOR_RED}Could not determine GitHub repository owner and name.${COLOR_RESET}"
        exit 1
    fi
}

# Check if the specified path is a Git repository
while true; do
    if check_git_repo "$repo_path"; then
        echo -e "${COLOR_GREEN}Current directory is a Git repository.${COLOR_RESET}"
        echo -ne "${COLOR_YELLOW}Do you want to proceed? (y/n): ${COLOR_RESET}"
        read -r proceed_choice

        if [[ "$proceed_choice" =~ ^[Yy]$ ]]; then
            cd "$repo_path" || exit
            break
        elif [[ "$proceed_choice" =~ ^[Nn]$ ]]; then
            echo -e "${COLOR_RED}Exiting the script.${COLOR_RESET}"
            exit 0
        else
            echo -e "${COLOR_RED}Invalid choice. Please enter 'y' or 'n'.${COLOR_RESET}"
        fi
    else
        echo -e "${COLOR_RED}This is not a Git repository.${COLOR_RESET}"
        echo -ne "${COLOR_YELLOW}Please enter a valid Git repository path: ${COLOR_RESET}"
        read repo_path

        # Change to the new directory if valid
        if [ -d "$repo_path" ]; then
            cd "$repo_path" || exit
        else
            echo -e "${COLOR_RED}The path entered is not valid. Please try again.${COLOR_RESET}"
        fi
    fi
done

# Fetch repository owner and name automatically
get_github_repo_details

# Fetch all branches and tags to ensure history is complete
git fetch --all

# Searching for the string in the entire repository history
echo -e "${COLOR_YELLOW}Searching for the string \"$search_string\" in the entire repository history...${COLOR_RESET}"

# Function to strip escape sequences
strip_escape_sequences() {
    echo "$1" | sed -E 's/\x1B\[[0-9;]*[JKmsu]//g'
}

# Function to print output with a dynamic box
print_in_box() {
    content=("$@")
    max_len=0

    # Calculate the maximum line length without considering escape sequences
    for line in "${content[@]}"; do
        stripped_line=$(strip_escape_sequences "$line")
        if [ ${#stripped_line} -gt $max_len ]; then
            max_len=${#stripped_line}
        fi
    done

    # Print top border
    border=$(printf '─%.0s' $(seq 1 $((max_len + 4))))
    echo "┌$border┐"

    # Print content with side borders
    for line in "${content[@]}"; do
        echo -e "│ ${line}$(printf '%*s' $((max_len - ${#line})) | tr ' ' ' ') "
    done

    # Print bottom border
    echo "└$border┘"
}

# Search through the entire repository's commit history and show commit hash, author, filename, line number, and highlighted matching string
git rev-list --all | while read -r commit_hash; do
    git grep -n --color=always -F "$search_string" "$commit_hash" | while IFS=: read -r commit file_path line_number match_content; do
        # Get the commit author
        commit_author=$(git show -s --format='%an' "$commit_hash")

        # Generate the GitHub link
        github_link="https://github.com/${repo_owner}/${repo_name}/blob/${commit_hash}/${file_path}#L${line_number}"

        # Store the output in an array
        output=(
            "${COLOR_BOLD}Commit:${COLOR_RESET} $commit_hash"
            "${COLOR_BOLD}Author:${COLOR_RESET} $commit_author"
            "${COLOR_BOLD}File:${COLOR_RESET} $file_path"
            "${COLOR_BOLD}Line:${COLOR_RESET} $line_number"
            "${COLOR_BOLD}Match:${COLOR_RESET} $match_content"
            ""
            "${COLOR_BOLD}GitHub Link:${COLOR_RESET} $github_link"
            ""
            "${COLOR_BOLD}To view the commit locally, run:${COLOR_RESET}"
            "${COLOR_BOLD}git show $commit_hash${COLOR_RESET}"
            ""
            "${COLOR_BOLD}To check out the commit locally, run:${COLOR_RESET}"
            "${COLOR_BOLD}git checkout $commit_hash${COLOR_RESET}"
        )

        # Print the output in a dynamically created box
        print_in_box "${output[@]}"
        echo ""
    done
done

echo -e "${COLOR_GREEN}Search completed.${COLOR_RESET}"
