#!/usr/bin/env zsh

DATE="2024-01-01"

# Inline contributors
CONTRIBUTORS=$(cat <<EOF
# Name patterns to match against commit 'author' e.g. christian-x7h
EOF
)

# Inline repos with their main branches
REPOS=$(cat <<EOF
example-repo-1 | master
example-repo-2 | main
EOF
)

# Start HTML output
cat <<EOF
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>Git Contributions Report</title>
<style>
body {
    font-family: Arial, sans-serif;
    margin: 20px;
}

h2 {
    margin-top: 40px;
    margin-bottom: 10px;
    font-size: 1.5em;
}

table {
    border-collapse: collapse;
    width: 100%;
    margin-bottom: 20px;
}

th, td {
    border: 1px solid #ccc;
    padding: 8px 12px;
    vertical-align: top;
}

th {
    background: #f2f2f2;
}

details {
    margin-top: 5px;
}

summary {
    cursor: pointer;
    font-weight: bold;
}
</style>
</head>
<body>

<h1>Git Contributions Report since $DATE</h1>
EOF

# For each contributor
echo "<div class=\"contributors\">"
while IFS= read -r contributor
do
    [ -z "$contributor" ] && continue

    # Track total commits for this contributor across all repos
    contributor_total=0
    contributor_rows=""

    # For each repository
    while IFS='|' read -r repo main_branch
    do
        repo=$(echo "$repo" | xargs)
        main_branch=$(echo "$main_branch" | xargs)

        # Get the list of commits for this repo/contributor since DATE
        commits=$(git -C "$repo" log --since "$DATE" --author="$contributor" --oneline "$main_branch" 2>/dev/null)

        # Count how many commits
        count=$(echo "$commits" | grep -c .)

        if [ "$count" -gt 0 ]; then
            contributor_total=$((contributor_total + count))
        fi

        # Build the table row for this repo
        row="<tr>"
        row+="<td><strong>$repo</strong></td>"
        row+="<td>$count</td>"
        row+="<td>"

        if [ "$count" -gt 0 ]; then
            row+="<details>"
            row+="<summary>Show commits</summary>"
            row+="<ul>"
            
            # Print each commit and linkify the PR references
            while IFS= read -r commit
            do
                [ -z "$commit" ] && continue
                commit_linked=$(echo "$commit" | sed -E 's/\(#([0-9]+)\)/(<a href="https:\/\/github.com\/christian-x7h\/'"$repo"'\/pull\/\1">#\1<\/a>)/g')
                row+="<li>$commit_linked</li>"
            done <<< "$commits"
            row+="</ul>"
            row+="</details>"
        else
            row+="No commits"
        fi

        row+="</td>"
        row+="</tr>"

        contributor_rows+="$row"
    done <<< "$REPOS"

    # Now print the contributor section
    echo "<h2>$contributor</h2>"
    echo "<p><strong>Total Commits:</strong> $contributor_total</p>"
    echo "<table>"
    echo "<thead>"
    echo "<tr>"
    echo "<th>Repository</th>"
    echo "<th>Count</th>"
    echo "<th>Commits</th>"
    echo "</tr>"
    echo "</thead>"
    echo "<tbody>"
    echo "$contributor_rows"
    echo "</tbody>"
    echo "</table>"

done <<< "$CONTRIBUTORS"
echo "</div>"

# Close HTML
cat <<EOF
</body>
</html>
EOF
