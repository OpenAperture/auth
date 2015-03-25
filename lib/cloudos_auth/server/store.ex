defmodule CloudosAuth.Server.Store do
  def start_link() do
    Agent.start_link &HashDict.new/0, name: CloudosAuth.Server.Store
  end

  def get(store, key1, key2) do
    Agent.get(store, &HashDict.get(&1, create_key(key1, key2)))
  end

  def put(store, key1, key2, token) do
    Agent.update(store, &HashDict.put(&1, create_key(key1, key2), token))
  end

  def remove(store, key1, key2) do
    Agent.update(store, &HashDict.delete(&1, create_key(key1, key2)))
  end

  defp create_key(part1, part2) do
    part1 <> "::" <> part2
  end
end