defmodule CloudosAuth do

	@spec create_client(String.t(), String.t(), String.t()) :: {:ok, pid} | {:error, String.t()}
	def create_client(url, client_id, client_secret) do
		CloudosAuth.Client.start_link(url, client_id, client_secret)
	end

	@spec create_server(String.t()) :: {:ok, pid} | {:error, String.t()}
	def create_server(validate_url) do
		CloudosAuth.Server.start_link(validate_url)
	end

end