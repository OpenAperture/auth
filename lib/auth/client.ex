require Logger

defmodule OpenAperture.Auth.Client do

  alias OpenAperture.Auth.Client.Store
  alias OpenAperture.Auth.Util
  @doc """
  Method to retrieve the an authentication token from cache, if available
  ## Options
  The `force_refresh` option will force a retrieval of the auth token
  ## Return values
  String
  """
  @spec get_token(String.t(), String.t(), String.t()) :: String.t()
  def get_token(url, client_id, client_secret, force_refresh \\ false) do
    stored_token = Store.get(url, client_id)

    cond do
      stored_token != nil && !force_refresh && Util.valid_token?(stored_token)-> 
        stored_token.token
      true ->
        case get_token_raw(url, client_id, client_secret) do
          {:ok, token} ->
            Store.put(url, client_id, token)
            token.token
          {:error, reason} ->
            Logger.error(reason)
            ""
        end
    end
  end

  @doc """
  Method to retrieve the an authentication token, directly from the provider
  """
  @spec get_token_raw(String.t(), String.t(), String.t()) :: {:ok, OpenAperture.Auth.Token} | {:error, String.t()}
  def get_token_raw(url, client_id, client_secret) do
    body = '#{Poison.encode!(%{
      grant_type: "client_credentials", 
      client_id: client_id, 
      client_secret: client_secret
    })}'
    start_time = :os.timestamp()
    case :httpc.request(:post, {'#{url}', [{'Content-Type', 'application/json'}, {'Accept', 'application/json'}], 'application/json', body}, [], []) do
      {:ok, {{_,200, _}, _, body}} ->
        Logger.debug("Retrieved OAuth Token")
        token = Poison.decode!("#{body}")["access_token"]
        expiration = Poison.decode!("#{body}")["expires_in"]
        timestamp = Util.timestamp_add_seconds(start_time, expiration)
        {:ok, %OpenAperture.Auth.Token{token: token, expires_at: timestamp}}
      {:ok, {{_,return_code, _}, _, body}} ->
        Logger.error("OAuth returned status #{return_code} while authenticating:  #{inspect body}")
        {:error, "OAuth returned status #{return_code} while authenticating:  #{inspect body}"}
      {:error, {failure_reason, _}} ->
        Logger.error("OAuth responded with an error while authenticating:  (#{inspect failure_reason})")
        {:error, "OAuth responded with an error while authenticating:  (#{inspect failure_reason})"}
    end
  end
end