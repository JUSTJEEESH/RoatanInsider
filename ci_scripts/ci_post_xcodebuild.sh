#!/bin/sh
#
# Xcode Cloud runs this after xcodebuild. It uploads the archive's dSYMs to
# Sentry so production crash reports name functions and lines instead of
# memory addresses.
#
# The local build phase can't do this job here: it shells out to sentry-cli,
# and Apple's build machines have no Homebrew packages installed — which is
# the "sentry-cli not installed" warning on every Xcode Cloud archive.
#
# Inert until SENTRY_AUTH_TOKEN exists. Add it in App Store Connect under
# the workflow's Environment > Environment Variables, marked SECRET so it
# is not printed in logs. Create the token at
# sentry.io/settings/account/api/auth-tokens with project:releases scope.
#
# Never fails the build. A missing symbol upload costs you readable crash
# reports; a failed build costs you the release.

[ "$CI_XCODEBUILD_ACTION" = "archive" ] || exit 0

if [ -z "$SENTRY_AUTH_TOKEN" ]; then
    echo "warning: SENTRY_AUTH_TOKEN not set — 2.0 crashes will not be symbolicated in Sentry."
    exit 0
fi

DSYMS="$CI_ARCHIVE_PATH/dSYMs"
if [ ! -d "$DSYMS" ]; then
    echo "warning: no dSYMs at $DSYMS — nothing to upload."
    exit 0
fi

export SENTRY_ORG=jeeeshua
export SENTRY_PROJECT=apple-ios

# Downloaded rather than brewed: the installer is a few seconds, `brew
# install` is a couple of minutes of a metered compute allowance.
if ! curl -sL https://sentry.io/get-cli/ | INSTALL_DIR="$PWD" sh; then
    echo "warning: could not install sentry-cli — skipping symbol upload."
    exit 0
fi

if ! "$PWD/sentry-cli" debug-files upload "$DSYMS"; then
    echo "warning: sentry-cli could not upload dSYMs from $DSYMS."
fi

exit 0
