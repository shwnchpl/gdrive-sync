#!/bin/bash

###############################################################################
# gdrive-sync: a simple script for version controlled local Google Drive
# backups using google-drive-ocamlfuse, rsync, and git.
#
# Copyright (C) 2018 Shawn M. Chapla 
# 
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301,
# USA.
###############################################################################

###############################################################################
# TODO:
#   * Setup README.md.
#   * Move todo stuff to a real todo.
#   * Should --no-create not call git init? (update man page if changed).
#   * Document config file.
#   * Make example config to be installed to be installed to /etc (update man page).
#   * Set up some kind of intelligent version/module name interpolation using autotools/sed?
#
# NOT TODO:
#   * Add functionality for sending mail regarding latest git commit. Use:
#       git show --stat     
#     (Actally, cron does this for us, so probably no need).
#
# DONE:
#   * All output should have $0 prepended to make it clear where it comes from.
#     (Ex. ./git_sync.sh: Error).
#   * Create a "fail" function that prints something and exits with some code.
#   * Create an unmount function to reduce code duplication.
#   * Add no-create option.
#   * Make an actual git repo and put this there.
#   * Come up with a better name. (gdrive-sync?)
#   * Create a makefile/install setup (using autoconf/automake?)
#   * Double quote varialbe references (ouch)
#   * Make an explicit verbose mode that gives all ouput. Non verbose mode should run rsync
#     quiet, gcamlfuse quiet, and not show would-be green messages.
#   * Make print usage actually do something useful.
#   * Check home director for config file by default.
#   * Be sure to check return from ALL git commands (and all commands) to be
#     sure they're executed properly.
#   * Figure out how to handle the default README.md (just keep it simple)
#   * Build man page as part of make process.
#   * Setup man page and add to autoconf build.
#
###############################################################################

# Constant strings
CONST_PROGRAM_NAME="gdrive-sync"

# Constant error numbers
ERR_INVALID_ARGUMENT=1
ERR_NO_CONFIG_SRC_DIR=2
ERR_NO_CONFIG_DEST_DIR=3
ERR_SRC_DIR_NOEXIST=4
ERR_MOUNTDIR_NOT_EMPTY=5
ERR_MKDIR_FAIL=6
ERR_GIT_INIT_FAIL=7
ERR_README_CREATE_FAIL=8
ERR_FUSERMOUNT_FAIL=9
ERR_FUSERMOUNT_U_FAIL=10
ERR_NOCREATE_FAIL=11

# Verbose file descriptor
VERBOSE_FILE_DESC=3
eval "exec $VERBOSE_FILE_DESC>/dev/null"

# Colors
if test -t 1; then # Check if stderr is a terminal.
  __ncolors=$(tput colors)

  if test -n "$__ncolors" && test $__ncolors -ge 8; then # Check if the terminal supports colors.
    FORMAT_BOLD="$(tput bold)"
    FORMAT_UNDERLINE="$(tput smul)"
    FORMAT_STANDOUT="$(tput smso)"
    FORMAT_NORMAL="$(tput sgr0)"
    FORMAT_COLOR_BLACK="$(tput setaf 0)"
    FORMAT_COLOR_RED="$(tput setaf 1)"
    FORMAT_COLOR_GREEN="$(tput setaf 2)"
    FORMAT_COLOR_YELLOW="$(tput setaf 3)"
    FORMAT_COLOR_BLUE="$(tput setaf 4)"
    FORMAT_COLOR_MAGENTA="$(tput setaf 5)"
    FORMAT_COLOR_CYAN="$(tput setaf 6)"
    FORMAT_COLOR_WHITE="$(tput setaf 7)"
  fi
fi

