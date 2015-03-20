require Logger

defmodule CloudosAuth do

  @spec start_link(String.t(), String.t(), String.t()) :: {:ok, pid} | {:error, String.t()}
  def start_link(url, client_id, client_secret) do
    create(url, client_id, client_secret)
  end

  @spec create(String.t(), String.t(), String.t()) :: {:ok, pid} | {:error, String.t()} 
  def create(url, client_id, client_secret) do
    case Agent.start_link(fn -> %{:url => url, :client_id => client_id, :client_secret => client_secret} end) do
      {:ok, pid} -> 
        get_token(pid, true)
        {:ok, pid}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  Method to retrieve the an authentication token from cache, if available
  ## Options
  The `force_refresh` option will force a retrieval of the auth token
  ## Return values
  String
  """
  @spec get_token(pid, term) :: String.t()
  def get_token(pid, force_refresh \\ false) do
    options = Agent.get(pid, fn options -> options end)

    cond do
      options[:auth_token] != nil && !force_refresh -> options[:auth_token]
      true ->
        options = Map.put(options, :auth_token, get_token_raw(options[:url], options[:client_id], options[:client_secret]))
        Agent.update(pid, fn _ -> options end)
        options[:auth_token]
    end
  end

  @doc """
  Method to retrieve the an authentication token, directly from the provider
  ## Return values
  String
  """
  @spec get_token_raw(String.t(), String.t(), String.t()) :: String.t()
  def get_token_raw(url, client_id, client_secret) do
    body = '#{JSON.encode!(%{
      grant_type: "client_credentials", 
      client_id: client_id, 
      client_secret: client_secret
    })}'
    case :httpc.request(:post, {url, [{'Content-Type', 'application/json'}, {'Accept', 'application/json'}], 'application/json', body}, [], []) do
      {:ok, {{_,return_code, _}, _, body}} ->
        case return_code do
          200 -> 
            Logger.debug("Retrieved OAuth Token")
            JSON.decode!("#{body}")["access_token"]
          _   -> 
            Logger.error("OAuth returned status #{return_code} while authenticating:  #{inspect body}")
            ""
        end
      {:error, {failure_reason, _}} ->
        Logger.error("OAuth responded with an error while authenticating:  (#{inspect failure_reason})")
        ""
    end
  end

  @doc """
  Method to retrieve the authentication header
  ## Options
  The `force_refresh` option will force a retrieval of the auth token
  ## Return values
  String
  """
  @spec get_auth_header(term) :: String.t()
  def get_auth_header(force_refresh \\ false) do
    "OAuth access_token=#{get_token(force_refresh)}"
  end

  @doc """
  Method to validate a Google OAuth authentication header
  ## Options
  The `auth_header` option defines the auth header
  ## Return values
  Boolean
  """
 @spec validate_header(pid, String.t()) :: :ok | :error
  def validate_header(pid, auth_header) do
    if (!String.starts_with?(auth_header, "OAuth ")) do
      false
    else
      options = Agent.get(pid, fn options -> options end)

      access_token = to_string(tl(String.split(auth_header, "OAuth ")))

      url = "#{options[:url]}/info?#{access_token}"
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
end
