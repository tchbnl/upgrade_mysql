#!/bin/bash
# upgrade_mysql - A simple MySQL/MariaDB upgrade script for cPanel servers
# Nathan Paton <nathanpat@inmotionhosting.com>
# v0.1 (Updated on 1/19/2023)

# Before we even try to do anything, this script requires a cPanel server
if ! [[ -x /usr/local/cpanel/bin/whmapi1 ]]; then
  echo "Couldn't locate the WHM API. This script requires a cPanel server to work."

  exit
fi

# Text formatting
TEXT_BOLD="\e[1m"
TEXT_RESET="\e[0m"

# Backup, backup, backup
echo -e "${TEXT_BOLD}Heads up!${TEXT_RESET} This can be a destructive process. Make sure to run 'backup_mysql' first to create a full backup. Also make a snapshot if this is a VPS.\n"

# In case whmapi1 isn't in our path for some reason
whmapi1_cmd() {
  /usr/local/cpanel/bin/whmapi1 "${@}"
}

# Is this MySQL or MariaDB? Let's find out.
MYSQL_KIND="$(whmapi1_cmd current_mysql_version | grep server: | awk -F ': ' '{print $2}')"
if [[ "${MYSQL_KIND}" == "mariadb" ]]; then
  MYSQL_KIND="MariaDB"
elif [[ "${MYSQL_KIND}" == "mysql" ]]; then
  MYSQL_KIND="MySQL"
fi

# Get our current and available MySQL/MariaDB versions. We need to reuse this
# again, so it's a function.
show_versions() {
  # Get and show the current version installed
  VERSION_INSTALLED="$(whmapi1_cmd current_mysql_version | grep -A 1 server: | grep version: | awk -F "'" '{print $2}')"

  echo -e "Installed: ${MYSQL_KIND} ${VERSION_INSTALLED}\n"

  # Now list what's available
  # WHM offers to reinstall the current version in case of a failed upgrade or
  # if MySQL had to be reinstalled because of an oops
  VERSION_AVAILABLE="$(whmapi1_cmd installable_mysql_versions | grep -A 1 server: | grep version: | awk -F "'" '{print $2}')"

  echo -e "Here's what's available:"
  echo "${VERSION_AVAILABLE}" | sed '1s/$/ [Installed]/' | awk '{print "* " $0}'
  echo # Spacing
}

# First run
show_versions

while true; do
  # Get the version to upgrade to (or bail out)
  read -rp "Choose Your Fighter (or \"Bail\"): " VERSION_SELECTED

  # We do a hack with shopt here for case-insensitive regex below
  if shopt nocasematch | grep -q off; then
    shopt -s nocasematch
  fi

  # If the version selected is right, do the upgrade further down
  if echo "${VERSION_AVAILABLE}" | grep -q "${VERSION_SELECTED}"; then
    echo -e "\nNo turning back now. Starting the upgrade...\n"

    break
  # We bail out if requested
  elif [[ "${VERSION_SELECTED}" =~ bail|quit|exit|q ]]; then
    # Now we undo the shopt hack (if needed)
    if shopt nocasematch | grep -q on; then
      shopt -u nocasematch
    fi

    echo -e "\nRoger that. No changes made."

    exit
  else
    # Or we ask again for a _usable_ version number if needed
    echo -e "\nYou said \"${VERSION_SELECTED}.\" Let's try that again.\n"

    # Show the installed and available versions again
    show_versions
  fi
done

# Did not want to variablize the actual command we run, but need that sweet
# upgrade_id from it for later
UPGRADE_ID="$(whmapi1_cmd start_background_mysql_upgrade version="${VERSION_SELECTED}" | grep upgrade_id: | awk -F ': ' '{print $2}')"

# Now we do a loop to check the status
while true; do
  # Get the status and variablize it to grep later
  UPGRADE_STATUS="$(whmapi1_cmd background_mysql_upgrade_status upgrade_id="${UPGRADE_ID}")"

  if echo "${UPGRADE_STATUS}" | grep state: | grep -q inprogress; then
    # TODO: Change this each run to something random
    echo "Rotating beagles..."

    sleep 5
  elif echo "${UPGRADE_STATUS}" | grep state: | grep -q success; then
    echo -e "\n${TEXT_BOLD}Success!${TEXT_RESET} ${MYSQL_KIND} has been successfully upgraded to ${VERSION_SELECTED}."

    exit
  elif echo "${UPGRADE_STATUS}" | grep state: | grep -q failed; then
    echo -e "\n${TEXT_BOLD}Uh-oh!${TEXT_RESET} Something went wrong. Here's a tail of the log:\n"
    # Get the log file so the user can view it if needed
    echo -e "File: /var/cpanel/logs/${UPGRADE_ID}/unattended_background_upgrade.log\n"

    # And tail the end in case it has some useful info that saves them time
    tail "/var/cpanel/logs/${UPGRADE_ID}/unattended_background_upgrade.log"

    exit
  fi
done
