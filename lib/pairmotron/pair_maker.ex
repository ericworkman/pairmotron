defmodule Pairmotron.PairMaker do
  import Ecto.Query
  alias Pairmotron.{Repo, Group, Pair, UserPair, Mixer, Pairer, PairBuilder}

  def fetch_or_gen(year, week, group_id) do
    case fetch_pairs(year, week, group_id) do
      []    -> generate_and_fetch_if_current_week(year, week, group_id)
      pairs -> pairs
    end
      |> fetch_users_from_pairs
  end

  defp generate_and_fetch_if_current_week(year, week, group_id) do
    case Pairmotron.Calendar.same_week?(year, week, Timex.today) do
      true ->
        generate_pairs(year, week, group_id)
        fetch_pairs(year, week, group_id)
      false -> []
    end
  end

  defp fetch_pairs(year, week, group_id) do
    Pair
      |> where(year: ^year, week: ^week, group_id: ^group_id)
      |> order_by(:id)
      |> Repo.all
  end

  defp fetch_users_from_pairs(pairs) do
    pairs
      |> Repo.preload([:users])
  end

  def generate_pairs(year, week, group_id) do
    group = Group
      |> select([g], g)
      |> where([g], g.id == ^group_id)
      |> preload(:users)
      |> Repo.one

    users = group.users
      |> Enum.filter(fn(u) -> u.active end)
      |> Enum.sort

    pairs = fetch_pairs(year, week, group_id)
      |> Repo.preload(:users)

    determination = PairBuilder.determify(pairs, users)

    determination.dead_pairs
      |> Enum.map(fn(p) -> Repo.delete! p end)

    pairs = determination.remaining_pairs
      |> Repo.preload(:pair_retros)
      |> Enum.filter(&(Enum.empty?(&1.pair_retros)))

    results = determination.available_users
      |> Mixer.mixify(week)
      |> Pairer.generate_pairs(pairs)

    results.pairs
      |> Enum.map(fn(users) -> make_pairs(users, year, week, group_id) end)
      |> List.flatten
      |> Enum.map(fn(p) -> Repo.insert! p end)

    insert_user_pair(results.user_pair)
  end

  defp insert_user_pair(nil), do: nil
  defp insert_user_pair(user_pair) do
    Repo.insert! user_pair
  end

  defp make_pairs(users, year, week, group_id) do
    pair = Repo.insert! Pair.changeset(%Pair{}, %{year: year, week: week, group_id: group_id})
    users
      |> Enum.map(fn(user) -> UserPair.changeset(%UserPair{}, %{pair_id: pair.id, user_id: user.id}) end)
  end

end
