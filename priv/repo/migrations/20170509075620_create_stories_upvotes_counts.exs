defmodule Citybuilder.Repo.Migrations.CreateCitybuilder.Stories.UpvotesCounts do
  use Ecto.Migration

  def change do
    create table(:stories_upvotes_counts) do
      add :count, :integer, null: false, default: 0
      add :post_id, references(:stories_posts, on_delete: :nothing), null: false

      timestamps()
    end

    create constraint(:stories_upvotes_counts, :upvotes_counts_must_be_not_negative, check: "count >= 0")

    create index(:stories_upvotes_counts, [:post_id], unique: true)
    create index(:stories_upvotes_counts, :count)
  end
end