# Functions
function print_usage {
  echo "Usage: $CONST_PROGRAM_NAME --option=\"value\" --option"
  echo ""
  echo "$CONST_PROGRAM_NAME is a simple script for version controlled local Google Drive backups using google-drive-ocamlfuse, rsync, and git."
  echo ""
  echo "Options:"
  echo "-c=[FILE], --config=[FILE]        Use [FILE] as the configuration file."
  echo "-s=[DIR], --src=[DIR]             Use [DIR] as the source directory."
  echo "-d=[DEST], --dest=[DEST]          Use [DIR] as the dest directory."
  echo "--sync-dir-name=[DIR]             Use [DIR] as the sync directory. Sync"
  echo "                                  directory is the directory within the"
  echo "                                  destination directory to which files are"
  echo "                                  actually synced."
  echo "--sync-commit-message=[MESSAGE]   Append [MESSAGE] to each automatically"
  echo "                                  generated commit, following the timestamp."
  echo "                                  Defaults to \"$CONST_PROGRAM_NAME\"."
  echo "--mount-label=[LABEL]             Call google-drive-ocamlfuse with [LABEL]"
  echo "                                  as account label."
  echo ""
  echo "--no-delete                       Do not delete any files on sync."
  echo "-q, --quiet                       Suppress all output."
  echo "-v, --verbose                     Issue the most output."
  echo "--no-mount                        Assume the source directory is not a"
  echo "                                  mount point and/or that it already"
  echo "                                  contains the files we want to sync."
  echo "--no-colors                       No colored output. This shouldn't be"
  echo "                                  necessary on terminals that do not"
  echo "                                  support color."
  echo "--no-create                       Do not create any new directories."
  echo "-h, --help                        Print this message."
  echo ""
  echo "Please report bugs to https://github.com/shwnchpl/gdrive-sync or shwnchpl@gmail.com."
  echo ""
}

function formatted_output {
  __message_color=$([[ -z "$CONFIG_NO_COLORS" ]] && echo "${2:-"$FORMAT_COLOR_GREEN"}")
  __prefix_color=$([[ -z "$CONFIG_NO_COLORS" ]] && echo "$FORMAT_COLOR_CYAN")
  printf "$__prefix_color%s:$FORMAT_NORMAL $__message_color%s$FORMAT_NORMAL\n" "$CONST_PROGRAM_NAME" "$*"
}

function formatted_output_warn {
  formatted_output "$1" "$FORMAT_COLOR_YELLOW"
}

function formatted_output_and_fail {
  formatted_output "$1" "$FORMAT_COLOR_RED"
  exit $2
}

function formatted_output_verbose {
  if [[ ! -z "$CONFIG_VERBOSE_MODE" ]]; then
    formatted_output "$1"
  fi
}

function attempt_unmount {
  if fusermount -u "$CONFIG_SRC_DIR"; then
    formatted_output_verbose "Unmounted '$CONFIG_SRC_DIR'." 
  else
    formatted_output_and_fail "Failed to unmount '$CONFIG_SRC_DIR'. Terminating." "$ERR_FUSERMOUNT_U_FAIL"
  fi
}


# Start out without color, just in case people really don't want it.
CONFIG_NO_COLORS="yes"

# Variable position arguments
for arg in "$@"
do
  case $arg in
    -c=*|--config=*)
      ARG_CONFIG_FILE="${arg#*=}"
      shift
    ;;
    -s=*|--src=*)
      ARG_SRC_DIR="${arg#*=}"
      shift
    ;;
    -d=*|--dest=*)
      ARG_DEST_DIR="${arg#*=}"
      shift
    ;;
    --sync-dir-name=*)
      ARG_SYNC_DIR_NAME="${arg#*=}"
      shift
    ;;
    --sync-commit-message=*)
      ARG_SYNC_COMMIT_MESSAGE="${arg#*=}"
      shift
    ;;
    --mount-label=*)
      ARG_MOUNT_LABEL="${arg#*=}"
      shift
    ;;
    --no-delete)
      ARG_NO_DELETE="yes"
      shift
    ;;
    -q|--quiet)
      ARG_QUIET_MODE="yes"
      shift
    ;;
    -v|--verbose)
      ARG_VERBOSE_MODE="yes"
      shift
    ;;
    --no-mount)
      ARG_NO_MOUNT="yes"
      shift
    ;;
    --no-colors)
      ARG_NO_COLORS="yes"
      shift
    ;;
    --no-create)
      ARG_NO_CREATE="yes"
      shift
    ;;
    -h|--help)
      print_usage
      exit 0
    ;;
    *)
      # Unknown option
      formatted_output_and_fail "Invalid argument: $arg" $ERR_INVALID_ARGUMENT
    ;;
  esac
done

CONFIG_FILE=${ARG_CONFIG_FILE:-~/.gdsconfig}

if [[ -f $CONFIG_FILE ]]; then
  . $CONFIG_FILE
