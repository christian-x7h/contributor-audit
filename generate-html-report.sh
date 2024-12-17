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

<table>
<thead>
<tr>
    <th>Contributor</th>
    <th>Repository</th>
    <th>Count</th>
    <th>Commits</th>
</tr>
</thead>
<tbody>
EOF

# For each contributor
while IFS= read -r contributor
do
    [ -z "$contributor" ] && continue

    # For each repository
    while IFS='|' read -r repo main_branch
    do
        repo=$(echo "$repo" | xargs)
        main_branch=$(echo "$main_branch" | xargs)

        # Get the list of commits to main branch
        commits=$(git -C "$repo" log --since "$DATE" --author="$contributor" --oneline "$main_branch" 2>/dev/null)

        # Count how many contributions to main
        count=$(echo "$commits" | grep -c .)

        # Begin table row
        echo "<tr>"
        echo "  <td>$contributor</td>"
        echo "  <td>$repo</td>"
        echo "  <td>$count</td>"
        echo "  <td>"

        if [ "$count" -gt 0 ]; then
            # Use a <details> element to show/hide the list of files
            echo "<details>"
            echo "<summary>Show commits</summary>"
            echo "<ul>"
            # Print each contribution as a list item
            while IFS= read -r commit
            do
                [ -z "$commit" ] && continue
                # Linkify the PR reference (#XXXX)
                # The pattern: (#1234)
                commit_linked=$(echo "$commit" | sed -E 's/\(#([0-9]+)\)/(<a href="https:\/\/github.com\/christian-x7h\/'"$repo"'\/pull\/\1">#\1<\/a>)/g')      
                echo "<li>$commit_linked</li>"
            done <<< "$commits"
            echo "</ul>"
            echo "</details>"
        else
            echo "No commits"
        fi

        echo "  </td>"
        echo "</tr>"

    done <<< "$REPOS"
done <<< "$CONTRIBUTORS"

# Close HTML
cat <<EOF
</tbody>
</table>
</body>
</html>
EOF
