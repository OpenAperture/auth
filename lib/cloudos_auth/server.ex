require Logger

defmodule CloudosAuth.Server do


  @doc """
  Method to validate an OAuth token
  ## Options
  The `auth_header` option defines the auth header
  ## Return values
  Boolean
  """
 @spec validate_token(String.t, String.t()) :: :ok | :error
 def validate_token(validate_url, token) do
  	url = "#{validate_url}?#{token}"
		Logger.debug("Executing OAuth call:  #{url}")
		try do
	    case :httpc.request(:get, {url, [{'Accept', 'application/json'}]}, [], []) do
	      {:ok, {{_,return_code, _}, _, body}} ->
	        case return_code do
	          200 -> 
	            Logger.debug("Received response from OAuth:  #{inspect body}")
	            userinfo_json = JSON.decode!("#{body}")
	            Logger.debug("Parsed OAuth response:  #{inspect userinfo_json}")
	            cond do
	              userinfo_json["expires_in_seconds"] == nil || userinfo_json["expires_in_seconds"] <= 0 -> false
	              true -> true
	            end
	          _   -> false
	        end
	      {:error, {failure_reason, _}} -> false
	    end
	  rescue e in _ ->
	    Logger.error("An error occurred calling OAuth:  #{inspect e}")
	    false 
	  end
	end
end