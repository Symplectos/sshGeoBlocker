#!/bin/bash

########################################################################################################################
# Bash script to only allow SSH access from a specified list of countries
#
# Author: Gilles Bellot
# Date: 01/04/2021
# Location: Lenningen, Luxembourg
#
# Usage: ./sshGeoBlocker 8.8.8.8
########################################################################################################################

########################################################################################################################
# VARIABLES ############################################################################################################
########################################################################################################################

# define list of countries that are allowed SSH access (separated by space ; country codes in all caps)
allowedCountries="LU NL"

# specify log facility
logFacility="auth.notice"

########################################################################################################################
# SCRIPT ###############################################################################################################
########################################################################################################################

# check for valid input
if [ $# -ne 1 ]; then
  # check for valid input
  echo "Usage: $(basename) $0 <ip>" 1>&2

  # return true when run incorrectly, as not to accidentally add strange rules to the firewall
  exit 0
fi

# determine IP version, i.e. IPv4 or IPv6
ipVersion=''
if [[ "$(echo "$1" | grep ':')" != "" ]] ; then
  # this is an IPv6 address -> add "6" to the command call
  ipVersion='6'
fi

# get the country
country=$(/usr/bin/geoiplookup${ipVersion} "$1" | awk -F ": " '{ print $2 }' | awk -F "," '{ print $1 }' | head -n 1)

# if the country is in the list of allowed countries, or if the IP address was not found, return ALLOW, else return DENY
[[ $country = "IP Address not found" || $allowedCountries =~ $country ]] && response="ALLOW" || response="DENY"

if [ $response = "ALLOW" ] ; then
  # return 0, as in, no errors
  exit 0
else
  # the country was not in the list of allowed countries -> log that a connection was denied and exit with an error
  logger -p ${logFacility} "$response sshd connection from $1 ($country)"

  # and exit with an error message, telling aclexec to block the connection attempt
  exit 1
fi