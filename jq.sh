jq '.prior_state.values.root_module.resources[0].values.platform_details' file.json   

curl 'https://api.github.com/repos/jqlang/jq/commits?per_page=5' |
jq '.[] | select(.committer.id == 19864447) |
{sha: .sha, commit: .commit.author.name}'