else
  formatted_output_warn "Could not open config file: '$CONFIG_FILE'"
fi

CONFIG_SYNC_DIR_NAME=${ARG_SYNC_DIR_NAME:-${sync_dir_name:-sync}}
CONFIG_SYNC_COMMIT_MESSAGE=${ARG_SYNC_COMMIT_MESSAGE:=${sync_commit_message:-"$CONST_PROGRAM_NAME"}}
CONFIG_NO_DELETE=${ARG_NO_DELETE:-$no_delete}
CONFIG_MOUNT_LABEL=${ARG_MOUNT_LABEL:-$default_mount_label}
CONFIG_NO_MOUNT=${ARG_NO_MOUNT:-$no_mount}
CONFIG_NO_COLORS=${ARG_NO_COLORS:-$no_colors}
CONFIG_NO_CREATE=${ARG_NO_CREATE:-$no_create}
CONFIG_VERBOSE_MODE=${ARG_VERBOSE_MODE:-$verbose_mode}

CONFIG_QUIET_MODE=${ARG_QUIET_MODE:-$quiet_mode}
CONFIG_SRC_DIR=${ARG_SRC_DIR:-$src_dir}
CONFIG_DEST_DIR=${ARG_DEST_DIR:-$dest_dir}

if [[ ! -z "$CONFIG_VERBOSE_MODE" ]]; then
  eval "exec $VERBOSE_FILE_DESC>&1"
fi

if [[ ! -z "$CONFIG_QUIET_MODE" ]]; then
  exec &> /dev/null
fi

if [[ -z "$CONFIG_SRC_DIR" ]]; then 
  formatted_output_and_fail "No source directory specified in config file or as argument." "$ERR_NO_CONFIG_SRC_DIR"
fi

if [[ -z "$CONFIG_DEST_DIR" ]]; then
  formatted_output_and_fail "No destination directory specified in config file or as argument." "$ERR_NO_CONFIG_DEST_DIR"
fi

if [[ ! -d "$CONFIG_SRC_DIR" ]]; then
  if [[ ! -z "$CONFIG_NO_MOUNT" ]]; then
    formatted_output_and_fail "Source directory does not exist. Terminating." "$ERR_SRC_DIR_NOEXIST"
  elif [[ -z "$CONFIG_NO_CREATE" ]]; then
    formatted_output_warn "Source directory mount point does not exist. Creating..."
    mkdir "$CONFIG_SRC_DIR" || formatted_output_and_fail "Failed to create directory '$CONFIG_SRC_DIR'. Terminating." "$ERR_MKDIR_FAIL"
  else
    formatted_output_and_fail "Cannot create source directory in no-create mode. Terminating." "$ERR_NOCREATE_FAIL"
  fi
fi

if [[ ! -d "$CONFIG_DEST_DIR" ]]; then
  if [[ -z "$CONFIG_NO_CREATE" ]]; then
    formatted_output_warn "Destination directory does not exist. Creating..."
    mkdir "$CONFIG_DEST_DIR" || formatted_output_and_fail "Failed to create directory '$CONFIG_DEST_DIR'. Terminating." "$ERR_MKDIR_FAIL"
  else
    formatted_output_and_fail "Cannot create destination directory in no-create mode. Terminating." "$ERR_NOCREATE_FAIL"
  fi
fi

if [[ ! -d "$CONFIG_DEST_DIR/$CONFIG_SYNC_DIR_NAME" ]]; then
  if [[ -z "$CONFIG_NO_CREATE" ]]; then
    formatted_output_warn "Sync directory '$CONFIG_DEST_DIR/$CONFIG_SYNC_DIR_NAME' does not exist. Creating..."
    mkdir "$CONFIG_DEST_DIR/$CONFIG_SYNC_DIR_NAME" || formatted_output_and_fail "Failed to create directory '$CONFIG_DEST_DIR/$CONFIG_SYNC_DIR_NAME'. Terminating." "$ERR_MKDIR_FAIL"
  else
    formatted_output_and_fail "Cannot create sync directory in no-create mode. Terminating." "$ERR_NOCREATE_FAIL"
  fi
fi

