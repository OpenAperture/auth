require Logger

defmodule CloudosAuth.Server do

  alias CloudosAuth.Server.Store
  alias CloudosAuth.Util

  @doc """
  Method to validate an OAuth token
  ## Options
  The `auth_header` option defines the auth header
  ## Return values
  Boolean
  """
 @spec validate_token?(String.t, String.t()) :: true | false
 def validate_token?(validate_url, token) do
    stored_token = Store.get(validate_url, token)
    cond do
      stored_token != nil && Util.valid_token?(stored_token)-> 
        true
      true ->
        url = "#{validate_url}?#{token}"
        Logger.debug("Executing OAuth call:  #{url}")
        try do
          start_time = :os.timestamp()
          case :httpc.request(:get, {'#{url}', [{'Accept', 'application/json'}]}, [], []) do
            {:ok, {{_,200, _}, _, body}} ->
              Logger.debug("Received response from OAuth:  #{inspect body}")
              userinfo_json = Poison.decode!("#{body}")
              Logger.debug("Parsed OAuth response:  #{inspect userinfo_json}")
              cond do
                userinfo_json["expires_in_seconds"] == nil || userinfo_json["expires_in_seconds"] <= 0 ->
                  Logger.debug("auth token expired")
                  false
                true ->
                  timestamp = Util.timestamp_add_seconds(start_time, userinfo_json["expires_in_seconds"])                      
                  Store.put(validate_url, token, %CloudosAuth.Token{token: token, expires_at: timestamp})
                  true
              end
            {:ok, {{_,return_code, _}, _, body}} ->
              Logger.debug("auth token check returned #{return_code}: #{inspect body}")
              false
            {:error, {failure_reason, _}} -> 
              Logger.debug("auth token check failed: #{inspect failure_reason}")
              false
          end
        rescue e in _ ->
          Logger.error("An error occurred calling OAuth:  #{inspect e}")
          false 
        end
    end    
  end
end