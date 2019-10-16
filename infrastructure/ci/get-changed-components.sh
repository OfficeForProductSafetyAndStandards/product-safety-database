#!/usr/bin/env bash
set -ex

COMMITS=$TRAVIS_COMMIT_RANGE

# Get top level files / folders changed in recent commits
TOP_LEVEL_CHANGES=$(git diff --name-only $COMMITS | awk -F'/' '{ print $1 }' | sort -u)

COMPONENTS=''
if [[ "$TOP_LEVEL_CHANGES" =~ shared-web ]] || [[ "$TOP_LEVEL_CHANGES" =~ psd-web ]]; then
    COMPONENTS="$COMPONENTS psd-web psd-worker"
elif [[ "$TOP_LEVEL_CHANGES" =~ shared-worker ]] || [[ "$TOP_LEVEL_CHANGES" =~ psd-worker ]]; then
    COMPONENTS="$COMPONENTS psd-worker"
fi

echo $COMPONENTS
