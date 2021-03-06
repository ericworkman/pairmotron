defmodule Pairmotron.Project do
  use Pairmotron.Web, :model

  schema "projects" do
    field :name, :string
    field :description, :string
    field :url, :string

    has_many :pair_retros, Pairmotron.PairRetro
    belongs_to :group, Pairmotron.Group
    belongs_to :created_by, Pairmotron.User

    timestamps()
  end

  @required_params ~w(name)
  @optional_params ~w(description url group_id created_by_id)

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @required_params, @optional_params)
    |> validate_url(:url)
  end

  @required_create_params ~w(name group_id created_by_id)
  @optional_change_params ~w(description url)

  def changeset_for_create(struct, params \\ %{}, users_groups) do
    struct
    |> cast(params, @required_create_params, @optional_change_params)
    |> validate_url(:url)
    |> validate_user_is_in_group(:group_id, users_groups)
  end


  def changeset_for_update(struct, params \\ %{}) do
    struct
    |> cast(params, @required_params, @optional_change_params)
    |> validate_url(:url)
  end

  def validate_url(changeset, field) do
    validate_change changeset, field, fn _, url ->
      case url |> URI.parse do
        %URI{scheme: nil} -> [{field, "URL is missing the scheme. Include 'http://' or 'https://'."}]
        %URI{host: nil} -> [{field, "URL is not valid."}]
        _ -> []
      end
    end
  end

  def validate_user_is_in_group(changeset, field, users_groups) do
    validate_change changeset, field, fn _, selected_group_id ->
      if users_groups |> Enum.any?(fn group -> group.id == selected_group_id end) do
        []
      else
        [{field, "Must be member of group"}]
      end
    end
  end

  def projects_for_user(user) do
    from project in Pairmotron.Project,
    join: group in assoc(project, :group),
    join: u in assoc(group, :users),
    where: u.id == ^user.id
  end
end
