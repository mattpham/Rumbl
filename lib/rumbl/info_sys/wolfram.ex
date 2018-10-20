defmodule Rumbl.InfoSys.Wolfram do
  # Wolfram api uses xml so we require sweet_xml dependency
  import SweetXml
  alias Rumbl.InfoSys.Result

  # Establishes our module as implementing the behaviour
  @behaviour Rumbl.InfoSys.Backend

  @base "http://api.wolframalpha.com/v2/query"

  @impl true
  def name, do: "wolfram"

  @impl true
  def compute(query_str, _opts) do
    query_str
    |> fetch_xml()
    |> xpath(~x"/queryresult/pod[contains(@title, 'Result') or
                                  contains(@title, 'Definitions')]
                              /subpod/plaintext/text()")
    |> build_results()
  end

  defp build_results(nil), do: []
  # build a list of result structs
  defp build_results(answer) do
    [%Result{backend: __MODULE__, score: 95, text: to_string(answer)}]
  end

  # contact Wolfram alpha with the query string using `:httpc` which ships within
  # Erlang's standard library, to do straight HTTP request, matching against :ok
  # and the body
  defp fetch_xml(query) do
    {:ok, {_, _, body}} = :httpc.request(String.to_charlist(url(query)))

    body
  end

  defp url(input) do
    "#{@base}?" <> URI.encode_query(appid: id(), input: input, format: "plaintext")
  end

  # extracts the api key from our application configuration
  defp id, do: Application.get_env(:rumbl, :wolfram)[:app_id]
end
