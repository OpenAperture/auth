defmodule OpenAperture.Auth.Client.Store do
  def start_link() do
    Agent.start_link &HashDict.new/0, name: OpenAperture.Auth.Client.Store
  end

  def get(key1, key2) do
    Agent.get(OpenAperture.Auth.Client.Store, &HashDict.get(&1, create_key(key1, key2)))
  end

  def put(key1, key2, token) do
    Agent.update(OpenAperture.Auth.Client.Store, &HashDict.put(&1, create_key(key1, key2), token))
  end

  def remove(key1, key2) do
    Agent.update(OpenAperture.Auth.Client.Store, &HashDict.delete(&1, create_key(key1, key2)))
  end

  defp create_key(part1, part2) do
    "#{part1}::#{part2}"
  end
end