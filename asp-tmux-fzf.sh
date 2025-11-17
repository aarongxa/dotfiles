#!/usr/bin/env bash
# 
# AWS Bash add-ons
# Updated for fzf and tmux integration
#
# To use this script, add the following line to your ~/.bashrc or ~/.bash_profile:
# source $HOME/dotfiles/asp-tmux-fzf.sh

# 20250520 - Integrated fzf for profile/region selection, updated tmux title bar support
# 20250520 - Added automatic region prompt in asp, added space in PS1
# 20250520 - Used tmux environment variables and PROMPT_COMMAND for status bar updates
# 20250521 - Updated fzf window to be smaller and centered, added script best practices (set -eEuo pipefail)
# 20250521 - Removed --width from fzf, adjusted margin for compatibility due to "unknown option: --width" error.
# 20250521 - Increased fzf height to 60%, added --tmux=popup for better tmux integration.

# Note: We don't use 'set -eEuo pipefail' here because this script is meant to be sourced.
# Strict error handling would cause the shell to exit on any error when sourcing.
# Individual functions handle their own error checking and return appropriate exit codes.

# Set AWS_CONFIG_FILE with fallback to shared config
if [ -f /opt/techops/etc/aws/shared_config ]; then
    export AWS_CONFIG_FILE="${HOME}/.aws/config" # Quoted HOME for safety
fi

# Ensure CONFIGPATH is set, defaulting to ~/.aws/config if AWS_CONFIG_FILE is somehow empty
# (though the above logic should prevent AWS_CONFIG_FILE from being empty)
if [[ -z "${AWS_CONFIG_FILE}" ]]; then
    export CONFIGPATH="${HOME}/.aws/config" # Fallback, should ideally not be reached
else
    export CONFIGPATH="${AWS_CONFIG_FILE}"
fi

# Validate that the AWS config file exists and is readable
# Warn if missing, but don't exit (functions will handle errors when they try to use it)
if [[ ! -f "${CONFIGPATH}" ]] || [[ ! -r "${CONFIGPATH}" ]]; then
    echo "Warning: AWS config file not found or not readable at ${CONFIGPATH}" >&2
    echo "Please ensure ${CONFIGPATH} exists and is readable to use AWS profile functions." >&2
fi

# Function to display shared config usage
aws_use_shared() {
    echo -e "The AWS Profile Selector supports a shared .aws/config file.\n"
    echo -e "Setup a profile in your .aws/credentials file like:\n"
    echo -e "[profile-name]\naws_access_key_id = AKIAXXXXXXXXXXXXXXX\naws_secret_access_key = Os1XXXXXXXXXXXXXXXXXXXXX\n"
    echo -e "Add to your .bashrc before sourcing this script:\n"
    echo -e "export AWS_CONFIG_FILE=/etc/aws/shared-config\n"
    echo -e "Logout to use the shared AWS config file.\n"
}

# Function to display AWS profile and region in prompt
aws_prompt_info() {
    local profile_display=""
    local region_display=""
    # Only display if the variable is set and not empty
    [[ -n "${AWS_PROFILE:-}" ]] && profile_display="[${AWS_PROFILE}]"
    [[ -n "${AWS_REGION:-}" ]] && region_display="[${AWS_REGION}]"
    echo -n "${profile_display}${region_display}"
}

# Function to update tmux environment variables
update_tmux_status() {
    if [ -n "${TMUX:-}" ]; then # Check if TMUX environment variable is set and not empty
        # Suppress errors in case tmux commands fail (e.g., not in a tmux session, though TMUX check should cover this)
        tmux set-environment -g AWS_PROFILE_STATUS "${AWS_PROFILE:-}" 2>/dev/null || true
        tmux set-environment -g AWS_REGION_STATUS "${AWS_REGION:-}" 2>/dev/null || true
        tmux refresh-client -S 2>/dev/null || true # Refresh status line
    fi
}

# Set PROMPT_COMMAND to update tmux status before prompt
# Prepend to existing PROMPT_COMMAND if it's already set
if [[ -z "${PROMPT_COMMAND:-}" ]]; then
    PROMPT_COMMAND="update_tmux_status"
else
    # Ensure update_tmux_status is not added multiple times if script is sourced again
    if [[ ! "$PROMPT_COMMAND" == *"update_tmux_status"* ]]; then
        PROMPT_COMMAND="update_tmux_status; $PROMPT_COMMAND"
    fi
fi

# Alias to clear AWS profile and region
alias clearprofile='export AWS_PROFILE=; export AWS_REGION=; export AWS_DEFAULT_REGION=; update_tmux_status'

# Set AWS profile
setprofile() {
    if [[ -z "$1" ]]; then
        echo "Error: No profile name supplied to setprofile."
        return 1
    fi
    # Check if profile exists in the config file
    # Using grep -q for quiet mode, [[:space:]]* for portable whitespace matching
    if grep -q "\[profile ${1}[[:space:]]*\]" "${CONFIGPATH}"; then
        export AWS_PROFILE="$1"
        update_tmux_status
        echo "AWS Profile set to: $AWS_PROFILE"
    else
        echo "Error: Invalid profile name '$1' or profile not found in ${CONFIGPATH}."
        return 1 # Indicate failure
    fi
}

# Set AWS region
setregion() {
    if [[ -z "$1" ]]; then
        echo "Error: No region name supplied to setregion."
        return 1
    fi
    export AWS_REGION="$1"
    export AWS_DEFAULT_REGION="$AWS_REGION" # Keep AWS_DEFAULT_REGION in sync
    update_tmux_status
    echo "AWS Region set to: $AWS_REGION"
}

