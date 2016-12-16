defmodule Pairmotron.Factory do
  # with Ecto
  use ExMachina.Ecto, repo: Pairmotron.Repo

  alias Pairmotron.{PairRetro, User}

  def user_factory do
    %User{
      name: sequence(:first_name, &"name #{&1}"),
      email: sequence(:email, &"email-#{&1}@example.com"),
      active: true,
      password_hash: "12345678"
    }
  end

  def user_with_password_factory do
    %User{
      name: sequence(:first_name, &"name #{&1}"),
      email: sequence(:email, &"email-#{&1}@example.com"),
      active: true,
      password: "12345678",
      password_confirmation: "12345678",
      password_hash: Comeonin.Bcrypt.hashpwsalt("12345678")
    }
  end

end
