require Logger

defmodule OpenAperture.Auth.Server do

  alias OpenAperture.Auth.Server.Store
  alias OpenAperture.Auth.Util
  alias OpenAperture.Auth.Token

  @doc """
  Checks if a provided OAuth access token is valid.
  """
  @spec validate_token?(String.t, String.t) :: true | false
  def validate_token?(validate_url, token) do
    start_time = :os.timestamp()
    case token_info(validate_url, token) do
      nil -> false
      {:new, user_info} ->
        if user_info["expires_in_seconds"] == nil || user_info["expires_in_seconds"] <= 0 do
          Logger.debug("Auth token expired.")
          false
        else
          timestamp = Util.timestamp_add_seconds(start_time, user_info["expires_in_seconds"])
          Store.put(validate_url, token, %Token{token: token, expires_at: timestamp, user_info: user_info})
          true
        end
      {:cached, _user_info} ->
        true
    end    
  end

  @doc """
  Retrieves a token info body from the server.
  """
  @spec token_info(String.t, String.t) :: {:new | :cached, Map.t} | nil
  def token_info(validate_url, token) do
    stored_token = Store.get(validate_url, token)
    if stored_token != nil && Util.valid_token?(stored_token) do
      {:cached, stored_token.user_info}
    else
      url = "#{validate_url}?#{token}"
      try do
        case :httpc.request(:get, {'#{url}', [{'Accept', 'application/json'}]}, [], []) do
          {:ok, {{_, 200, _}, _, body}} ->
            Logger.debug("Token info response: #{inspect body}")
            user_info = Poison.decode!(body)
            Logger.debug("Parsed token info response: #{inspect user_info}")

            {:new, user_info}
          {:ok, {{_, status, _}, body}} ->
            Logger.debug("Token info check returned with status: #{status}: #{inspect body}")
            nil
          {:error, {failure_reason, _}} ->
            Logger.error("Token info check failed. #{inspect failure_reason}")
            nil
        end

      rescue e in _ ->
        Logger.error("An error occurred validating the OAuth token: #{inspect e}")
        nil
      end
    end
  end
end