# Get AWS profiles from config
getAWSProfiles() {
    local profiles_output
    # Ensure CONFIGPATH points to a readable file
    if [[ ! -f "${CONFIGPATH}" ]] || [[ ! -r "${CONFIGPATH}" ]]; then
        echo "Error: AWS config file not found or not readable at ${CONFIGPATH}" >&2
        AWSProfiles="" # Ensure it's empty on error
        return 1
    fi
    # Extract profile names, sort them, and store as a space-separated string
    # Use [[:space:]]* for portable whitespace matching instead of \s*
    profiles_output=$(grep "\[profile " "${CONFIGPATH}" | sed -e "s/\[profile[[:space:]]*//g" -e "s/\]//g" | sort | tr '\n' ' ')
    # Remove trailing space if any
    AWSProfiles=$(echo "${profiles_output}" | sed 's/ *$//')
}

# Select AWS profile using fzf and prompt for region if not set
asp() {
    if ! command -v fzf >/dev/null 2>&1; then
        echo "Error: fzf is not installed. Please install fzf to use this function."
        return 1
    fi

    getAWSProfiles
    # Check if getAWSProfiles failed or returned no profiles
    if [[ -z "${AWSProfiles:-}" ]]; then
        echo "No AWS profiles found in ${CONFIGPATH} or error fetching them."
        return 1
    fi

    local selected_profile
    local -a fzf_options # Declare as an array
    fzf_options=(
        --prompt="Select AWS Profile: "
        --border=rounded
        --layout=reverse
        --info=inline
        --header="Press ESC to cancel"
        --cycle
    )

    if [[ -n "${TMUX:-}" ]]; then
        # Running in tmux, use tmux popup
        # tmux popup defaults to 80% width/height and centered.
        # Override height. Width can be default or specified if needed.
        fzf_options+=(--height=60% --tmux=popup)
    else
        # Not in tmux, use margin for centering
        fzf_options+=(--height=60% --margin='20%,2,20%,2') # (100-60)/2 = 20% top/bottom margin
    fi

    selected_profile=$(echo "${AWSProfiles}" | tr ' ' '\n' | \
        fzf "${fzf_options[@]}") # Pass options as an array

    if [[ -n "$selected_profile" ]]; then
        if setprofile "$selected_profile"; then
            if [[ -z "${AWS_REGION:-}" ]]; then
                echo "No AWS region is currently set. Please select a region."
                asr
            else
                echo "Current region: $AWS_REGION"
                echo "You can run 'asr' to change your region if needed."
            fi
        fi
    else
        echo "No profile selected."
        return 1
    fi
}

# Get AWS regions
getAWSRegions() {
    local regions_output
    if ! command -v aws >/dev/null 2>&1; then
        echo "Error: AWS CLI is not installed. Please install AWS CLI to fetch regions." >&2
        AWSRegions=""
        return 1
    fi
    # describe-regions doesn't require credentials, but may fail due to network issues
    if ! regions_output=$(aws ec2 describe-regions --region us-east-1 --query "Regions[].{Name:RegionName}" --output text 2>&1); then
        echo "Error: Failed to retrieve AWS regions from AWS CLI: ${regions_output}" >&2
        AWSRegions=""
        return 1
    fi
    AWSRegions=$(echo "${regions_output}" | sort | tr '\n' ' ')
    AWSRegions=$(echo "${AWSRegions}" | sed 's/ *$//')

    if [[ -z "${AWSRegions:-}" ]]; then
        echo "Warning: No AWS regions were retrieved. This could be a CLI or network issue." >&2
    fi
}

# Select AWS region using fzf
asr() {
    if ! command -v fzf >/dev/null 2>&1; then
        echo "Error: fzf is not installed. Please install fzf to use this function."
        return 1
    fi

    getAWSRegions
    if [[ -z "${AWSRegions:-}" ]]; then
        echo "No AWS regions found or error fetching them. Cannot select a region."
        return 1
    fi

    local selected_region
    local -a fzf_options # Declare as an array
    fzf_options=(
        --prompt="Select AWS Region: "
        --border=rounded
        --layout=reverse
        --info=inline
        --header="Press ESC to cancel"
        --cycle
    )

    if [[ -n "${TMUX:-}" ]]; then
        # Running in tmux, use tmux popup
        fzf_options+=(--height=60% --tmux=popup)
    else
        # Not in tmux, use margin for centering
        fzf_options+=(--height=60% --margin='20%,2,20%,2')
    fi

    selected_region=$(echo "${AWSRegions}" | tr ' ' '\n' | \
        fzf "${fzf_options[@]}") # Pass options as an array

    if [[ -n "$selected_region" ]]; then
        setregion "$selected_region"
    else
        echo "No region selected."
        return 1
    fi
}

# Update PS1 to include AWS profile and region with a space
# Only modify PS1 if it doesn't already include aws_prompt_info and if PS1 is set
# Skip if Starship is being used (it handles AWS info via its own module)
if command -v starship >/dev/null 2>&1; then
    # Starship handles AWS display, so don't modify PS1
    :
elif [[ -n "${PS1:-}" ]] && [[ ! "$PS1" == *'$(aws_prompt_info)'* ]]; then
    export PS1="\$(aws_prompt_info) $PS1"
elif [[ -z "${PS1:-}" ]]; then
    # If PS1 is not set and not using Starship, set a minimal one
    export PS1="\$(aws_prompt_info) "
fi

# Notify user that the script extensions are loaded (optional)
# echo "AWS Bash add-ons loaded. Use 'asp' to select profile, 'asr' to select region."