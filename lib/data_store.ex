defmodule MeriazardLocal.DataStore do
  alias :mnesia, as: Mnesia

  def setup do
    Mnesia.create_schema([node()])
    Mnesia.start()

    unless Mnesia.system_info(:tables) |> Enum.member?(:media_list) do
      Mnesia.create_table(:media_list, [
        attributes: [:id, :name, :path],
      ])
    end
  end

  def add_media(media) do
    Mnesia.transaction(fn ->
      Mnesia.write({:media_list, media.id, media.name, media.path})
    end)
  end

  def get_media(id) do
    Mnesia.transaction(fn ->
      case Mnesia.read({:media_list, id}) do
        [] -> {:error, "Media not found."}
        [{:media_list, id, name, path}] -> {:ok, {name, path}}
      end
    end)
  end

  def get_all_media do
    Mnesia.transaction(fn ->
      Mnesia.match_object({:media_list, :_, :_, :_})
      |> Enum.map(fn {:media_list, id, name, path} -> {id, name, path} end)
    end)
  end
end

