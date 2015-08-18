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
        if expired?(user_info) do
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

  defp expired?(%{"expires_in_seconds" => nil}),               do: true
  defp expired?(%{"expires_in_seconds" => eis}) when eis <= 0, do: true
  defp expired?(_),                                            do: false

  @doc """
  Retrieves a token info body from the server.
  """
  @spec token_info(String.t, String.t) :: {:new | :cached, Map} | nil
  def token_info(validate_url, token) do
    stored_token = Store.get(validate_url, token)
    if stored_and_valid?(stored_token) do
      {:cached, stored_token.user_info}
    else
      url = "#{validate_url}?#{token}"
      try do
        case :httpc.request(:get, {'#{url}', [{'Accept', 'application/json'}]}, [], []) do
          {:ok, {{_http_protocol, 200, _status_desc}, _headers, body}} ->
            Logger.debug("Token info is valid")
            user_info = Poison.decode!(body)
            {:new, user_info}
          {:ok, {{_http_protocol, status, _status_desc}, _headers, body}} ->
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

  defp stored_and_valid?(nil),          do: false
  defp stored_and_valid?(stored_token), do: Util.valid_token?(stored_token)
end
