defmodule OpenAperture.Auth.Util do

  def timestamp_add_seconds(timestamp, seconds) do
    # preserve microseconds
    {_megas, _secs, micros} = timestamp
    timestamp
    |> timestamp_erlang_to_unix
    |> (fn i -> i + seconds end).()
    |> timestamp_unix_to_erlang
    |> (fn {megas, secs, 0} -> {megas, secs, micros} end).()
  end

  defp timestamp_erlang_to_unix(erlang_timestamp) do
    {megas, secs, _} = erlang_timestamp
    megas * 1_000_000 + secs
  end

  defp timestamp_unix_to_erlang(unix_timestamp) do
    megas = div(unix_timestamp, 1_000_000)
    secs = rem(unix_timestamp, 1_000_000)
    {megas, secs, 0}
  end

  def valid_token?(token) do
    # A valid token has an access token, and expires more than 30 seconds from now.
    token.token != nil && :timer.now_diff(token.expires_at, :os.timestamp()) > 30_000_000
  end
end