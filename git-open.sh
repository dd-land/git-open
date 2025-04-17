#!/bin/sh

usage() {
  echo "Usage: $0 [-r remote] [user name] [repo name]"
  echo ""
  echo "Options:"
  echo "  -r, --remote   Specify git remote name (default: origin)"
  echo ""
  echo "Note: user name will default to \$GITHUB_USER or your \`git config --get github.user\` entry."
}

# parse URL and set baseurl, username, repo
parse_url() {
  local url="$1" project host proto path

  project=${url##**/}

  host=${url#git@}
  host=${host#ssh:\/\/git@}
  host=${host#http://}
  host=${host#https://}
  proto=${url%$host}
  host=${host%%[:/]*}

  path=${url#$proto$host[:/]}
  path=${path%/$project}

  project=${project%.git}

  baseurl="https://$host"
  username="$path"
  repo="$project"
}

remote="origin"
username=""
repo=""

# parse CLI args
while [ $# -gt 0 ]; do
  case "$1" in
    -r|--remote)
      remote="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    -v|--version)
      echo "version 1.4"
      exit 0
      ;;
    *)
      if [ -z "$username" ]; then
        username="$1"
      elif [ -z "$repo" ]; then
        repo="$1"
      fi
      shift
      ;;
  esac
done

git_repo=$(git rev-parse --git-dir 2>/dev/null)

if [ -n "$username" ] && [ -n "$repo" ]; then
  baseurl="https://github.com"
elif [ -n "$git_repo" ]; then
  url=$(git config "remote.${remote}.url")
  if [ -z "$url" ]; then
    echo "Error: remote '$remote' not found"
    exit 1
  fi
  parse_url "$url"
else
  if [ -z "$repo" ]; then
    echo "Error: must pass repo name or run from a git repo to open"
    usage
    exit 1
  fi
  baseurl=${GITHUB_URL:-"https://github.com"}
fi

if [ -z "$username" ]; then
  username=${GITHUB_USER:-$(git config --get github.user)}
fi

url="$baseurl/$username/$repo"

if [ -n "$DEBUG" ]; then
  echo "$url"
else
  open "$url"
fi
