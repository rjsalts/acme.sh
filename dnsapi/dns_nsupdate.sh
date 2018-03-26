#!/usr/bin/env sh
set -x
########  Public functions #####################

#Usage: dns_nsupdate_add   _acme-challenge.www.domain.com   "XKrxpRBosdIKFzxW_CT3KLZNf6q0HG9i01zxXp5CPBs"
dns_nsupdate_add() {
  fulldomain=$1
  txtvalue=$2
  _checkKeyFile || return 1
  # save the TSIG key and type to the account conf file.
  _saveaccountconf NSUPDATE_KEY "${NSUPDATE_KEY}"
  _saveaccountconf NSUPDATE_ARGS "${NSUPDATE_ARGS}"
  _info "adding ${fulldomain}. 60 in txt \"${txtvalue}\""
  nsupdate "${NSUPDATE_ARGS}" <<EOF
update add ${fulldomain}. 60 in txt "${txtvalue}"
send
EOF
  if [ $? -ne 0 ]; then
    _err "error updating domain"
    return 1
  fi

  return 0
}

#Usage: dns_nsupdate_rm   _acme-challenge.www.domain.com
dns_nsupdate_rm() {
  fulldomain=$1
  _checkKeyFile || return 1
  _info "removing ${fulldomain}. txt"
  nsupdate "${NSUPDATE_ARGS}" <<EOF
update delete ${fulldomain}. txt
send
EOF
  if [ $? -ne 0 ]; then
    _err "error updating domain"
    return 1
  fi

  return 0
}

####################  Private functions below ##################################

_checkKeyFile() {
  if [ -z "${NSUPDATE_KEY}" ]; then
    _err "you must specify a path to the nsupdate key file"
    return 1
  fi
  if [ ! -r "${NSUPDATE_KEY}" ]; then
    _err "key ${NSUPDATE_KEY} is unreadable"
    return 1
  fi
  if [ -z "${NSUPDATE_ARGS}" ]; then
    if _exists "file"; then
      if file "${NSUPDATE_KEY}" | grep -q "Kerberos";then
        NSUPDATE_ARGS="-g"
      else
        NSUPDATE_ARGS="-k ${NSUPDATE_KEY}"
      fi
    else
      _err "Can't determine ${NSUPDATE_KEY} type."
      _err "Install file, or set NSUPDATE_ARGS."
      return 1
    fi
  fi
  if _endswith "${NSUPDATE_ARGS}" "-g"; then
    if _exists kinit; then
      if ! kinit -k -t "${NSUPDATE_KEY}"; then
        _err "Couldn't acquire kerberos ticket."
        return 1
      fi
    else
      _err "kinit not found."
      return 1
    fi
  fi
}
