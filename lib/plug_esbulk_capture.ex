defmodule PlugEsbulkCapture do
    alias Plug.Conn

    @behaviour Plug

    def init(opts) do
        %{
            uniq: Keyword.get(opts, :uniq, false),
            ignore_meta_data: Keyword.get(opts, :ignore_meta_data, false),
        }
    end

    def call(conn = %Conn{method: "POST", path_info: ["_bulk"]}, opts) do
        items = parse_body(conn, opts)
        Conn.put_private(conn, :plug_esbulk_capture, items)
    end

    def call(conn, _), do: conn

    defp parse_body(conn, opts) do
        {:ok, body, _} = Conn.read_body(conn)

        items = String.split(body, ["\n"])
            |> Enum.filter(&(String.length(&1) > 0))
            |> Enum.map(&Poison.decode!(&1))

        items = case Map.get(opts, :ignore_meta_data) do
            true -> Enum.filter(items, &(!is_es_metaobj?(&1)))
            _    -> items
        end

        case Map.get(opts, :uniq) do
            true -> Enum.uniq(items)
            _    -> items
        end
    end

    defp is_es_metaobj?(obj = %{"index" => _}) do
        Map.size(obj) == 1
    end

    defp is_es_metaobj?(_) do
        false
    end
end
