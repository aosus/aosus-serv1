#!/bin/bash

# Existing part of your script
guest_token=$(curl -s -XPOST https://api.twitter.com/1.1/guest/activate.json -H 'Authorization: Bearer AAAAAAAAAAAAAAAAAAAAAFXzAwAAAAAAMHCxpeSDG1gLNLghVe8d74hl6k4%3DRUMF4xAQLsbeBhTSRrCiQpJtxoGWeyHrDb5te2jpGskWDFW82F' | jq -r '.guest_token')

flow_token=$(curl -s -XPOST 'https://api.twitter.com/1.1/onboarding/task.json?flow_name=welcome' \
          -H 'Authorization: Bearer AAAAAAAAAAAAAAAAAAAAAFXzAwAAAAAAMHCxpeSDG1gLNLghVe8d74hl6k4%3DRUMF4xAQLsbeBhTSRrCiQpJtxoGWeyHrDb5te2jpGskWDFW82F' \
          -H 'Content-Type: application/json' \
          -H "User-Agent: TwitterAndroid/10.10.0" \
          -H "X-Guest-Token: ${guest_token}" \
          -d '{"flow_token":null,"input_flow_data":{"flow_context":{"start_location":{"location":"splash_screen"}}}}' | jq -r .flow_token)

# Capture the new entry in a variable
new_entry=$(curl -s -XPOST 'https://api.twitter.com/1.1/onboarding/task.json' \
          -H 'Authorization: Bearer AAAAAAAAAAAAAAAAAAAAAFXzAwAAAAAAMHCxpeSDG1gLNLghVe8d74hl6k4%3DRUMF4xAQLsbeBhTSRrCiQpJtxoGWeyHrDb5te2jpGskWDFW82F' \
          -H 'Content-Type: application/json' \
          -H "User-Agent: TwitterAndroid/10.10.0" \
          -H "X-Guest-Token: ${guest_token}" \
          -d "{\"flow_token\":\"${flow_token}\",\"subtask_inputs\":[{\"open_link\":{\"link\":\"next_link\"},\"subtask_id\":\"NextTaskOpenLink\"}]}" | jq -c -r '.subtasks[0]|if(.open_account) then {oauth_token: .open_account.oauth_token, oauth_token_secret: .open_account.oauth_token_secret} else empty end')

# Define the path to your JSON file
json_file="$1"

# Add the new entry to the JSON array in the specified file
if [[ -n "$new_entry" && "$new_entry" != "null" ]]; then
    jq --argjson new_entry "$new_entry" '. += [$new_entry]' "$json_file" > temp.json && mv temp.json "$json_file"
fi
