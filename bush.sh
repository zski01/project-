#!/usr/bin/env bash
# =============================================================================
# GitHub Contribution Backdater Script – POSIX compatible version
# =============================================================================

# === CONFIGURATION ===
START_DATE="2025-01-01"           # YYYY-MM-DD
END_DATE="2025-12-31"             # YYYY-MM-DD
FILE_TO_MODIFY="activity.md"
COMMIT_MESSAGE_PREFIX="Activity"
MAX_COMMITS_PER_DAY=4
REPO_DIR="."
BRANCH="main"

# =============================================================================

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "Error: Not inside a git repository."
    exit 1
fi

touch "$FILE_TO_MODIFY"

echo "Backdating from $START_DATE to $END_DATE..."
echo "File: $FILE_TO_MODIFY   Branch: $BRANCH   Max/day: $MAX_COMMITS_PER_DAY"
echo "----------------------------------------"

current_epoch=$(date -d "$START_DATE" +%s 2>/dev/null || date -d "$START_DATE 00:00:00" +%s)
end_epoch=$(date -d "$END_DATE" +%s 2>/dev/null || date -d "$END_DATE 23:59:59" +%s)

day=$current_epoch

while [ "$day" -le "$end_epoch" ]; do
    date_str=$(date -d "@$day" +%Y-%m-%d 2>/dev/null || date -d "$(date -d "@$day" +%Y-%m-%d)" +%Y-%m-%d)

    # Random commits this day: 0 to MAX
    num_commits=$(( RANDOM % (MAX_COMMITS_PER_DAY + 1) ))

    echo "Date: $date_str → $num_commits commit(s)"

    commit_count=1
    while [ "$commit_count" -le "$num_commits" ]; do
        hour=$(( RANDOM % 24 ))
        minute=$(( RANDOM % 60 ))
        second=$(( RANDOM % 60 ))
        time_str=$(printf "%02d:%02d:%02d" "$hour" "$minute" "$second")

        full_datetime="${date_str}T${time_str}"

        echo "Commit on $full_datetime - #$commit_count" >> "$FILE_TO_MODIFY"

        git add "$FILE_TO_MODIFY" >/dev/null 2>&1

        GIT_AUTHOR_DATE="$full_datetime" \
        GIT_COMMITTER_DATE="$full_datetime" \
        git commit --quiet -m "$COMMIT_MESSAGE_PREFIX on $date_str #$commit_count" --date="$full_datetime"

        echo "  → Committed: $full_datetime"

        commit_count=$(( commit_count + 1 ))
    done

    day=$(( day + 86400 ))
done

echo "----------------------------------------"
echo "All local commits created."
echo "Pushing to origin/$BRANCH ..."

git push origin "$BRANCH"

echo "Finished. Check GitHub contribution graph in a few minutes."