( 
  cd "$CONFIG_DEST_DIR"
  if git status &> /dev/null; then
    formatted_output_verbose "Repo already exists."
  else
    formatted_output_warn "No repo exists. Creating..."
    git init 2>&1 >&"$VERBOSE_FILE_DESC" || formatted_output_and_fail "Failed to create repo. Terminating." "$ERR_GIT_INIT_FAIL" 2>&1 >&"$VERBOSE_FILE_DESC"

    echo "$CONST_PROGRAM_NAME auto generated git repo." > README.md || formatted_output_and_fail "Failed to create README.md. Terminating." "$ERR_README_CREATE_FAIL"

    git add . 2>&1 >&"$VERBOSE_FILE_DESC"
    if [[ $? != 0 ]]; then
      formatted_output_warn "Failed to stage fils for git commit. Continuing..."
    fi

    git commit -m "Initial commit." 2>&1 >&"$VERBOSE_FILE_DESC"
    if [[ $? != 0]]; then
      formatted_output_warn "Failed to commit to git repo. Continuing..."
    fi
  fi 
)

formatted_output_verbose "Syncing from source directory '$CONFIG_SRC_DIR/' into destination '$CONFIG_DEST_DIR/$CONFIG_SYNC_DIR_NAME'."

if [[ -z "$CONFIG_NO_MOUNT" ]]; then
  # Check if directory is mounted/empty.
  if findmnt -M "$CONFIG_SRC_DIR" &> /dev/null; then
    formatted_output_warn "It appears we are already mounted. Attempting to unmount..."
    attempt_unmount
  fi

  if [[ ! -n "$(find "$CONFIG_SRC_DIR" -maxdepth 0 -type d -empty 2> /dev/null)" ]]; then
    formatted_output_and_fail "'$CONFIG_SRC_DIR' is not empty. Terminating." "$ERR_MOUNTDIR_NOT_EMPTY"
  fi

  # Clear the cache prior to mounting to be sure we have the latest files.
  google-drive-ocamlfuse -cc $([[ ! -z "$CONFIG_MOUNT_LABEL" ]] && echo "-label $CONFIG_MOUNT_LABEL") 2>&1 >&"$VERBOSE_FILE_DESC"
  if [[ $? != 0 ]]; then
    formatted_output_warn "Failed to clear google-drive-ocamlfuse cache. Files may not be up to date."
  fi

  google-drive-ocamlfuse $([[ ! -z "$CONFIG_MOUNT_LABEL" ]] && echo "-label $CONFIG_MOUNT_LABEL") "$CONFIG_SRC_DIR" 2>&1 >&"$VERBOSE_FILE_DESC"
  if [[ $? = 0 ]] && findmnt -M "$CONFIG_SRC_DIR" &> /dev/null; then
    formatted_output_verbose "We appear to have mounted $([[ ! -z "$CONFIG_MOUNT_LABEL" ]] && echo "label '$CONFIG_MOUNT_LABEL'") on '$CONFIG_SRC_DIR'. Continuing..."
    STATE_MUST_UNMOUNT=yes
  else
    formatted_output_and_fail "Failed to mount $([[ ! -z "$CONFIG_MOUNT_LABEL" ]] && echo "label '$CONFIG_MOUNT_LABEL'") on mount point '$CONFIG_SRC_DIR'. Terminating." "$ERR_FUSERMOUNT_FAIL"
  fi
fi

rsync -arv $([[ -z "$CONFIG_NO_DELETE" ]] && echo "--delete") "$CONFIG_SRC_DIR/" "$CONFIG_DEST_DIR/$CONFIG_SYNC_DIR_NAME" 2>&1 >&"$VERBOSE_FILE_DESC"

# Small delay so that we're more likely to succeed in unmounting.
sleep 1

if [[ ! -z "$STATE_MUST_UNMOUNT" ]]; then
  attempt_unmount
fi

( 
  cd "$CONFIG_DEST_DIR"
  git add . 2>&1 >&"$VERBOSE_FILE_DESC"
  git diff-index --quiet HEAD -- &> /dev/null
  
  if [[ $? != 0 ]]; then
    # We have changes to commit.
    git commit -m "$(date -Iseconds): $CONFIG_SYNC_COMMIT_MESSAGE" 2>&1 >&"$VERBOSE_FILE_DESC"
    if [[ $? != 0]]; then
      formatted_output_and_fail "Failed to commit synced changes to git repo. Terminating."
    fi

    git show --stat
  fi
)

