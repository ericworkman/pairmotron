defmodule Pairmotron.PairRetroView do
  use Pairmotron.Web, :view

  def format_date(nil), do: ""
  def format_date(date), do: Ecto.Date.to_string(date)

  def format_project(nil), do: "(none)"
  def format_project(%Pairmotron.Project{name: name}), do: name

  def projects_for_select(conn) do
    case conn.assigns[:projects] do
      nil -> []
      projects ->
        projects
        |> Enum.map(&["#{&1.name}": &1.id])
        |> List.flatten
    end
  end
end
